part of 'music_library_repository.dart';

/// Library-wide search.
extension SearchQueries on MusicLibraryRepository {
  /// Every match across the library for [rawQuery], grouped by entity
  /// type in the order the Search Results screen renders them. A bare
  /// 4-digit query (e.g. "1975") additionally matches Albums by release
  /// year, on top of (not instead of) the normal name search -- see
  /// [_searchAlbums].
  Future<SearchResults> searchLibrary(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const SearchResults(
        mixlists: [],
        artists: [],
        albums: [],
        songs: [],
      );
    }

    final likePattern = '%$query%';
    final isYearQuery = RegExp(r'^\d{4}$').hasMatch(query);

    final mixlistsFuture = _searchMixlists(likePattern);
    final artistsFuture = _searchArtists(likePattern);
    final albumsFuture = _searchAlbums(
      query,
      likePattern,
      isYearQuery: isYearQuery,
    );
    final songsFuture = _searchSongs(likePattern);

    return SearchResults(
      mixlists: await mixlistsFuture,
      artists: await artistsFuture,
      albums: await albumsFuture,
      songs: await songsFuture,
    );
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

  /// Albums matching [query] by name, and (only when [isYearQuery]) also
  /// by release year. `releaseDate` is inconsistently formatted (bare
  /// "2013" vs. full "2017-08-25"), so year matching uses a prefix LIKE
  /// ('YYYY%') rather than `=` or a `substr()` that assumes one format.
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
        m.id             AS mixlistId,
        m.title          AS mixlistTitle,
        m.dateCreated    AS dateCreated
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
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
          albumCoverImageURL: row['albumCoverImageURL'] as String,
          artistNames: row['artistNames'] as String,
          mixlists: [],
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
