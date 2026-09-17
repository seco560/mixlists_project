part of 'music_library_repository.dart';

extension ArtistQueries on MusicLibraryRepository {
  /// Every artist, with their albums, every mixlist their songs appear
  /// in, and their distinct song count across all mixlists.
  Future<List<ArtistOverview>> getArtistOverviews() async {
    final artistRows = await _db.query('Artists', orderBy: 'name ASC');
    final allArtists = artistRows.map(Artist.fromMap).toList();

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
              coverImageURL: row['coverImageURL'] as String?,
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
      SELECT
        al.artist              AS artistId,
        COUNT(DISTINCT s.id)   AS songCount,
        COUNT(*)               AS appearanceCount
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      GROUP BY al.artist
    ''');
    final songCountByArtist = <int, int>{
      for (final row in songCountRows)
        row['artistId'] as int: row['songCount'] as int,
    };
    final appearanceCountByArtist = <int, int>{
      for (final row in songCountRows)
        row['artistId'] as int: row['appearanceCount'] as int,
    };

    return allArtists
        .map(
          (artist) => ArtistOverview(
            id: artist.id,
            name: artist.name,
            albums: albumsByArtist[artist.id] ?? const [],
            mixlists: mixlistsByArtist[artist.id] ?? const [],
            uniqueSongCount: songCountByArtist[artist.id] ?? 0,
            appearanceCount: appearanceCountByArtist[artist.id] ?? 0,
          ),
        )
        .toList();
  }

  /// Every song of [artistId]'s featured in a mixlist, each with every
  /// mixlist it appears in, ordered by `SongsMixlists.dateAdded` (per-song
  /// add date, not the mixlist's creation date).
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
          albumCoverImageURL: row['albumCoverImageURL'] as String?,
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

  /// A single artist in the same shape [getArtistOverviews] returns, via
  /// scoped queries so this stays cheap regardless of library size.
  Future<ArtistOverview?> getArtistOverviewById(int artistId) async {
    final artistRows = await _db.query(
      'Artists',
      where: 'id = ?',
      whereArgs: [artistId],
      limit: 1,
    );
    if (artistRows.isEmpty) return null;
    final artist = Artist.fromMap(artistRows.first);

    final albumRows = await _db.rawQuery(
      '''
      SELECT id AS albumId, name AS albumName, releaseDate, coverImageURL
      FROM Albums
      WHERE artist = ?
      ORDER BY releaseDate ASC
    ''',
      [artistId],
    );
    final albums = [
      for (final row in albumRows)
        AlbumSummary(
          id: row['albumId'] as int,
          name: row['albumName'] as String,
          releaseDate: row['releaseDate'] as String,
          coverImageURL: row['coverImageURL'] as String?,
        ),
    ];

    final mixlistRows = await _db.rawQuery(
      '''
      SELECT DISTINCT
        m.id          AS mixlistId,
        m.title       AS mixlistTitle,
        m.dateCreated AS dateCreated
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE al.artist = ?
      ORDER BY m.dateCreated ASC
    ''',
      [artistId],
    );
    final mixlists = [
      for (final row in mixlistRows)
        MixlistSummary(
          id: row['mixlistId'] as int,
          title: row['mixlistTitle'] as String,
          dateCreated: row['dateCreated'] as String,
        ),
    ];

    final songCountRows = await _db.rawQuery(
      '''
      SELECT COUNT(DISTINCT s.id) AS songCount, COUNT(*) AS appearanceCount
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      WHERE al.artist = ?
    ''',
      [artistId],
    );

    return ArtistOverview(
      id: artist.id,
      name: artist.name,
      albums: albums,
      mixlists: mixlists,
      uniqueSongCount: songCountRows.first['songCount'] as int,
      appearanceCount: songCountRows.first['appearanceCount'] as int,
    );
  }

  /// Scoped counterpart of [getArtistOverviews] restricted to a known set
  /// of artists via `WHERE artist IN (...)`. Used by `SearchQueries`.
  Future<List<ArtistOverview>> _artistOverviewsFor(
    List<Artist> matched,
  ) async {
    if (matched.isEmpty) return [];
    final ids = matched.map((a) => a.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    final albumRows = await _db.rawQuery('''
      SELECT
        artist         AS artistId,
        id             AS albumId,
        name           AS albumName,
        releaseDate,
        coverImageURL
      FROM Albums
      WHERE artist IN ($placeholders)
      ORDER BY releaseDate ASC
    ''', ids);
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
              coverImageURL: row['coverImageURL'] as String?,
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
      WHERE al.artist IN ($placeholders)
      ORDER BY m.dateCreated ASC
    ''', ids);
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
      SELECT
        al.artist              AS artistId,
        COUNT(DISTINCT s.id)   AS songCount,
        COUNT(*)               AS appearanceCount
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      WHERE al.artist IN ($placeholders)
      GROUP BY al.artist
    ''', ids);
    final songCountByArtist = <int, int>{
      for (final row in songCountRows)
        row['artistId'] as int: row['songCount'] as int,
    };
    final appearanceCountByArtist = <int, int>{
      for (final row in songCountRows)
        row['artistId'] as int: row['appearanceCount'] as int,
    };

    return matched
        .map(
          (artist) => ArtistOverview(
            id: artist.id,
            name: artist.name,
            albums: albumsByArtist[artist.id] ?? const [],
            mixlists: mixlistsByArtist[artist.id] ?? const [],
            uniqueSongCount: songCountByArtist[artist.id] ?? 0,
            appearanceCount: appearanceCountByArtist[artist.id] ?? 0,
          ),
        )
        .toList();
  }
}
