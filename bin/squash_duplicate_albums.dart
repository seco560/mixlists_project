// One-time db-surgery script -- not part of the shipped app.
//
// Squashes duplicate Albums rows caused by a since-fixed bug in
// getOrCreateAlbumId (see mixlists_core's mixlist_ingestion.dart):
// Spotify doesn't always serve the same album URI for what's really the
// same album (reissues, regional catalog variants, messy metadata on
// smaller labels), so importing 166 playlists independently split many
// albums' tracklists across 2-4 duplicate Albums rows sharing the same
// (name, artist).
//
// For each (name, artist) duplicate group:
//   - picks a canonical row (most attached Songs, tie-break lowest id)
//   - backfills the canonical row's null recordLabel/coverImageURL from
//     a duplicate that has one
//   - repoints Songs.album from every other row in the group to the
//     canonical id
//   - deletes the now-empty duplicate Albums rows
//
// Then, strictly *within* each merged album (never library-wide -- a
// library-wide same-name-song scan turns up legitimate cases like a
// track appearing on both a studio album and a compilation, which must
// never be merged), looks for an exact-name Song collision -- a
// byproduct of the same bug at the song level -- and merges those too:
// backfills SongsExtraData, adopts an orphaned SongsAudioFeatures row if
// the canonical has none, repoints SongsMixlists (dropping a duplicate
// (song, mixlist) pair rather than creating one), then deletes the loser
// Song + its SongsExtraData.
//
// Finally, removes any Albums row left with zero attached Songs -- a
// separate, unrelated residual bug (documented in project history):
// getOrCreateArtistId/getOrCreateAlbumId run *before* getOrCreateSongId
// in the ingestion transaction, so when a track's song turns out to
// already exist elsewhere (matched by name+duration under a different
// album -- e.g. a "Deluxe"/reissue edition containing the same
// recording as the original release), the Artist/Album rows already
// created for it go unused. These have unique names (not name/artist
// duplicates of anything -- that's the pass above), so they're never
// caught by the merge logic; safe to delete outright since nothing else
// references an Albums row except Songs.album.
//
// Always operates on a backup + working copy of --db, only overwriting
// the given path itself once the full run succeeds.
//
// Usage:
//   dart run bin/squash_duplicate_albums.dart --db <path>

// Print statements are the only output this script has.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MergeSummary {
  int groupsMerged = 0;
  int rowsRemoved = 0;
  final warnings = <String>[];
}

Future<void> main(List<String> args) async {
  String? dbPath;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--db':
        dbPath = args[++i];
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(1);
    }
  }
  if (dbPath == null) {
    stderr.writeln('Usage: dart run bin/squash_duplicate_albums.dart --db <path>');
    exit(1);
  }

  final dbFile = File(dbPath);
  if (!dbFile.existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(1);
  }

  // Step 1: back up, non-negotiable.
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupPath = '$dbPath.pre-squash-backup-$timestamp';
  dbFile.copySync(backupPath);
  print('Backed up $dbPath -> $backupPath');

  // Step 2: work on a separate copy, never the original, until success.
  // sqflite_common_ffi resolves a relative path against its own default
  // databases directory, not the working directory -- an absolute path
  // is required here or it silently opens/creates a different, empty
  // file there instead.
  final workingPath = p.absolute('$dbPath.squashing');
  final workingFile = File(workingPath);
  if (workingFile.existsSync()) workingFile.deleteSync();
  dbFile.copySync(workingPath);

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(workingPath);

  final albumsBefore = await _count(db, 'Albums');
  final songsBefore = await _count(db, 'Songs');

  final albumSummary = await _squashDuplicateAlbums(db);
  final songSummary = await _squashDuplicateSongs(db);
  final orphanSummary = await _removeOrphanedAlbums(db);

  final albumsAfter = await _count(db, 'Albums');
  final songsAfter = await _count(db, 'Songs');

  await db.close();

  // Step 6: only after a fully successful run, replace the original.
  workingFile.copySync(dbPath);
  workingFile.deleteSync();

  print('\n--- Summary ---');
  print(
    'Albums: $albumsBefore -> $albumsAfter '
    '(merged ${albumSummary.groupsMerged} groups, removed ${albumSummary.rowsRemoved} duplicate rows, '
    'removed ${orphanSummary.rowsRemoved} zero-song orphaned rows)',
  );
  print(
    'Songs:  $songsBefore -> $songsAfter '
    '(merged ${songSummary.groupsMerged} groups, removed ${songSummary.rowsRemoved} rows)',
  );
  final warnings = [...albumSummary.warnings, ...songSummary.warnings, ...orphanSummary.warnings];
  if (warnings.isNotEmpty) {
    print('\nWarnings:');
    for (final w in warnings) {
      print('  - $w');
    }
  }
  print('\nDone. $dbPath updated. Backup kept at $backupPath.');
}

