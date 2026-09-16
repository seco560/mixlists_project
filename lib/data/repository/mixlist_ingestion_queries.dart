part of 'music_library_repository.dart';

/// Write path for importing a mixlist from parsed CSV rows -- the only
/// extension that performs INSERTs/UPDATEs, everything else in this
/// repository is read-only. The get-or-create helpers are intentionally
/// generic (keyed by spotifyURI, not import-specific) so the one-time
/// `bin/backfill_new_format_data.dart` migration script reuses them too,
/// and so a later "merge spurious duplicates" cleanup tool can as well.
extension MixlistIngestionQueries on MusicLibraryRepository {
  /// True if a Mixlists row with this title already exists (case- and
  /// whitespace-insensitive, since re-exports of the same mixlist have
  /// been observed with drifted casing). The comparison happens in Dart,
  /// not SQL -- sqlite's built-in `lower()` only folds ASCII, so a name
  /// with e.g. a Romanian 'Ș' would never match its own lowercase form via
  /// `lower(trim(x)) = ?` (confirmed: this exact mismatch left one
  /// non-ASCII artist name duplicated after using that approach for
  /// get-or-create matching -- see [getOrCreateArtistId]). The Mixlists
  /// table is small enough (a few hundred rows at most) that fetching
  /// every title and comparing in Dart is cheap and avoids the whole
  /// class of bug.
  Future<bool> mixlistTitleExists(String title) async {
    final normalized = title.trim().toLowerCase();
    final rows = await _db.query('Mixlists', columns: ['title']);
    return rows.any(
      (row) => (row['title'] as String).trim().toLowerCase() == normalized,
    );
  }

  /// Returns the id of the Artist row identified by [spotifyURI], inserting
  /// one first if none exists. When [spotifyURI] is non-null this is a
  /// reliable natural key and matches across separate import runs. When
  /// it's null (an export format that carries no artist URIs at all), this
  /// falls back to matching by [name] against *every* existing Artist,
  /// regardless of whether that row itself has a spotifyURI -- there's no
  /// URI on this row to disambiguate with, so a name match is the best
  /// available signal, and reusing an already-URI'd row is exactly what
  /// should happen (it's the same real artist, we just don't have their
  /// URI from this particular export). An earlier version of this method
  /// scoped the fallback to `spotifyURI IS NULL` rows only, intending to
  /// avoid false merges -- in practice that just meant it could never find
  /// the real, already-linked artist, so it created a duplicate row for
  /// every artist that had a real URI already on file (confirmed: 42
  /// artists, e.g. 'Can't Swim', ended up duplicated this way; do not
  /// reintroduce that restriction). The name match is case/whitespace-
  /// insensitive and done in Dart, not SQL -- sqlite's `lower()` is
  /// ASCII-only and would silently fail to match a name like 'Apologies,
  /// I Have None' vs 'Apologies, i have none' against non-ASCII names such
  /// as one containing 'Ș' (confirmed this caused exactly one duplicate in
  /// this dataset before switching off `lower()`-in-SQL). If more than one
  /// row matches by name -- a genuine pre-existing duplicate, or two
  /// different real artists who happen to share a name -- this doesn't try
  /// to guess; it falls through to inserting a new row, leaving it for the
  /// deferred "spurious duplicates" cleanup pass.
  Future<int> getOrCreateArtistId(
    DatabaseExecutor txn, {
    required String? spotifyURI,
    required String name,
    String? genres,
  }) async {
    List<Map<String, Object?>> existing;
    if (spotifyURI != null) {
      existing = await txn.query(
        'Artists',
        columns: ['id'],
        where: 'spotifyURI = ?',
        whereArgs: [spotifyURI],
        limit: 1,
      );
    } else {
      final normalized = name.trim().toLowerCase();
      final all = await txn.query('Artists', columns: ['id', 'name']);
      existing = all
          .where(
            (row) => (row['name'] as String).trim().toLowerCase() == normalized,
          )
          .take(2)
          .toList();
    }

    if (existing.length == 1) {
      final artistId = existing.first['id'] as int;
      if (genres != null) {
        await txn.update(
          'Artists',
          {'genres': genres},
          where: 'id = ? AND genres IS NULL',
          whereArgs: [artistId],
        );
      }
      return artistId;
    }

    return txn.insert('Artists', {
      'spotifyURI': spotifyURI,
      'name': name,
      'genres': genres,
    });
  }

