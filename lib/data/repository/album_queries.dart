part of 'music_library_repository.dart';

/// Album-centered queries.
extension AlbumQueries on MusicLibraryRepository {
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

  /// A single album, in the same shape as [getAlbumOverviews] returns, for
  /// navigating to an [AlbumOverview]-driven screen when only an id is on
  /// hand, like from a [MixlistTrack].
  Future<AlbumOverview?> getAlbumOverviewById(int albumId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        al.id            AS id,
        al.name          AS name,
        al.releaseDate   AS releaseDate,
        al.coverImageURL AS coverImageURL,
        ar.name          AS artistName
      FROM Albums al
      JOIN Artists ar ON ar.id = al.artist
      WHERE al.id = ?
    ''',
      [albumId],
    );
    if (rows.isEmpty) return null;
    return AlbumOverview.fromMap(rows.first);
  }
}
