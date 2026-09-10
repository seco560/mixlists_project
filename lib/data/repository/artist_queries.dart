part of 'music_library_repository.dart';

/// Artist-centered queries, including the plain `Artists` table reads that
/// used to live on `ArtistDao.getAll()`/`getById()` (folded in here since
/// those were actually called from within this repository, unlike every
/// other DAO method).
extension ArtistQueries on MusicLibraryRepository {
  /// Every artist, with the albums they released (Albums.artist), every
  /// mixlist a song off one of those albums appears in
  /// (Albums -> Songs -> SongsMixlists -> Mixlists), and how many
  /// distinct songs of theirs show up across all mixlists.
  ///
  /// Deliberately flat queries grouped in Dart rather than one query
  /// joining everything: an artist with N albums and M mixlist
  /// appearances would otherwise come back as N*M rows that need
  /// collapsing anyway, or a GROUP_CONCAT-and-reparse hack. Same
  /// flat-rows-into-a-map shape as `duplicateSongIndex` in
  /// mixlist_queries.dart.
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

  /// A single artist, in the same shape as [getArtistOverviews] returns,
  /// for navigating to an [ArtistOverview]-driven screen (e.g. the artist
  /// detail screen) when only an id is on hand, like from a [MixlistTrack].
  /// Scoped queries rather than reusing [getArtistOverviews] and filtering,
  /// so this stays cheap regardless of library size.
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
          coverImageURL: row['coverImageURL'] as String,
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
      SELECT COUNT(DISTINCT s.id) AS songCount
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
    );
  }

  /// Builds full [ArtistOverview]s for an already-known set of artists --
  /// the scoped counterpart of the three grouping queries inside
  /// [getArtistOverviews], restricted by `WHERE artist IN (...)` instead
  /// of running unscoped over the whole library. Used by `SearchQueries`
  /// in search_queries.dart.
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
      SELECT al.artist AS artistId, COUNT(DISTINCT s.id) AS songCount
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

    return matched
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
}
