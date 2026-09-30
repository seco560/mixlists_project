part of 'music_library_repository.dart';

extension ConnectionQueries on MusicLibraryRepository {
  /// Every (song artist, mixlist) appearance under [filter], as the "Six
  /// Degrees" graph. Uncached, like [getTasteTimeline].
  Future<ArtistConnectionGraph> getArtistConnectionGraph({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final mixlistsFuture = getAllMixlists(filter: filter);
    final rows = await _db.rawQuery('''
      SELECT
        sm.mixlist       AS mixlistId,
        ar.id            AS artistId,
        ar.name          AS artistName,
        s.id             AS songId,
        s.name           AS songName,
        al.coverImageURL AS coverImageURL
      FROM SongsMixlists sm
      JOIN Mixlists m ON m.id = sm.mixlist
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      JOIN Artists ar ON ar.id = $_songArtistSql
      WHERE 1 = 1 ${_mixlistFilterSql(filter, 'm')}
      ORDER BY m.id, sm.positionIndex
    ''');
    return ArtistConnectionGraph.fromAppearances(
      mixlists: await mixlistsFuture,
      appearances: [
        for (final row in rows)
          ConnectionAppearance(
            mixlistId: row['mixlistId'] as int,
            artistId: row['artistId'] as int,
            artistName: row['artistName'] as String,
            songId: row['songId'] as int,
            songName: row['songName'] as String,
            coverImageURL: row['coverImageURL'] as String?,
          ),
      ],
    );
  }
}
