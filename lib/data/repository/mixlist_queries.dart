part of 'music_library_repository.dart';

/// Mixlist-centered queries: the plain `Mixlists` table reads that used to
/// live on `MixlistDao` (folded in here -- it was the only DAO whose
/// methods were actually used anywhere in the app), the mixlist track
/// list, and the cross-mixlist duplicate-song index.
extension MixlistQueries on MusicLibraryRepository {
  /// Every mixlist, oldest-created first. Was `MixlistDao.getAll()`.
  Future<List<Mixlist>> getAllMixlists() async {
    final rows = await _db.query('Mixlists', orderBy: 'dateCreated ASC');
    return rows.map(Mixlist.fromMap).toList();
  }

  /// A single mixlist by id, or null if it doesn't exist. Was
  /// `MixlistDao.getById(int)`.
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
        ed.audioPreviewURL AS audioPreviewURL
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      WHERE sm.mixlist = ?
      ORDER BY sm.positionIndex ASC
    ''',
      [mixlistId],
    );

    return rows.map(MixlistTrack.fromMap).toList();
  }

  /// Maps a song's id to every mixlist it appears in, for songs that
  /// appear in more than one. Songs that only appear once are absent
  /// from the map entirely (rather than mapped to a single-item list),
  /// so `containsKey` doubles as the "is this a duplicate?" check.
  Future<Map<int, List<MixlistSummary>>> get duplicateSongIndex {
    return _duplicateSongIndexFuture ??= _loadDuplicateSongIndex();
  }

  /// Forces the next [duplicateSongIndex] access to recompute from the
  /// database instead of returning the cached map. Only needed once
  /// SongsMixlists can actually change at runtime.
  void invalidateDuplicateSongIndex() {
    _duplicateSongIndexFuture = null;
  }

  Future<Map<int, List<MixlistSummary>>> _loadDuplicateSongIndex() async {
    final rows = await _db.rawQuery('''
      SELECT sm.song AS songId, m.id AS mixlistId, m.title AS mixlistTitle
      FROM SongsMixlists sm
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE sm.song IN (
        SELECT song FROM SongsMixlists
        GROUP BY song
        HAVING COUNT(DISTINCT mixlist) > 1
      )
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
