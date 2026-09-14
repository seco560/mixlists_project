part of 'music_library_repository.dart';

extension AlbumQueries on MusicLibraryRepository {
  Future<List<AlbumOverview>> getAlbumOverviews() async {
    final rows = await _db.rawQuery('''
      SELECT
        al.id            AS id,
        al.name          AS name,
        al.releaseDate   AS releaseDate,
        al.coverImageURL AS coverImageURL,
        ar.id            AS artistId,
        ar.name          AS artistName
      FROM Albums al
      JOIN Artists ar ON ar.id = al.artist
      ORDER BY ar.name ASC, al.releaseDate ASC
    ''');

    return rows.map(AlbumOverview.fromMap).toList();
  }


  Future<AlbumOverview?> getAlbumOverviewById(int albumId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        al.id            AS id,
        al.name          AS name,
        al.releaseDate   AS releaseDate,
        al.coverImageURL AS coverImageURL,
        ar.id            AS artistId,
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
          albumTrackNumber: row['albumTrackNumber'] as int,
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
}
