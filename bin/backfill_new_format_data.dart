// One-time migration/backfill script -- not part of the shipped app.
//
// Reads every CSV under `assets/mixlists_new_format/` (the newer, richer
// Spotify export format: no per-artist/album URIs, but genres/record
// label/audio features) and, for each file:
//   - content-matches it against the existing database by Track URI
//     overlap (never trusts the filename alone -- several of the new
//     export's filenames had punctuation silently stripped) to find which
//     existing mixlist it re-exports, or confirms it's genuinely new;
//   - backfills genres/record label/audio features onto already-seeded
//     songs (matched by spotifyURI) without touching their existing
//     URI/disc-number/ISRC data;
//   - inserts any genuinely new songs/mixlists via the same shared
//     get-or-create logic the in-app "Add New Mixlist" feature uses.
//
// Usage:
//   dart run bin/backfill_new_format_data.dart [--db <path>] [--csv-dir <path>] [--apply-titles]
//
// Always operates on a backup + working copy of --db, only overwriting the
// given path itself once the full run succeeds. Run it once against a copy
// of assets/database/mixlists.db to sanity-check the printed summary
// before pointing it at the real file.

// Print statements are the only output this script has.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A file's rows count toward an existing mixlist only if the majority of
/// its Track URIs already belong to that one mixlist. Real data here is
/// never ambiguous (matches are consistently ~90-100% or ~0%), so a plain
/// majority threshold is sufficient -- no need for a finer heuristic.
const _backfillMatchThreshold = 0.5;

class _TitleReviewEntry {
  final int mixlistId;
  final String currentTitle;
  final String proposedTitle;
  _TitleReviewEntry(this.mixlistId, this.currentTitle, this.proposedTitle);
}

class _Summary {
  int mixlistsBackfilled = 0;
  int mixlistsInserted = 0;
  int songsBackfilled = 0;
  int songsInserted = 0;
  final warnings = <String>[];
}

