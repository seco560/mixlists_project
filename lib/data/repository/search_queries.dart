part of 'music_library_repository.dart';

extension SearchQueries on MusicLibraryRepository {
  /// Every match across the library for [rawQuery], grouped by entity
  /// type in the order the Search Results screen renders them. A bare
  /// 4-digit query (e.g. "1975") additionally matches Albums by release year
  Future<SearchResults> searchLibrary(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const SearchResults(
        mixlists: [],
        artists: [],
        genres: [],
        albums: [],
        labels: [],
        songs: [],
      );
    }

    final likePattern = '%$query%';
    final isYearQuery = RegExp(r'^\d{4}$').hasMatch(query);

    final mixlistsFuture = _searchMixlists(likePattern);
    final artistsFuture = _searchArtists(likePattern);
    final genresFuture = _searchGenres(query);
    final albumsFuture = _searchAlbums(
      query,
      likePattern,
      isYearQuery: isYearQuery,
    );
    final labelsFuture = _searchLabels(query);
    final songsFuture = _searchSongs(likePattern);

    return SearchResults(
      mixlists: await mixlistsFuture,
      artists: await artistsFuture,
      genres: await genresFuture,
      albums: await albumsFuture,
      labels: await labelsFuture,
      songs: await songsFuture,
    );
  }

  /// Every distinct genre containing [query] (case-insensitive), from the
  /// cached distinct-genre index -- see [ArtistQueries._allGenres].
  Future<List<String>> _searchGenres(String query) async {
    final lowerQuery = query.toLowerCase();
    final allGenres = await _allGenres;
    return allGenres
        .where((g) => g.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Every distinct record label containing [query] (case-insensitive),
  /// from the cached distinct-label index -- see [AlbumQueries._allLabels].
  Future<List<String>> _searchLabels(String query) async {
    final lowerQuery = query.toLowerCase();
    final allLabels = await _allLabels;
    return allLabels
        .where((l) => l.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<List<Mixlist>> _searchMixlists(String likePattern) async {
    final rows = await _db.rawQuery(
      '''
      SELECT id, title, description, dateCreated
      FROM Mixlists
      WHERE title LIKE ?
      ORDER BY title ASC
    ''',
      [likePattern],
    );
    return rows.map(Mixlist.fromMap).toList();
  }

  Future<List<ArtistOverview>> _searchArtists(String likePattern) async {
    final rows = await _db.rawQuery(
      'SELECT id, spotifyURI, name FROM Artists WHERE name LIKE ? ORDER BY name ASC',
      [likePattern],
    );
    return _artistOverviewsFor(rows.map(Artist.fromMap).toList());
  }

  Future<List<AlbumOverview>> _searchAlbums(
    String query,
    String likePattern, {
    required bool isYearQuery,
  }) async {
    final whereClause = isYearQuery
        ? 'al.name LIKE ? OR al.releaseDate LIKE ?'
        : 'al.name LIKE ?';
    final args = isYearQuery ? [likePattern, '$query%'] : [likePattern];

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
      WHERE $whereClause
      ORDER BY ar.name ASC, al.releaseDate ASC
    ''', args);

    return rows.map(AlbumOverview.fromMap).toList();
  }

  Future<List<SongSearchResult>> _searchSongs(String likePattern) async {
    final rows = await _db.rawQuery(
      '''
      SELECT DISTINCT
        s.id             AS songId,
        s.name           AS songName,
        s.artists        AS artistNames,
        al.name          AS albumName,
        al.coverImageURL AS albumCoverImageURL,
        ed.explicit      AS explicit,
        m.id             AS mixlistId,
        m.title          AS mixlistTitle,
        m.dateCreated    AS dateCreated
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      WHERE s.name LIKE ?
      ORDER BY s.name ASC, m.dateCreated ASC
    ''',
      [likePattern],
    );

    final resultsBySong = <int, SongSearchResult>{};
    final songOrder = <int>[];
    for (final row in rows) {
      final songId = row['songId'] as int;
      var result = resultsBySong[songId];
      if (result == null) {
        result = SongSearchResult(
          songId: songId,
          songName: row['songName'] as String,
          albumName: row['albumName'] as String,
          albumCoverImageURL: row['albumCoverImageURL'] as String?,
          artistNames: row['artistNames'] as String,
          mixlists: [],
          isExplicit: _parseExplicit(row['explicit'] as String?),
        );
        resultsBySong[songId] = result;
        songOrder.add(songId);
      }
      result.mixlists.add(
        MixlistSummary(
          id: row['mixlistId'] as int,
          title: row['mixlistTitle'] as String,
          dateCreated: row['dateCreated'] as String,
        ),
      );
    }
    return [for (final id in songOrder) resultsBySong[id]!];
  }
}
