part of 'music_library_repository.dart';

/// `AND $alias.is_mixlists = 0/1` (empty for [MixlistFilter.all]) for a
/// clause joining `Mixlists` as [alias]. A closed enum, so interpolating is
/// safe.
String _mixlistFilterSql(MixlistFilter filter, String alias) {
  switch (filter) {
    case MixlistFilter.all:
      return '';
    case MixlistFilter.mixlistsOnly:
      return 'AND $alias.is_mixlists = 1';
    case MixlistFilter.nonMixlistsOnly:
      return 'AND $alias.is_mixlists = 0';
  }
}

extension MixlistQueries on MusicLibraryRepository {
  /// Every mixlist, oldest first by `id`: ids are chronological (never
  /// deleted, no gaps), while `dateCreated` is backfilled and can drift.
  Future<List<Mixlist>> getAllMixlists({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final where = switch (filter) {
      MixlistFilter.all => null,
      MixlistFilter.mixlistsOnly => 'is_mixlists = 1',
      MixlistFilter.nonMixlistsOnly => 'is_mixlists = 0',
    };
    final rows = await _db.query('Mixlists', where: where, orderBy: 'id ASC');
    return rows.map(Mixlist.fromMap).toList();
  }

  Future<Mixlist?> getMixlistById(int id) async {
    final rows = await _db.query(
      'Mixlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Mixlist.fromMap(rows.first);
  }

  /// Nearest mixlists before/after [mixlist] by id within [filter], so the
  /// detail screen's prev/next stays inside the globally filtered set.
  Future<(Mixlist? previous, Mixlist? next)> getAdjacentMixlists(
    Mixlist mixlist, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterWhere = switch (filter) {
      MixlistFilter.all => null,
      MixlistFilter.mixlistsOnly => 'is_mixlists = 1',
      MixlistFilter.nonMixlistsOnly => 'is_mixlists = 0',
    };

    final previousRows = await _db.query(
      'Mixlists',
      where: filterWhere == null ? 'id < ?' : '(id < ?) AND ($filterWhere)',
      whereArgs: [mixlist.id],
      orderBy: 'id DESC',
      limit: 1,
    );
    final nextRows = await _db.query(
      'Mixlists',
      where: filterWhere == null ? 'id > ?' : '(id > ?) AND ($filterWhere)',
      whereArgs: [mixlist.id],
      orderBy: 'id ASC',
      limit: 1,
    );

    return (
      previousRows.isEmpty ? null : Mixlist.fromMap(previousRows.first),
      nextRows.isEmpty ? null : Mixlist.fromMap(nextRows.first),
    );
  }

  /// 1-based position of [mixlistId] under [filter], i.e. its display number.
  /// Computed here since the detail screen has many entry points.
  Future<int> getMixlistPosition(
    int mixlistId, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterWhere = switch (filter) {
      MixlistFilter.all => null,
      MixlistFilter.mixlistsOnly => 'is_mixlists = 1',
      MixlistFilter.nonMixlistsOnly => 'is_mixlists = 0',
    };
    final where = filterWhere == null
        ? 'id <= ?'
        : '(id <= ?) AND ($filterWhere)';
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS position FROM Mixlists WHERE $where',
      [mixlistId],
    );
    return rows.first['position'] as int;
  }

  /// The "Mark Mixlists" write path: sets `is_mixlists`, invalidates
  /// [MixlistScopeIndex] and notifies listeners.
  Future<void> setMixlistFlags(Map<int, bool> flags) async {
    final batch = _db.batch();
    for (final entry in flags.entries) {
      batch.update(
        'Mixlists',
        {'is_mixlists': entry.value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
    _mixlistScopeIndexFuture = null;
    _notifyMutated();
  }

  /// All tracks in [mixlistId], in playback order, with the album name
  /// / cover art and duration / explicit / popularity fields a track
  /// list or "now playing" screen needs -- fetched with one JOIN
  Future<List<MixlistTrack>> getTracksForMixlist(int mixlistId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        sm.positionIndex   AS positionIndex,
        sm.dateAdded       AS dateAdded,
        s.id               AS songId,
        s.spotifyURI       AS songSpotifyURI,
        s.name             AS songName,
        s.artists          AS artists,
        s.artistsURIs      AS artistsURIs,
        al.artist          AS artistId,
        al.id              AS albumId,
        al.name            AS albumName,
        al.coverImageURL   AS albumCoverImageURL,
        al.releaseDate     AS albumReleaseDate,
        ed.durationMs      AS durationMs,
        ed.explicit        AS explicit,
        ed.popularity      AS popularity,
        ed.audioPreviewURL AS audioPreviewURL,
        af.danceability    AS danceability,
        af.energy          AS energy,
        af.key             AS key,
        af.loudness        AS loudness,
        af.mode            AS mode,
        af.speechiness     AS speechiness,
        af.acousticness    AS acousticness,
        af.instrumentalness AS instrumentalness,
        af.liveness        AS liveness,
        af.valence         AS valence,
        af.tempo           AS tempo,
        af.timeSignature   AS timeSignature
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      LEFT JOIN SongsAudioFeatures af ON af.song = s.id
      WHERE sm.mixlist = ?
      ORDER BY sm.positionIndex ASC
    ''',
      [mixlistId],
    );

    return rows.map(MixlistTrack.fromMap).toList();
  }

  /// Mixlist id -> track count, for every mixlist with at least one track,
  /// in one grouped query (absent key means empty).
  Future<Map<int, int>> getMixlistSongCounts() async {
    final rows = await _db.rawQuery(
      'SELECT mixlist, COUNT(*) AS songCount FROM SongsMixlists GROUP BY mixlist',
    );
    return {
      for (final row in rows) row['mixlist'] as int: row['songCount'] as int,
    };
  }

  /// Up to [limit] distinct album cover URLs for [mixlistId] in track order,
  /// for [PlaylistCoverGrid]. Null entries (album without art) are kept.
  Future<List<String?>> getMixlistCoverArt(
    int mixlistId, {
    int limit = 4,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT al.coverImageURL AS coverImageURL, MIN(sm.positionIndex) AS minPosition
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      WHERE sm.mixlist = ?
      GROUP BY al.id
      ORDER BY minPosition ASC
      LIMIT ?
    ''',
      [mixlistId, limit],
    );
    return rows.map((row) => row['coverImageURL'] as String?).toList();
  }

  /// Song id -> its mixlists, for songs on 2+ mixlists within [filter], so
  /// `containsKey` means duplicate. Uncached; go through
  /// [DuplicateSongIndexController] for a warm, auto-reloading copy.
  Future<Map<int, List<MixlistSummary>>> duplicateSongIndex({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final outerFilterSql = _mixlistFilterSql(filter, 'm');
    final innerFilterSql = _mixlistFilterSql(filter, 'm2');
    final rows = await _db.rawQuery('''
      SELECT sm.song AS songId, m.id AS mixlistId, m.title AS mixlistTitle
      FROM SongsMixlists sm
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE sm.song IN (
        SELECT sm2.song
        FROM SongsMixlists sm2
        JOIN Mixlists m2 ON m2.id = sm2.mixlist
        WHERE 1 = 1 $innerFilterSql
        GROUP BY sm2.song
        HAVING COUNT(DISTINCT sm2.mixlist) > 1
      )
      $outerFilterSql
      ORDER BY sm.song, m.title
    ''');

    final duplicatesIndex = <int, List<MixlistSummary>>{};
    for (final row in rows) {
      final songId = row['songId'] as int;
      final summary = MixlistSummary(
        id: row['mixlistId'] as int,
        title: row['mixlistTitle'] as String,
      );
      duplicatesIndex.putIfAbsent(songId, () => []).add(summary);
    }
    return duplicatesIndex;
  }
}