  /// Same pattern as [getOrCreateArtistId] for Albums, scoped by
  /// `(name, artistId)` when URI-less (matching the original Python
  /// prototype's cache key) -- matched against every existing Album for
  /// that artist, not just URI-less ones, and compared in Dart rather than
  /// via sqlite's ASCII-only `lower()`, for the same reasons described on
  /// [getOrCreateArtistId]. Backfills [recordLabel] only if the existing
  /// row doesn't have one yet (first-seen wins on conflicting labels).
  Future<int> getOrCreateAlbumId(
    DatabaseExecutor txn, {
    required String? spotifyURI,
    required String name,
    required String? releaseDate,
    required String? coverImageURL,
    required int artistId,
    String? recordLabel,
  }) async {
    List<Map<String, Object?>> existing;
    if (spotifyURI != null) {
      existing = await txn.query(
        'Albums',
        columns: ['id'],
        where: 'spotifyURI = ?',
        whereArgs: [spotifyURI],
        limit: 1,
      );
    } else {
      final normalized = name.trim().toLowerCase();
      final forArtist = await txn.query(
        'Albums',
        columns: ['id', 'name'],
        where: 'artist = ?',
        whereArgs: [artistId],
      );
      existing = forArtist
          .where(
            (row) => (row['name'] as String).trim().toLowerCase() == normalized,
          )
          .take(2)
          .toList();
    }

    if (existing.length == 1) {
      final albumId = existing.first['id'] as int;
      if (recordLabel != null) {
        await txn.update(
          'Albums',
          {'recordLabel': recordLabel},
          where: 'id = ? AND recordLabel IS NULL',
          whereArgs: [albumId],
        );
      }
      return albumId;
    }

    return txn.insert('Albums', {
      'spotifyURI': spotifyURI,
      'name': name,
      'releaseDate': releaseDate,
      'coverImageURL': coverImageURL,
      'recordLabel': recordLabel,
      'artist': artistId,
    });
  }