Future<void> main(List<String> args) async {
  String dbPath = 'assets/database/mixlists.db';
  String csvDir = 'assets/mixlists_new_format';
  var applyTitles = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--db':
        dbPath = args[++i];
      case '--csv-dir':
        csvDir = args[++i];
      case '--apply-titles':
        applyTitles = true;
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(1);
    }
  }

  final dbFile = File(dbPath);
  if (!dbFile.existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(1);
  }

  // Step 1: back up, non-negotiable.
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupPath = '$dbPath.pre-v3-backup-$timestamp';
  dbFile.copySync(backupPath);
  print('Backed up $dbPath -> $backupPath');

  // Step 2: work on a separate copy, never the original, until success.
  // sqflite_common_ffi resolves a relative path against its own default
  // databases directory (.dart_tool/sqflite_common_ffi/databases/), not
  // the working directory -- openDatabase needs an absolute path or it
  // silently opens/creates a different, empty file there instead.
  final workingPath = p.absolute('$dbPath.migrating');
  final workingFile = File(workingPath);
  if (workingFile.existsSync()) workingFile.deleteSync();
  dbFile.copySync(workingPath);

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await openDatabase(workingPath);

  final currentVersion = await db.getVersion();
  if (currentVersion < 3) {
    await applySchemaV3(db);
    await db.setVersion(3);
    print('Applied schema v3 to working copy.');
  } else {
    print('Working copy already at schema v3.');
  }

  final repo = MusicLibraryRepository(db);
  final summary = _Summary();
  final titleReview = <_TitleReviewEntry>[];

  final csvFiles =
      Directory(csvDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  print('Found ${csvFiles.length} CSV files under $csvDir.');

  for (final file in csvFiles) {
    final content = file.readAsStringSync();
    final List<MixlistCsvRow> rows;
    try {
      rows = MixlistCsvParser.parse(content);
    } on MixlistCsvParseException catch (e) {
      summary.warnings.add('Skipped ${file.path}: $e');
      continue;
    }

    final trackURIs = rows.map((r) => r.trackURI).toList();
    final placeholders = List.filled(trackURIs.length, '?').join(',');
    final matchRows = await db.rawQuery('''
      SELECT sm.mixlist AS mixlistId, COUNT(*) AS cnt
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      WHERE s.spotifyURI IN ($placeholders)
      GROUP BY sm.mixlist
      ORDER BY cnt DESC
      LIMIT 1
    ''', trackURIs);

    final topMatch = matchRows.isEmpty ? null : matchRows.first;
    final matchRatio = topMatch == null
        ? 0.0
        : (topMatch['cnt'] as int) / rows.length;

    if (topMatch != null && matchRatio >= _backfillMatchThreshold) {
      final mixlistId = topMatch['mixlistId'] as int;
      await _backfillIntoExistingMixlist(
        db,
        repo,
        mixlistId: mixlistId,
        rows: rows,
        summary: summary,
      );
      summary.mixlistsBackfilled++;

      final currentTitleRow = (await db.query(
        'Mixlists',
        columns: ['title'],
        where: 'id = ?',
        whereArgs: [mixlistId],
      )).first;
      final currentTitle = currentTitleRow['title'] as String;
      final proposedTitle = MixlistCsvParser.titleFromFilePath(file.path);
      if (currentTitle.trim().toLowerCase() !=
          proposedTitle.trim().toLowerCase()) {
        titleReview.add(
          _TitleReviewEntry(mixlistId, currentTitle, proposedTitle),
        );
      }
    } else {
      final title = MixlistCsvParser.titleFromFilePath(file.path);
      try {
        await repo.ingestion.importMixlistFromCsvRows(
          title: title,
          description: '',
          rows: rows,
        );
        summary.mixlistsInserted++;
        summary.songsInserted += rows.length;
        print(
          "Inserted new mixlist '$title' (${rows.length} tracks) from ${file.path}",
        );
      } on MixlistTitleExistsException catch (e) {
        summary.warnings.add(
          '${file.path}: $e (no content match found, but title collides)',
        );
      }
    }
  }

  // Step 4: print the title review list. Never auto-rename without
  // --apply-titles -- some of the current titles are themselves already
  // missing characters from the original 2018-era seeding, so a superset
  // filename-derived title is a good guess, not a certainty.
  if (titleReview.isNotEmpty) {
    print('\n--- Title review (${titleReview.length} mixlists) ---');
    for (final entry in titleReview) {
      print(
        "  [${entry.mixlistId}] '${entry.currentTitle}' -> '${entry.proposedTitle}'",
      );
    }
    if (applyTitles) {
      for (final entry in titleReview) {
        await db.update(
          'Mixlists',
          {'title': entry.proposedTitle},
          where: 'id = ?',
          whereArgs: [entry.mixlistId],
        );
      }
      print(
        'Applied all ${titleReview.length} title updates (--apply-titles).',
      );
    } else {
      print('Not applying title changes (pass --apply-titles to write them).');
    }
  }

  print('\n--- Summary ---');
  print('Mixlists backfilled: ${summary.mixlistsBackfilled}');
  print('Mixlists inserted:   ${summary.mixlistsInserted}');
  print('Songs backfilled:    ${summary.songsBackfilled}');
  print('Songs inserted:      ${summary.songsInserted}');
  if (summary.warnings.isNotEmpty) {
    print('\nWarnings:');
    for (final w in summary.warnings) {
      print('  - $w');
    }
  }

  await db.close();

  // Step 6: only after a fully successful run, replace the original.
  workingFile.copySync(dbPath);
  workingFile.deleteSync();
  print('\nDone. $dbPath updated. Backup kept at $backupPath.');
}

