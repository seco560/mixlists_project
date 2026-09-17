import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/widgets/mixlist_audio_feature_chart.dart';

MixlistTrack _track({
  required int position,
  required String name,
  double? danceability,
  double? tempo,
  double? loudness,
}) {
  return MixlistTrack(
    position: position,
    dateAdded: '2018-01-01T00:00:00Z',
    songId: position,
    songSpotifyURI: 'spotify:track:$position',
    songName: name,
    artistNames: 'Some Artist',
    artistURIs: null,
    artistId: 1,
    albumId: 1,
    albumName: 'Some Album',
    albumCoverImageURL: null,
    albumReleaseDate: '2018',
    durationMs: 200000,
    isExplicit: false,
    popularity: 50,
    danceability: danceability,
    tempo: tempo,
    loudness: loudness,
  );
}

void main() {
  testWidgets(
    'renders bars for tracks with data and a no-data marker for tracks without',
    (tester) async {
      final tracks = [
        _track(
          position: 1,
          name: 'Track One',
          danceability: 0.8,
          tempo: 120,
          loudness: -5.0,
        ),
        _track(
          position: 2,
          name: 'Track Two',
          danceability: 0.3,
          tempo: 140,
          loudness: -8.5,
        ),
        _track(
          position: 3,
          name: 'Track Three',
        ), // no audio-feature data at all
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MixlistAudioFeatureChart(tracks: tracks)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MixlistAudioFeatureChart), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets('switching the dropdown to another field does not throw', (
    tester,
  ) async {
    final tracks = [
      _track(
        position: 1,
        name: 'Track One',
        danceability: 0.8,
        tempo: 120,
        loudness: -5.0,
      ),
      _track(
        position: 2,
        name: 'Track Two',
        danceability: 0.3,
        tempo: 140,
        loudness: -8.5,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MixlistAudioFeatureChart(tracks: tracks)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<AudioFeatureField>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loudness').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sorting ascending/descending does not throw with mixed null values',
    (tester) async {
      final tracks = [
        _track(position: 1, name: 'Track One', danceability: 0.8),
        _track(position: 2, name: 'Track Two'), // null danceability
        _track(position: 3, name: 'Track Three', danceability: 0.3),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MixlistAudioFeatureChart(tracks: tracks)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Low → High'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('High → Low'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows a message instead of a chart when no track has data', (
    tester,
  ) async {
    final tracks = [
      _track(position: 1, name: 'Track One'),
      _track(position: 2, name: 'Track Two'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MixlistAudioFeatureChart(tracks: tracks)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No audio feature data for this mixlist yet.'),
      findsOneWidget,
    );
  });

  testWidgets('empty track list renders nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MixlistAudioFeatureChart(tracks: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