Future<int> _count(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
  return rows.first['c'] as int;
}

/// Picks the canonical row among a duplicate group: prefer one with a
/// non-null spotifyURI (to keep a working Spotify link when some rows
/// -- e.g. older CSV-era imports -- might lack one), then the most
/// recently-inserted (highest id) among those, on the theory that a more
/// recent import reflects Spotify's current catalog data more closely.
Map<String, Object?> _pickCanonical(List<Map<String, Object?>> rows) {
  final sorted = [...rows]..sort((a, b) {
    final aHasUri = a['spotifyURI'] != null;
    final bHasUri = b['spotifyURI'] != null;
    if (aHasUri != bHasUri) return aHasUri ? -1 : 1;
    return (b['id'] as int).compareTo(a['id'] as int);
  });
  return sorted.first;
}

/// Merges Albums rows sharing the same (name, artist) pair -- name
/// compared case/whitespace-insensitively in Dart, not SQL, since
/// sqlite's `lower()` is ASCII-only and would miss non-ASCII casing
/// (same reasoning as the ingestion code's own title/name matching).
Future<_MergeSummary> _squashDuplicateAlbums(Database db) async {
  final summary = _MergeSummary();

  final allAlbums = await db.query('Albums');
  final groups = <String, List<Map<String, Object?>>>{};
  for (final row in allAlbums) {
    final key = '${(row['name'] as String).trim().toLowerCase()}|${row['artist']}';
    groups.putIfAbsent(key, () => []).add(row);
  }

  await db.transaction((txn) async {
    for (final rows in groups.values) {
      if (rows.length < 2) continue;

      final canonical = _pickCanonical(rows);
      final canonicalId = canonical['id'] as int;
      final losers = rows.where((r) => r['id'] != canonicalId).toList();
      final loserIds = losers.map((r) => r['id'] as int).toList();

      // Backfill the canonical row's null fields from a loser that has one.
      for (final field in ['recordLabel', 'coverImageURL']) {
        if (canonical[field] != null) continue;
        for (final loser in losers) {
          final value = loser[field];
          if (value != null) {
            await txn.update(
              'Albums',
              {field: value},
              where: 'id = ?',
              whereArgs: [canonicalId],
            );
            break;
          }
        }
      }

      final placeholders = List.filled(loserIds.length, '?').join(',');
      await txn.rawUpdate(
        'UPDATE Songs SET album = ? WHERE album IN ($placeholders)',
        [canonicalId, ...loserIds],
      );
      await txn.rawDelete(
        'DELETE FROM Albums WHERE id IN ($placeholders)',
        loserIds,
      );

      summary.groupsMerged++;
      summary.rowsRemoved += loserIds.length;
    }
  });

  return summary;
}

/// Deletes Albums rows with zero attached Songs -- see the top-of-file
/// comment for why these exist. `groupsMerged` is left at 0 on the
/// returned summary; this pass doesn't merge anything, just deletes.
Future<_MergeSummary> _removeOrphanedAlbums(Database db) async {
  final summary = _MergeSummary();

  final orphanRows = await db.rawQuery('''
    SELECT al.id, al.name FROM Albums al
    LEFT JOIN Songs s ON s.album = al.id
    WHERE s.id IS NULL
  ''');
  if (orphanRows.isEmpty) return summary;

  final ids = orphanRows.map((r) => r['id'] as int).toList();
  final placeholders = List.filled(ids.length, '?').join(',');
  await db.transaction((txn) async {
    await txn.rawDelete('DELETE FROM Albums WHERE id IN ($placeholders)', ids);
  });

  summary.rowsRemoved = ids.length;
  return summary;
}