  /// Songs are primarily identified by [spotifyURI]. When that doesn't
  /// match anything, falls back to `(name, albumId, durationMs)` before
  /// creating a new row -- confirmed via this database that Spotify
  /// reassigns a track's URI over time (55 songs here have two different
  /// URIs for what is, by name/album/millisecond-exact duration, clearly
  /// the same recording; e.g. "Coding These to Lukens" on "Holy Ghost").
  /// Without this fallback, re-exporting an existing mixlist creates a
  /// phantom duplicate song and a second SongsMixlists row at the same
  /// position every time Spotify has reassigned a URI in that mixlist.
  /// durationMs is included (not just name+album) as a safety margin
  /// against a same-titled but genuinely different recording, e.g. a
  /// reissue's bonus track, being wrongly merged.
  ///
  /// On a fallback match, the existing row's spotifyURI is overwritten
  /// with [spotifyURI] when it differs -- the newest export is taken as
  /// authoritative, on the theory that Spotify's own catalog has moved on
  /// to the new id and the old one may eventually stop resolving. The
  /// Song's own row id never changes, so every existing FK into it
  /// (SongsMixlists, SongsExtraData, SongsAudioFeatures) stays valid --
  /// this is a URI refresh, not a merge of two rows. Only inserts the
  /// companion SongsExtraData row when the Song itself is newly created;
  /// an existing, reused song already has one.
  Future<int> getOrCreateSongId(
    DatabaseExecutor txn, {
    required String spotifyURI,
    required String name,
    required String artists,
    required String? artistsURIs,
    required int albumId,
    required int durationMs,
    required SongExtraData Function(int songId) buildExtraData,
  }) async {
    final byUri = await txn.query(
      'Songs',
      columns: ['id'],
      where: 'spotifyURI = ?',
      whereArgs: [spotifyURI],
      limit: 1,
    );
    if (byUri.isNotEmpty) return byUri.first['id'] as int;

    // durationMs tolerance: re-encodes/re-masters can shift a track's
    // reported length by a couple hundred ms (confirmed: 'PDA' by
    // Interpol differed by 160ms between its two URIs) without being a
    // genuinely different recording. 1000ms comfortably covers that while
    // staying far short of the multi-second gap a real different version
    // (acoustic, live, remix) would have.
    const toleranceMs = 1000;
    Future<List<int>> matchesAmong(List<Map<String, Object?>> candidates) async {
      final normalizedName = name.trim().toLowerCase();
      final matches = <int>[];
      for (final row in candidates) {
        if ((row['name'] as String).trim().toLowerCase() != normalizedName) {
          continue;
        }
        final candidateId = row['id'] as int;
        final extraRows = await txn.query(
          'SongsExtraData',
          columns: ['durationMs'],
          where: 'song = ?',
          whereArgs: [candidateId],
          limit: 1,
        );
        if (extraRows.isEmpty) continue;
        final candidateDuration = extraRows.first['durationMs'] as int;
        if ((candidateDuration - durationMs).abs() <= toleranceMs) {
          matches.add(candidateId);
        }
      }
      return matches;
    }

    final sameAlbum = await txn.query(
      'Songs',
      columns: ['id', 'name'],
      where: 'album = ?',
      whereArgs: [albumId],
    );
    var matchingIds = await matchesAmong(sameAlbum);

    // Fall back to a name+duration match across the whole library (not
    // scoped to this album) when nothing matched within the album -- this
    // catches the same recording being credited to a differently-
    // formatted multi-artist string across export runs (e.g. old export
    // 'Modern Baseball, Marietta' vs new export crediting more/fewer
    // collaborators or a different separator), which resolves to a
    // different Album row entirely. Deliberately does NOT reassign the
    // matched song's album/artist -- picking which credit is "more
    // correct" is exactly the deferred Artist-unification work, out of
    // scope here; this only stops the duplicate-track symptom.
    if (matchingIds.isEmpty) {
      // No SQL-side name filter here -- matchesAmong() already does the
      // real (Dart-side, Unicode-correct) comparison, and sqlite's
      // lower()/trim() are ASCII-only (see getOrCreateArtistId's doc
      // comment for the concrete bug that caused).
      final allSongs = await txn.query('Songs', columns: ['id', 'name']);
      matchingIds = await matchesAmong(allSongs);
    }

    if (matchingIds.length == 1) {
      final songId = matchingIds.first;
      await txn.update(
        'Songs',
        {'spotifyURI': spotifyURI},
        where: 'id = ? AND spotifyURI != ?',
        whereArgs: [songId, spotifyURI],
      );
      return songId;
    }

    final songId = await txn.insert('Songs', {
      'spotifyURI': spotifyURI,
      'name': name,
      'artists': artists,
      'artistsURIs': artistsURIs,
      'album': albumId,
    });
    final extra = buildExtraData(songId);
    final extraMap = extra.toMap()..remove('id');
    await txn.insert('SongsExtraData', extraMap);
    return songId;
  }

