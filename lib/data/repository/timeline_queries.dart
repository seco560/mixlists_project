part of 'music_library_repository.dart';

const _timelineFeatureColumns = {
  AudioFeatureField.danceability: 'danceability',
  AudioFeatureField.energy: 'energy',
  AudioFeatureField.valence: 'valence',
  AudioFeatureField.acousticness: 'acousticness',
  AudioFeatureField.instrumentalness: 'instrumentalness',
  AudioFeatureField.liveness: 'liveness',
  AudioFeatureField.speechiness: 'speechiness',
  AudioFeatureField.loudness: 'loudness',
  AudioFeatureField.tempo: 'tempo',
};

extension TimelineQueries on MusicLibraryRepository {
  /// Every appearance under [filter], aggregated into [TasteTimeline].
  /// Uncached: only the timeline screen asks, once per open/filter change.
  Future<TasteTimeline> getTasteTimeline({
    MixlistFilter filter = MixlistFilter.all,
  }) async {
    final mixlistsFuture = getAllMixlists(filter: filter);
    final featureSelect = _timelineFeatureColumns.values
        .map((c) => 'af.$c AS $c')
        .join(', ');
    final rows = await _db.rawQuery('''
      SELECT
        sm.mixlist     AS mixlistId,
        sm.dateAdded   AS dateAdded,
        s.id           AS songId,
        al.releaseDate AS releaseDate,
        ar.id          AS artistId,
        ar.name        AS artistName,
        ar.genres      AS genres,
        $featureSelect
      FROM SongsMixlists sm
      JOIN Mixlists m ON m.id = sm.mixlist
      JOIN Songs s ON s.id = sm.song
      JOIN Albums al ON al.id = s.album
      LEFT JOIN Artists ar ON ar.id = al.artist
      LEFT JOIN SongsAudioFeatures af ON af.song = s.id
      WHERE 1 = 1 ${_mixlistFilterSql(filter, 'm')}
      ORDER BY m.id, sm.positionIndex
    ''');

    final appearances = [
      for (final row in rows)
        TimelineAppearance(
          mixlistId: row['mixlistId'] as int,
          songId: row['songId'] as int,
          artistId: row['artistId'] as int?,
          artistName: row['artistName'] as String?,
          genres: _parseGenres(row['genres'] as String?),
          releaseDate: row['releaseDate'] as String?,
          dateAdded: row['dateAdded'] as String?,
          features: {
            for (final entry in _timelineFeatureColumns.entries)
              if (row[entry.value] != null)
                entry.key: (row[entry.value] as num).toDouble(),
          },
        ),
    ];

    return TasteTimeline.fromAppearances(
      mixlists: await mixlistsFuture,
      appearances: appearances,
    );
  }
}