/// Merges Songs rows sharing the same name (case/whitespace-insensitive,
/// in Dart) *within the same album* -- only ever a byproduct of the
/// album merge above, never a library-wide name match (which would
/// wrongly conflate legitimate cases like a track appearing on both a
/// studio album and a compilation).
Future<_MergeSummary> _squashDuplicateSongs(Database db) async {
  final summary = _MergeSummary();

  final allSongs = await db.query('Songs');
  final groups = <String, List<Map<String, Object?>>>{};
  for (final row in allSongs) {
    final key = '${row['album']}|${(row['name'] as String).trim().toLowerCase()}';
    groups.putIfAbsent(key, () => []).add(row);
  }

  await db.transaction((txn) async {
    for (final rows in groups.values) {
      if (rows.length < 2) continue;
      final name = rows.first['name'] as String;

      final canonical = _pickCanonical(rows);
      final canonicalId = canonical['id'] as int;
      final loserIds = rows
          .where((r) => r['id'] != canonicalId)
          .map((r) => r['id'] as int)
          .toList();

      for (final loserId in loserIds) {
        // Backfill SongsExtraData null fields on canonical from loser.
        final canonicalExtraRows = await txn.query(
          'SongsExtraData',
          where: 'song = ?',
          whereArgs: [canonicalId],
        );
        final loserExtraRows = await txn.query(
          'SongsExtraData',
          where: 'song = ?',
          whereArgs: [loserId],
        );
        if (canonicalExtraRows.isNotEmpty && loserExtraRows.isNotEmpty) {
          final canonicalExtra = canonicalExtraRows.first;
          final loserExtra = loserExtraRows.first;
          final updates = <String, Object?>{};
          for (final field in [
            'discNumber',
            'albumTrackNumber',
            'audioPreviewURL',
            'popularity',
            'ISRC',
          ]) {
            if (canonicalExtra[field] == null && loserExtra[field] != null) {
              updates[field] = loserExtra[field];
            }
          }
          if (updates.isNotEmpty) {
            await txn.update(
              'SongsExtraData',
              updates,
              where: 'song = ?',
              whereArgs: [canonicalId],
            );
          }
        }
        if (loserExtraRows.isNotEmpty) {
          await txn.delete('SongsExtraData', where: 'song = ?', whereArgs: [loserId]);
        }

        // Adopt an orphaned SongsAudioFeatures row if canonical has none
        // -- never overwrite an existing one.
        final canonicalHasFeatures = (await txn.query(
          'SongsAudioFeatures',
          where: 'song = ?',
          whereArgs: [canonicalId],
        )).isNotEmpty;
        if (canonicalHasFeatures) {
          await txn.delete('SongsAudioFeatures', where: 'song = ?', whereArgs: [loserId]);
        } else {
          await txn.update(
            'SongsAudioFeatures',
            {'song': canonicalId},
            where: 'song = ?',
            whereArgs: [loserId],
          );
        }

        // Repoint SongsMixlists, dropping any that would collide with an
        // existing (canonical, mixlist) pair instead of creating one.
        final loserMixlistRows = await txn.query(
          'SongsMixlists',
          where: 'song = ?',
          whereArgs: [loserId],
        );
        for (final smRow in loserMixlistRows) {
          final mixlistId = smRow['mixlist'] as int;
          final alreadyThere = (await txn.query(
            'SongsMixlists',
            where: 'song = ? AND mixlist = ?',
            whereArgs: [canonicalId, mixlistId],
          )).isNotEmpty;
          if (alreadyThere) {
            summary.warnings.add(
              "Song $loserId ('$name') was already in mixlist $mixlistId under "
              'canonical song $canonicalId -- dropped the duplicate SongsMixlists row.',
            );
            await txn.delete('SongsMixlists', where: 'id = ?', whereArgs: [smRow['id']]);
          } else {
            await txn.update(
              'SongsMixlists',
              {'song': canonicalId},
              where: 'id = ?',
              whereArgs: [smRow['id']],
            );
          }
        }

        await txn.delete('Songs', where: 'id = ?', whereArgs: [loserId]);
      }

      summary.groupsMerged++;
      summary.rowsRemoved += loserIds.length;
    }
  });

  return summary;
}
