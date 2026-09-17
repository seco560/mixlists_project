part of 'music_library_repository.dart';

extension MixlistQueries on MusicLibraryRepository {
  /// Every mixlist, oldest-created first. `id` order is chronological
  /// order here (mixlists are never deleted, so ids never leave gaps) --
  /// `dateCreated` is not reliable for this, since it's backfilled from
  /// CSV track data and can drift (e.g. a track re-added to a playlist
  /// after Spotify dropped it). Was `MixlistDao.getAll()`.
  Future<List<Mixlist>> getAllMixlists() async {
    final rows = await _db.query('Mixlists', orderBy: 'id ASC');
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

  /// The mixlists immediately before/after [mixlist] by id -- see
  /// `getAllMixlists` for why id order is used as chronological order.
  Future<(Mixlist? previous, Mixlist? next)> getAdjacentMixlists(
    Mixlist mixlist,
  ) async {
    final previous = await getMixlistById(mixlist.id - 1);
    final next = await getMixlistById(mixlist.id + 1);
    return (previous, next);
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
  /// one -- absent from the map otherwise, so `containsKey` doubles as
  /// the "is this a duplicate?" check.
  Future<Map<int, List<MixlistSummary>>> get duplicateSongIndex {
    return _duplicateSongIndexFuture ??= _loadDuplicateSongIndex();
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