/// Backfills [rows] into an already-matched, already-existing [mixlistId].
/// For a row whose Track URI already exists, this updates only the
/// currently-null genres/recordLabel/audio-features fields on that song's
/// existing Artist/Album/SongsAudioFeatures rows -- never touching
/// spotifyURI/disc-number/ISRC/etc, which are preserved from the original
/// seeding. A row whose Track URI doesn't exist yet (a track added to this
/// mixlist since original seeding) is inserted fresh via the same
/// get-or-create path the in-app feature uses.
Future<void> _backfillIntoExistingMixlist(
  Database db,
  MusicLibraryRepository repo, {
  required int mixlistId,
  required List<MixlistCsvRow> rows,
  required _Summary summary,
}) async {
  await db.transaction((txn) async {
    var position = 1;
    for (final row in rows) {
      final existingSongs = await txn.query(
        'Songs',
        where: 'spotifyURI = ?',
        whereArgs: [row.trackURI],
        limit: 1,
      );

      int songId;
      if (existingSongs.isNotEmpty) {
        songId = existingSongs.first['id'] as int;
        final albumId = existingSongs.first['album'] as int;
        final albumRows = await txn.query(
          'Albums',
          where: 'id = ?',
          whereArgs: [albumId],
          limit: 1,
        );
        final artistId = albumRows.first['artist'] as int;

        if (row.genres != null) {
          await txn.update(
            'Artists',
            {'genres': row.genres},
            where: 'id = ? AND genres IS NULL',
            whereArgs: [artistId],
          );
        }
        if (row.recordLabel != null) {
          await txn.update(
            'Albums',
            {'recordLabel': row.recordLabel},
            where: 'id = ? AND recordLabel IS NULL',
            whereArgs: [albumId],
          );
        }
        summary.songsBackfilled++;
      } else {
        final artistId = await repo.ingestion.getOrCreateArtistId(
          txn,
          spotifyURI: row.albumArtistURI,
          name: row.albumArtistName,
          genres: row.genres,
        );
        final albumId = await repo.ingestion.getOrCreateAlbumId(
          txn,
          spotifyURI: row.albumURI,
          name: row.albumName,
          releaseDate: row.albumReleaseDate,
          coverImageURL: row.albumImageURL,
          artistId: artistId,
          recordLabel: row.recordLabel,
        );
        final songCountBefore =
            (await txn.rawQuery('SELECT COUNT(*) AS c FROM Songs')).first['c']
                as int;
        songId = await repo.ingestion.getOrCreateSongId(
          txn,
          spotifyURI: row.trackURI,
          name: row.trackName,
          artists: row.artistNames,
          artistsURIs: row.artistURIs,
          albumId: albumId,
          durationMs: row.durationMs,
          buildExtraData: (id) => SongExtraData(
            id: 0,
            discNumber: row.discNumber,
            albumTrackNumber: row.albumTrackNumber,
            durationMs: row.durationMs,
            audioPreviewURL: row.audioPreviewURL,
            isExplicit: row.isExplicit,
            popularity: row.popularity,
            isrc: row.isrc,
            songID: id,
          ),
        );
        final songCountAfter =
            (await txn.rawQuery('SELECT COUNT(*) AS c FROM Songs')).first['c']
                as int;
        // getOrCreateSongId may have matched an existing song via its
        // (name, album, duration) URI-reassignment fallback instead of
        // truly inserting -- only count it as "inserted" if the table
        // actually grew, so the summary doesn't overstate genuinely new
        // songs (this also refreshes that song's spotifyURI in place; see
        // getOrCreateSongId's doc comment).
        if (songCountAfter != songCountBefore) {
          summary.songsInserted++;
        } else {
          summary.songsBackfilled++;
        }
      }

      await repo.ingestion.upsertSongAudioFeatures(
        txn,
        songId: songId,
        row: row,
      );

      final smExists = await txn.query(
        'SongsMixlists',
        where: 'song = ? AND mixlist = ?',
        whereArgs: [songId, mixlistId],
        limit: 1,
      );
      if (smExists.isEmpty) {
        await txn.insert('SongsMixlists', {
          'positionIndex': position,
          'dateAdded': row.addedAt,
          'song': songId,
          'mixlist': mixlistId,
        });
      }
      position++;
    }
  });
}
