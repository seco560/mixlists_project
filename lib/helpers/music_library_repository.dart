import 'package:mixlists_project/models/album_overview.dart';
import 'package:mixlists_project/models/album_song_appearance.dart';
import 'package:mixlists_project/models/album_summary.dart';
import 'package:mixlists_project/models/artist_overview.dart';
import 'package:mixlists_project/models/artist_song_appearance.dart';
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
    ''',
      [mixlistId],
    );

    return rows.map(MixlistTrack.fromMap).toList();
  }

  /// Every artist, with the albums they released (Albums.artist), every
  /// mixlist a song off one of those albums appears in
  /// (Albums -> Songs -> SongsMixlists -> Mixlists), and how many
  /// distinct songs of theirs show up across all mixlists.
  ///
  /// Deliberately flat queries grouped in Dart rather than one query
  /// joining everything: an artist with N albums and M mixlist
  /// appearances would otherwise come back as N*M rows that need
  /// collapsing anyway, or a GROUP_CONCAT-and-reparse hack. Same
  /// flat-rows-into-a-map shape as `duplicateSongIndex` below.
  Future<List<ArtistOverview>> getArtistOverviews() async {
    final allArtists = await artists.getAll();

    final albumRows = await _db.rawQuery('''
      SELECT
        artist         AS artistId,
        id             AS albumId,
        name           AS albumName,
        releaseDate,
        coverImageURL
      FROM Albums
      ORDER BY releaseDate ASC
    ''');
    final albumsByArtist = <int, List<AlbumSummary>>{};
    for (final row in albumRows) {
      final artistId = row['artistId'] as int;
      albumsByArtist
          .putIfAbsent(artistId, () => [])
          .add(
            AlbumSummary(
              id: row['albumId'] as int,
              name: row['albumName'] as String,
              releaseDate: row['releaseDate'] as String,
              coverImageURL: row['coverImageURL'] as String,
            ),
          );
    }

    final mixlistRows = await _db.rawQuery('''
      SELECT DISTINCT
        al.artist     AS artistId,
        m.id          AS mixlistId,
        m.title       AS mixlistTitle,
        m.dateCreated AS dateCreated
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      JOIN Mixlists m ON m.id = sm.mixlist
      ORDER BY m.dateCreated ASC
    ''');
    final mixlistsByArtist = <int, List<MixlistSummary>>{};
    for (final row in mixlistRows) {
      final artistId = row['artistId'] as int;
      mixlistsByArtist
          .putIfAbsent(artistId, () => [])
          .add(
            MixlistSummary(
              id: row['mixlistId'] as int,
              title: row['mixlistTitle'] as String,
              dateCreated: row['dateCreated'] as String,
            ),
          );
    }

    final songCountRows = await _db.rawQuery('''
      SELECT al.artist AS artistId, COUNT(DISTINCT s.id) AS songCount
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      GROUP BY al.artist
    ''');
    final songCountByArtist = <int, int>{
      for (final row in songCountRows)
        row['artistId'] as int: row['songCount'] as int,
    };

    return allArtists
        .map(
          (artist) => ArtistOverview(
            id: artist.id,
            name: artist.name,
            albums: albumsByArtist[artist.id] ?? const [],
            mixlists: mixlistsByArtist[artist.id] ?? const [],
            uniqueSongCount: songCountByArtist[artist.id] ?? 0,
          ),
        )
        .toList();
  }

  /// Every album with its artist's name attached, for the "browse all
  /// albums" screen -- one JOIN, no grouping needed since (unlike
  /// getArtistOverviews) each Album has exactly one Artist.
  ///
  /// Sorted by artist name then release date, so the flat grid still reads
  /// as "each artist's discography, oldest to newest" even with no section
  /// headers.
  Future<List<AlbumOverview>> getAlbumOverviews() async {
    final rows = await _db.rawQuery('''
      SELECT
        al.id            AS id,
        al.name          AS name,
        al.releaseDate   AS releaseDate,
        al.coverImageURL AS coverImageURL,
        ar.name          AS artistName
      FROM Albums al
      JOIN Artists ar ON ar.id = al.artist
      ORDER BY ar.name ASC, al.releaseDate ASC
    ''');

    return rows.map(AlbumOverview.fromMap).toList();
  }

  /// Every song of [artistId]'s that's featured in a mixlist, each with
  /// every mixlist it appears in -- the per-artist detail screen's version
  /// of `getArtistOverviews()`, joined one level further to the song.
  ///
  /// Rows come back ordered by `SongsMixlists.dateAdded` (when *this song*
  /// was added to *that* mixlist -- not the mixlist's own creation date),
  /// so both a song's `mixlists`/`datesAdded` lists end up chronological,
  /// and the returned list itself is sorted by each song's earliest
  /// `dateAdded`.
  Future<List<ArtistSongAppearance>> getArtistSongAppearances(
    int artistId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT DISTINCT
        s.id              AS songId,
        s.name            AS songName,
        al.name           AS albumName,
        al.coverImageURL  AS albumCoverImageURL,
        m.id              AS mixlistId,
        m.title           AS mixlistTitle,
        m.dateCreated     AS dateCreated,
        sm.dateAdded      AS dateAddedToMixlist
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE al.artist = ?
      ORDER BY sm.dateAdded ASC
    ''',
      [artistId],
    );

    final appearancesBySong = <int, ArtistSongAppearance>{};
    for (final row in rows) {
      final songId = row['songId'] as int;
      final mixlist = MixlistSummary(
        id: row['mixlistId'] as int,
        title: row['mixlistTitle'] as String,
        dateCreated: row['dateCreated'] as String,
      );
      final dateAdded = row['dateAddedToMixlist'] as String;
      final existing = appearancesBySong[songId];
      if (existing == null) {
        appearancesBySong[songId] = ArtistSongAppearance(
          songId: songId,
          songName: row['songName'] as String,
          albumName: row['albumName'] as String,
          albumCoverImageURL: row['albumCoverImageURL'] as String,
          mixlists: [mixlist],
          datesAdded: [dateAdded],
        );
      } else {
        existing.mixlists.add(mixlist);
        existing.datesAdded.add(dateAdded);
      }
    }
    return appearancesBySong.values.toList()
      ..sort((a, b) => a.datesAdded.first.compareTo(b.datesAdded.first));
  }

  /// Every song on [albumId]'s album, each with every mixlist it appears
  /// in -- the per-album detail screen's version of
  /// `getArtistSongAppearances()`, scoped to one album instead of every
  /// album by an artist. Every song is guaranteed at least one mixlist
  /// (that's how a song ends up in this library at all), so this is an
  /// inner JOIN throughout, same as `getArtistSongAppearances`.
  ///
  /// Ordered by the album's own track listing (`SongsExtraData.
  /// albumTrackNumber`, falling back to song id for anything missing one).
  Future<List<AlbumSongAppearance>> getAlbumSongAppearances(
    int albumId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        s.id                AS songId,
        s.name              AS songName,
        se.albumTrackNumber AS albumTrackNumber,
        m.id                AS mixlistId,
        m.title             AS mixlistTitle,
        m.dateCreated       AS dateCreated,
        sm.dateAdded        AS dateAddedToMixlist
      FROM Songs s
      LEFT JOIN SongsExtraData se ON se.song = s.id
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE s.album = ?
      ORDER BY se.albumTrackNumber ASC, s.id ASC, sm.dateAdded ASC
    ''',
      [albumId],
    );

    final appearancesBySong = <int, AlbumSongAppearance>{};
    final songOrder = <int>[];
    for (final row in rows) {
      final songId = row['songId'] as int;
      var appearance = appearancesBySong[songId];
      if (appearance == null) {
        appearance = AlbumSongAppearance(
          songId: songId,
          songName: row['songName'] as String,
          mixlists: [],
          datesAdded: [],
        );
        appearancesBySong[songId] = appearance;
        songOrder.add(songId);
      }
      appearance.mixlists.add(
        MixlistSummary(
          id: row['mixlistId'] as int,
          title: row['mixlistTitle'] as String,
          dateCreated: row['dateCreated'] as String,
        ),
      );
      appearance.datesAdded.add(row['dateAddedToMixlist'] as String);
    }
    return [for (final songId in songOrder) appearancesBySong[songId]!];
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
