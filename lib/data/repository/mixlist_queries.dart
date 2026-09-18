part of 'music_library_repository.dart';

/// A SQL fragment (`AND $alias.is_mixlists = 0/1`, or empty for
/// [MixlistFilter.all]) to append to a `WHERE`/`ON` clause that already
/// joins in a `Mixlists` row aliased as [alias]. The three states are a
/// fixed, closed set (not user input), so interpolating the literal
/// 0/1 directly is fine -- no injection surface.
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
  /// Every mixlist, oldest-created first. `id` order is chronological
  /// order here (mixlists are never deleted, so ids never leave gaps) --
  /// `dateCreated` is not reliable for this, since it's backfilled from
  /// CSV track data and can drift (e.g. a track re-added to a playlist
  /// after Spotify dropped it). Was `MixlistDao.getAll()`.
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

  /// The nearest mixlists before/after [mixlist] by id that also match
  /// [filter] -- see `getAllMixlists` for why id order is chronological
  /// order. [MixlistDetailScreen] doesn't show the filter toggle itself;
  /// it inherits whatever the global filter was when navigated into, so
  /// prev/next only ever step within that same filtered set (e.g.
  /// browsing "mixlists only", next/previous skip over anything marked
  /// as not a mixlist rather than landing on it). With
  /// [MixlistFilter.all] this is equivalent to the old `id - 1`/`id + 1`
  /// lookup, since ids never have gaps.
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

  /// The 1-based position of [mixlistId] within the id-ordered list under
  /// [filter] -- the same number `AllMixlistsScreen` would show as this
  /// mixlist's display number under that filter. Computed straight from
  /// `(mixlistId, filter)` rather than passed in from wherever the
  /// caller navigated from, since [MixlistDetailScreen] is reachable
  /// from many places (the list itself, prev/next, a track's "other
  /// mixlists" link) and a self-contained query stays correct regardless
  /// of entry point instead of needing every call site to thread an
  /// index through.
  Future<int> getMixlistPosition(
    int mixlistId, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterWhere = switch (filter) {
      MixlistFilter.all => null,
      MixlistFilter.mixlistsOnly => 'is_mixlists = 1',
      MixlistFilter.nonMixlistsOnly => 'is_mixlists = 0',
    };
    final where = filterWhere == null ? 'id <= ?' : '(id <= ?) AND ($filterWhere)';
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS position FROM Mixlists WHERE $where',
      [mixlistId],
    );
    return rows.first['position'] as int;
  }

  /// Sets `is_mixlists` for every mixlist id in [flags] to the given
  /// value -- the write path for the "Mark Mixlists" screen.
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

  /// Maps a song's id to every mixlist it's on, for songs on more than
  /// one within [filter] -- absent from the map otherwise, so
  /// `containsKey` doubles as the "is this a duplicate?" check. Cached
  /// per [filter], since which mixlists count toward "duplicate" (and
  /// which appearances get listed) depends on it.
  Future<Map<int, List<MixlistSummary>>> duplicateSongIndex({
    MixlistFilter filter = MixlistFilter.all,
  }) {
    return _duplicateSongIndexFutures[filter] ??= _loadDuplicateSongIndex(
      filter,
    );
  }

  Future<Map<int, List<MixlistSummary>>> _loadDuplicateSongIndex(
    MixlistFilter filter,
  ) async {
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
