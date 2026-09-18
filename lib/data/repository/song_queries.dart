part of 'music_library_repository.dart';

extension SongQueries on MusicLibraryRepository {
  /// Every song in the library, with its album, artist display text, and
  /// every mixlist it appears in -- scoped to [filter] when it isn't
  /// [MixlistFilter.all]. A song with zero qualifying appearances is
  /// dropped entirely (the inner joins through `SongsMixlists`/`Mixlists`
  /// naturally exclude it, same as [ArtistQueries.getArtistSongAppearances]).
  Future<List<SongOverview>> getSongOverviews({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');
    final rows = await _db.rawQuery('''
      SELECT
        s.id              AS songId,
        s.name            AS songName,
        s.artists         AS artistNames,
        al.name           AS albumName,
        al.coverImageURL  AS albumCoverImageURL,
        m.id              AS mixlistId,
        m.title           AS mixlistTitle,
        m.dateCreated     AS dateCreated
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      WHERE 1=1 $filterSql
      ORDER BY s.name ASC, m.dateCreated ASC
    ''');

    final songsById = <int, SongOverview>{};
    for (final row in rows) {
      final songId = row['songId'] as int;
      final mixlist = MixlistSummary(
        id: row['mixlistId'] as int,
        title: row['mixlistTitle'] as String,
        dateCreated: row['dateCreated'] as String,
      );
      final existing = songsById[songId];
      if (existing == null) {
        songsById[songId] = SongOverview(
          id: songId,
          name: row['songName'] as String,
          artistNames: row['artistNames'] as String,
          albumName: row['albumName'] as String,
          albumCoverImageURL: row['albumCoverImageURL'] as String?,
          mixlists: [mixlist],
        );
      } else {
        existing.mixlists.add(mixlist);
      }
    }
    return songsById.values.toList();
  }
}