  /// Inserts a SongsAudioFeatures row for [songId] from [row] if one
  /// doesn't already exist. Never overwrites -- audio features don't
  /// change once captured.
  Future<void> upsertSongAudioFeatures(
    DatabaseExecutor txn, {
    required int songId,
    required MixlistCsvRow row,
  }) async {
    final existing = await txn.query(
      'SongsAudioFeatures',
      columns: ['id'],
      where: 'song = ?',
      whereArgs: [songId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    // Nothing worth storing if the row carries no audio-feature data at
    // all (e.g. it came from the original Exportify-format columns).
    if (row.danceability == null &&
        row.energy == null &&
        row.key == null &&
        row.loudness == null &&
        row.mode == null &&
        row.speechiness == null &&
        row.acousticness == null &&
        row.instrumentalness == null &&
        row.liveness == null &&
        row.valence == null &&
        row.tempo == null &&
        row.timeSignature == null) {
      return;
    }

    await txn.insert('SongsAudioFeatures', {
      'song': songId,
      'danceability': row.danceability,
      'energy': row.energy,
      'key': row.key,
      'loudness': row.loudness,
      'mode': row.mode,
      'speechiness': row.speechiness,
      'acousticness': row.acousticness,
      'instrumentalness': row.instrumentalness,
      'liveness': row.liveness,
      'valence': row.valence,
      'tempo': row.tempo,
      'timeSignature': row.timeSignature,
    });
  }

  /// Full atomic import: creates the Mixlist row, then for every CSV row
  /// get-or-creates Artist/Album/Song (+ SongsExtraData, + audio features)
  /// and always inserts a fresh SongsMixlists row (positionIndex = 1-based
  /// index into [rows], dateAdded = that row's addedAt). The Mixlist's
  /// dateCreated is the MIN of all rows' addedAt (not just the first row's
  /// -- the original Python prototype's printer script flagged that as
  /// unreliable).
  ///
  /// Throws [MixlistTitleExistsException] if [title] collides. Any other
  /// failure rolls back the entire transaction -- nothing partial is left
  /// behind.
  Future<int> importMixlistFromCsvRows({
    required String title,
    required String description,
    required List<MixlistCsvRow> rows,
  }) async {
    if (rows.isEmpty) {
      throw ArgumentError('Cannot import a mixlist with zero rows');
    }
    if (await mixlistTitleExists(title)) {
      throw MixlistTitleExistsException(title);
    }

    final dateCreated = rows
        .map((r) => r.addedAt)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);

    return _db.transaction<int>((txn) async {
      final mixlistId = await txn.insert('Mixlists', {
        'title': title,
        'description': description,
        'dateCreated': dateCreated,
      });

      var position = 1;
      for (final row in rows) {
        final artistId = await getOrCreateArtistId(
          txn,
          spotifyURI: row.albumArtistURI,
          name: row.albumArtistName,
          genres: row.genres,
        );
        final albumId = await getOrCreateAlbumId(
          txn,
          spotifyURI: row.albumURI,
          name: row.albumName,
          releaseDate: row.albumReleaseDate,
          coverImageURL: row.albumImageURL,
          artistId: artistId,
          recordLabel: row.recordLabel,
        );
        final songId = await getOrCreateSongId(
          txn,
          spotifyURI: row.trackURI,
          name: row.trackName,
          artists: row.artistNames,
          artistsURIs: row.artistURIs,
          albumId: albumId,
          durationMs: row.durationMs,
          buildExtraData: (songId) => SongExtraData(
            id: 0,
            discNumber: row.discNumber,
            albumTrackNumber: row.albumTrackNumber,
            durationMs: row.durationMs,
            audioPreviewURL: row.audioPreviewURL,
            isExplicit: row.isExplicit,
            popularity: row.popularity,
            isrc: row.isrc,
            songID: songId,
          ),
        );
        await upsertSongAudioFeatures(txn, songId: songId, row: row);
        await txn.insert('SongsMixlists', {
          'positionIndex': position,
          'dateAdded': row.addedAt,
          'song': songId,
          'mixlist': mixlistId,
        });
        position++;
      }
      return mixlistId;
    });
  }
}

/// Thrown by [MixlistIngestionQueries.importMixlistFromCsvRows] when
/// [title] already names an existing Mixlists row.
class MixlistTitleExistsException implements Exception {
  final String title;
  const MixlistTitleExistsException(this.title);
  @override
  String toString() => "A mixlist named '$title' already exists";
}
