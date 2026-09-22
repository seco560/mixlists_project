part of 'music_library_repository.dart';

/// Splits `Artists.genres` (a comma-joined string, e.g.
/// `"funk rock,alternative rock,rock"`) into trimmed, non-empty tokens.
/// `null`/empty input yields an empty list.
List<String> _parseGenres(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(',')
      .map((g) => g.trim())
      .where((g) => g.isNotEmpty)
      .toList();
}

extension ArtistQueries on MusicLibraryRepository {
  /// Every artist with albums, mixlists and distinct song count, scoped to
  /// [filter]: artists with no qualifying appearance are dropped, and
  /// `albums` only lists albums with a qualifying song.
  Future<List<ArtistOverview>> getArtistOverviews({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');

    final artistRows = await _db.query('Artists', orderBy: 'name ASC');
    final allArtists = artistRows.map(Artist.fromMap).toList();

    final albumRows = await _db.rawQuery('''
      SELECT
        artist         AS artistId,
        id             AS albumId,
        name           AS albumName,
        releaseDate,
        coverImageURL,
        recordLabel
      FROM Albums
      ORDER BY releaseDate ASC
    ''');

    Set<int>? qualifyingAlbumIds;
    if (filter != MixlistFilter.all) {
      final rows = await _db.rawQuery('''
        SELECT DISTINCT al.id AS albumId
        FROM Albums al
        JOIN Songs s ON s.album = al.id
        JOIN SongsMixlists sm ON sm.song = s.id
        JOIN Mixlists m ON m.id = sm.mixlist
        WHERE 1=1 $filterSql
      ''');
      qualifyingAlbumIds = {for (final row in rows) row['albumId'] as int};
    }

    final albumsByArtist = <int, List<AlbumSummary>>{};
    for (final row in albumRows) {
      final albumId = row['albumId'] as int;
      if (qualifyingAlbumIds != null && !qualifyingAlbumIds.contains(albumId)) {
        continue;
      }
      final artistId = row['artistId'] as int;
      albumsByArtist
          .putIfAbsent(artistId, () => [])
          .add(
            AlbumSummary(
              id: albumId,
              name: row['albumName'] as String,
              releaseDate: row['releaseDate'] as String,
              coverImageURL: row['coverImageURL'] as String?,
              recordLabel: row['recordLabel'] as String?,
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
      WHERE 1=1 $filterSql
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
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE 1=1 $filterSql
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

    final artistsToShow = filter == MixlistFilter.all
        ? allArtists
        : allArtists.where((a) => (songCountByArtist[a.id] ?? 0) > 0).toList();

    return artistsToShow
        .map(
          (artist) => ArtistOverview(
            id: artist.id,
            name: artist.name,
            albums: albumsByArtist[artist.id] ?? const [],
            mixlists: mixlistsByArtist[artist.id] ?? const [],
            uniqueSongCount: songCountByArtist[artist.id] ?? 0,
            appearanceCount: appearanceCountByArtist[artist.id] ?? 0,
            genres: _parseGenres(artist.genres),
          ),
        )
        .toList();
  }

  /// [artistId]'s songs with their mixlists, ordered by per-song
  /// `SongsMixlists.dateAdded`. Songs with no qualifying appearance under
  /// [filter] are dropped.
  Future<List<ArtistSongAppearance>> getArtistSongAppearances(
    int artistId, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');
    final rows = await _db.rawQuery(
      '''
      SELECT DISTINCT
        s.id              AS songId,
        s.name            AS songName,
        al.name           AS albumName,
        al.coverImageURL  AS albumCoverImageURL,
        ed.explicit       AS explicit,
        m.id              AS mixlistId,
        m.title           AS mixlistTitle,
        m.dateCreated     AS dateCreated,
        sm.dateAdded      AS dateAddedToMixlist
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      WHERE al.artist = ? $filterSql
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
          isExplicit: _parseExplicit(row['explicit'] as String?),
        );
      } else {
        existing.mixlists.add(mixlist);
        existing.datesAdded.add(dateAdded);
      }
    }
    return appearancesBySong.values.toList()
      ..sort((a, b) => a.datesAdded.first.compareTo(b.datesAdded.first));
  }

  /// One artist in [getArtistOverviews]' shape via scoped queries. Always
  /// returns the artist even if [filter] excludes all its appearances:
  /// filtering thins the contents, it never hides a selected artist.
  Future<ArtistOverview?> getArtistOverviewById(
    int artistId, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');
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
      SELECT id AS albumId, name AS albumName, releaseDate, coverImageURL, recordLabel
      FROM Albums
      WHERE artist = ?
      ORDER BY releaseDate ASC
    ''',
      [artistId],
    );

    Set<int>? qualifyingAlbumIds;
    if (filter != MixlistFilter.all) {
      final rows = await _db.rawQuery(
        '''
        SELECT DISTINCT al.id AS albumId
        FROM Albums al
        JOIN Songs s ON s.album = al.id
        JOIN SongsMixlists sm ON sm.song = s.id
        JOIN Mixlists m ON m.id = sm.mixlist
        WHERE al.artist = ? $filterSql
      ''',
        [artistId],
      );
      qualifyingAlbumIds = {for (final row in rows) row['albumId'] as int};
    }

    final albums = [
      for (final row in albumRows)
        if (qualifyingAlbumIds == null ||
            qualifyingAlbumIds.contains(row['albumId'] as int))
          AlbumSummary(
            id: row['albumId'] as int,
            name: row['albumName'] as String,
            releaseDate: row['releaseDate'] as String,
            coverImageURL: row['coverImageURL'] as String?,
            recordLabel: row['recordLabel'] as String?,
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
      WHERE al.artist = ? $filterSql
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
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE al.artist = ? $filterSql
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
      genres: _parseGenres(artist.genres),
    );
  }

  /// [getArtistOverviews] restricted to [matched], for `SearchQueries`. The
  /// contents are always unfiltered; `SearchResults.scopedTo` only keeps or
  /// drops whole artists.
  Future<List<ArtistOverview>> _artistOverviewsFor(List<Artist> matched) async {
    if (matched.isEmpty) return [];
    final ids = matched.map((a) => a.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    final albumRows = await _db.rawQuery('''
      SELECT
        artist         AS artistId,
        id             AS albumId,
        name           AS albumName,
        releaseDate,
        coverImageURL,
        recordLabel
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
              recordLabel: row['recordLabel'] as String?,
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
            genres: _parseGenres(artist.genres),
          ),
        )
        .toList();
  }

  /// Every distinct genre token across all artists, sorted -- cached
  /// indefinitely since this is a read-only app with no genre write path.
  Future<List<String>> get _allGenres {
    return _allGenresFuture ??= _loadAllGenres();
  }

  Future<List<String>> _loadAllGenres() async {
    final rows = await _db.rawQuery(
      "SELECT genres FROM Artists WHERE genres IS NOT NULL AND genres != ''",
    );
    final genres = <String>{};
    for (final row in rows) {
      genres.addAll(_parseGenres(row['genres'] as String?));
    }
    return genres.toList()..sort();
  }

  /// The genre alphabetically before/after [genre] in the full distinct
  /// genre index -- null at either end, same shape as
  /// [MixlistQueries.getAdjacentMixlists].
  Future<(String? previous, String? next)> getAdjacentGenres(
    String genre,
  ) async {
    final genres = await _allGenres;
    final index = genres.indexOf(genre);
    if (index == -1) return (null, null);
    return (
      index == 0 ? null : genres[index - 1],
      index == genres.length - 1 ? null : genres[index + 1],
    );
  }
}
