import 'package:mixlists_project/models/mixlist_summary.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/mixlist_track.dart';
import '../daos/album_dao.dart';
import '../daos/artist_dao.dart';
import '../daos/mixlist_dao.dart';
import '../daos/song_dao.dart';
import '../daos/song_extra_data_dao.dart';
import '../daos/song_mixlist_dao.dart';

/// The single object screens talk to for data access. It composes the
/// per-table DAOs and owns any query that spans more than one table.
///
/// That split matters because sqflite's `db.query()` convenience method
/// only builds single-table SELECTs (it's a thin wrapper that assembles
/// `SELECT ... FROM <one table> WHERE ...`) -- there's no `join()`
/// argument. Anything that needs a JOIN, a GROUP BY, or hand-written
/// SQL for any other reason has to go through `db.rawQuery()` instead.
class MusicLibraryRepository {
  MusicLibraryRepository(this._db)
      : mixlists = MixlistDao(_db),
        artists = ArtistDao(_db),
        albums = AlbumDao(_db),
        songs = SongDao(_db),
        songExtraData = SongExtraDataDao(_db),
        songMixlists = SongMixlistDao(_db);

  final Database _db;

  final MixlistDao mixlists;
  final ArtistDao artists;
  final AlbumDao albums;
  final SongDao songs;
  final SongExtraDataDao songExtraData;
  final SongMixlistDao songMixlists;

  /// All tracks in [mixlistId], in playback order, with the album name
  /// / cover art and duration / explicit / popularity fields a track
  /// list or "now playing" screen needs -- fetched with one JOIN
  Future<List<MixlistTrack>> getTracksForMixlist(int mixlistId) async {
    final rows = await _db.rawQuery('''
      SELECT
        sm.positionIndex   AS positionIndex,
        sm.dateAdded       AS dateAdded,
        s.id               AS songId,
        s.spotifyURI       AS songSpotifyURI,
        s.name             AS songName,
        s.artists          AS artists,
        s.artistsURIs      AS artistsURIs,
        al.id              AS albumId,
        al.name            AS albumName,
        al.coverImageURL   AS albumCoverImageURL,
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
    ''', [mixlistId]);

    return rows.map(MixlistTrack.fromMap).toList();
  }

  // This assumes SongsMixlists doesn't change during the app's lifetime,
  // which is true today (the database is read-only, seeded data). If you
  // add editing later (adding/removing a song from a mixlist), call
  // `invalidateDuplicateSongIndex()` after that write so the next read
  // recomputes it.
  Future<Map<int, List<MixlistSummary>>>? _duplicateSongIndexFuture;
 
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

  Future<void> close() => _db.close();
}