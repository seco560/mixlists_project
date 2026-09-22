part of 'music_library_repository.dart';

extension SearchQueries on MusicLibraryRepository {
  /// Every match for [rawQuery], grouped by type in render order; a bare
  /// 4-digit query also matches album release years. Unfiltered: the result
  /// carries a [MixlistScopeIndex] for in-memory [SearchResults.scopedTo].
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
        scopeIndex: MixlistScopeIndex.empty(),
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
    final scopeIndexFuture = _mixlistScopeIndex;

    return SearchResults(
      mixlists: await mixlistsFuture,
      artists: await artistsFuture,
      genres: await genresFuture,
      albums: await albumsFuture,
      labels: await labelsFuture,
      songs: await songsFuture,
      scopeIndex: await scopeIndexFuture,
    );
  }

  /// Cached indefinitely; invalidated on library switch and [setMixlistFlags].
  Future<MixlistScopeIndex> get _mixlistScopeIndex {
    return _mixlistScopeIndexFuture ??= _loadMixlistScopeIndex();
  }

  Future<MixlistScopeIndex> _loadMixlistScopeIndex() async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT
        al.artist      AS artistId,
        al.id          AS albumId,
        al.recordLabel AS recordLabel,
        ar.genres      AS genres,
        m.is_mixlists  AS isMixlist
      FROM SongsMixlists sm
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      JOIN Artists ar ON ar.id = al.artist
      JOIN Mixlists m ON m.id = sm.mixlist
    ''');

    final mixlistArtistIds = <int>{};
    final playlistArtistIds = <int>{};
    final mixlistAlbumIds = <int>{};
    final playlistAlbumIds = <int>{};
    final mixlistGenres = <String>{};
    final playlistGenres = <String>{};
    final mixlistLabels = <String>{};
    final playlistLabels = <String>{};

    for (final row in rows) {
      final isMixlist = (row['isMixlist'] as int?) == 1;
      final artistIds = isMixlist ? mixlistArtistIds : playlistArtistIds;
      final albumIds = isMixlist ? mixlistAlbumIds : playlistAlbumIds;
      final genreSet = isMixlist ? mixlistGenres : playlistGenres;
      final labelSet = isMixlist ? mixlistLabels : playlistLabels;

      artistIds.add(row['artistId'] as int);
      albumIds.add(row['albumId'] as int);
      genreSet.addAll(_parseGenres(row['genres'] as String?));
      final label = row['recordLabel'] as String?;
      if (label != null) labelSet.add(label);
    }

    return MixlistScopeIndex(
      mixlistArtistIds: mixlistArtistIds,
      playlistArtistIds: playlistArtistIds,
      mixlistAlbumIds: mixlistAlbumIds,
      playlistAlbumIds: playlistAlbumIds,
      mixlistGenres: mixlistGenres,
      playlistGenres: playlistGenres,
      mixlistLabels: mixlistLabels,
      playlistLabels: playlistLabels,
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
      SELECT id, title, description, dateCreated, is_mixlists
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
        m.dateCreated    AS dateCreated,
        m.is_mixlists    AS mixlistIsMixlist
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
          isMixlist: (row['mixlistIsMixlist'] as int?) == 1,
        ),
      );
    }
    return [for (final id in songOrder) resultsBySong[id]!];
  }
}
