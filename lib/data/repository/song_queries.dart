part of 'music_library_repository.dart';

extension SongQueries on MusicLibraryRepository {
  /// Every song with album, artist text and mixlists, scoped to [filter];
  /// songs with no qualifying appearance are dropped by the inner joins.
  Future<List<SongOverview>> getSongOverviews({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');
    final rows = await _db.rawQuery('''
      SELECT
        s.id              AS songId,
        s.name            AS songName,
        s.artists         AS artistNames,
        al.id             AS albumID,
        al.name           AS albumName,
        al.coverImageURL  AS albumCoverImageURL,
        ed.explicit       AS explicit,
        m.id              AS mixlistId,
        m.title           AS mixlistTitle,
        m.dateCreated     AS dateCreated
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      WHERE 1=1 $filterSql
      ORDER BY s.name ASC, m.dateCreated ASC
    ''');

    return _groupSongOverviewRows(rows);
  }

  /// A single song, by id -- same shape/grouping as [getSongOverviews],
  /// scoped to one `Songs.id`. `null` when [songId] has zero qualifying
  /// appearances under [filter] (or doesn't exist).
  Future<SongOverview?> getSongOverviewById(
    int songId, {
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final filterSql = _mixlistFilterSql(filter, 'm');
    final rows = await _db.rawQuery(
      '''
      SELECT
        s.id              AS songId,
        s.name            AS songName,
        s.artists         AS artistNames,
        al.id             AS albumID,
        al.name           AS albumName,
        al.coverImageURL  AS albumCoverImageURL,
        ed.explicit       AS explicit,
        m.id              AS mixlistId,
        m.title           AS mixlistTitle,
        m.dateCreated     AS dateCreated
      FROM Songs s
      JOIN Albums al ON al.id = s.album
      JOIN SongsMixlists sm ON sm.song = s.id
      JOIN Mixlists m ON m.id = sm.mixlist
      LEFT JOIN SongsExtraData ed ON ed.song = s.id
      WHERE s.id = ? $filterSql
      ORDER BY m.dateCreated ASC
    ''',
      [songId],
    );

    final grouped = _groupSongOverviewRows(rows);
    return grouped.isEmpty ? null : grouped.first;
  }

  List<SongOverview> _groupSongOverviewRows(List<Map<String, Object?>> rows) {
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
          albumID: row['albumID'] as int,
          albumName: row['albumName'] as String,
          albumCoverImageURL: row['albumCoverImageURL'] as String?,
          mixlists: [mixlist],
          isExplicit: _parseExplicit(row['explicit'] as String?),
        );
      } else {
        existing.mixlists.add(mixlist);
      }
    }
    return songsById.values.toList();
  }
}
