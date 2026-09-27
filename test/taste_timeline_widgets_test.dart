import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/models/audio_feature_field.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/timeline/artist_lifespan_list.dart';
import 'package:mixlists_project/widgets/timeline/artist_timeline_strip.dart';
import 'package:mixlists_project/widgets/timeline/feature_trend_chart.dart';
import 'package:mixlists_project/widgets/timeline/genre_drift_chart.dart';
import 'package:mixlists_project/widgets/timeline/music_age_chart.dart';

TasteTimeline _timeline({int mixlistCount = 40, bool withFeatures = true}) {
  return TasteTimeline.fromAppearances(
    mixlists: [
      for (var i = 1; i <= mixlistCount; i++)
        Mixlist(
          id: i,
          title: 'Mixlist $i',
          description: '',
          dateCreated: '${2017 + i ~/ 6}-01-01T00:00:00Z',
        ),
    ],
    appearances: [
      for (var i = 1; i <= mixlistCount; i++)
        for (var t = 0; t < 3; t++)
          TimelineAppearance(
            mixlistId: i,
            songId: i * 10 + t,
            artistId: t,
            artistName: 'Artist $t',
            genres: t == 0 ? ['shoegaze', 'dream pop'] : ['ambient'],
            releaseDate: '${2000 + t}',
            dateAdded: '${2017 + i ~/ 6}-06-01T00:00:00Z',
            features: withFeatures
                ? {
                    AudioFeatureField.energy: (i % 10) / 10,
                    AudioFeatureField.tempo: 100.0 + i,
                  }
                : const {},
          ),
    ],
  );
}

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  testWidgets('feature trend only offers continuous fields', (tester) async {
    final timeline = _timeline();
    await tester.pumpWidget(_wrap(FeatureTrendChart(points: timeline.points)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<AudioFeatureField>));
    await tester.pumpAndSettle();
    expect(find.text('Tempo'), findsWidgets);
    expect(find.text('Key'), findsNothing);
    expect(find.text('Mode'), findsNothing);
    expect(find.text('Time Signature'), findsNothing);

    await tester.tap(find.text('Tempo').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('feature trend shows a message without audio features', (
    tester,
  ) async {
    final timeline = _timeline(withFeatures: false);
    await tester.pumpWidget(_wrap(FeatureTrendChart(points: timeline.points)));
    await tester.pumpAndSettle();
    expect(
      find.text('No audio feature data for these mixlists.'),
      findsOneWidget,
    );
  });

  testWidgets('genre drift, music age and lifespans build', (tester) async {
    final timeline = _timeline();
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            GenreDriftChart(
              points: timeline.points,
              bands: timeline.genreBands,
              windows: timeline.genreWindows,
            ),
            MusicAgeChart(
              points: timeline.points,
              overallMedianYears: timeline.overallMedianMusicAgeYears,
            ),
            ArtistLifespanList(
              points: timeline.points,
              lifespans: timeline.artistLifespans,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ambient'), findsOneWidget); // heatmap row
    expect(find.text('Artist 0'), findsOneWidget);

    await tester.tap(find.text('Most frequent'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('genre heatmap expands a family into its genres', (
    tester,
  ) async {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [
        for (var i = 1; i <= 6; i++)
          Mixlist(
            id: i,
            title: 'Mixlist $i',
            description: '',
            dateCreated: '2020-01-0${i}T00:00:00Z',
          ),
      ],
      appearances: [
        for (var i = 1; i <= 6; i++)
          for (final (t, genre) in [
            (0, 'indie rock'),
            (1, 'garage rock'),
            (2, 'ambient'),
          ])
            TimelineAppearance(
              mixlistId: i,
              songId: i * 10 + t,
              artistId: t,
              genres: [genre],
            ),
      ],
    );
    await tester.pumpWidget(
      _wrap(
        GenreDriftChart(
          points: timeline.points,
          bands: timeline.genreBands,
          windows: timeline.genreWindows,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('rock'), findsOneWidget);
    expect(find.text('indie rock'), findsNothing);

    await tester.tap(find.text('rock'));
    await tester.pumpAndSettle();
    expect(find.text('indie rock'), findsOneWidget);
    expect(find.text('garage rock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('artist timeline strip summarizes and opens mixlists', (
    tester,
  ) async {
    final points = [
      for (var i = 1; i <= 5; i++)
        TimelineMixlistPoint.positionOnly(
          position: i,
          mixlist: Mixlist(
            id: i,
            title: 'Mixlist $i',
            description: '',
            dateCreated: '202$i-01-01T00:00:00Z',
          ),
        ),
    ];
    ArtistTimelineSong song(int id) => ArtistTimelineSong(
      songId: id,
      songName: 'Song $id',
      albumCoverImageURL: null,
    );
    (TimelineMixlistPoint, ArtistTimelineSong)? tapped;
    await tester.pumpWidget(
      _wrap(
        ArtistTimelineStrip(
          artistId: 1,
          artistName: 'Artist',
          points: points,
          songsByPosition: {
            2: [song(1)],
            4: [song(2), song(3)],
          },
          onSongTap: (point, song) => tapped = (point, song),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('On 2 of 5 mixlists'), findsOneWidget);
    final fourth = find.byTooltip(
      '#4 Mixlist 4 · 2024-01-01\n♪ Song 2\n♪ Song 3',
    );
    expect(fourth, findsOneWidget);

    await tester.tap(fourth);
    expect(tapped?.$1.position, 4);
    expect(tapped?.$2.songId, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single mixlist does not break the charts', (tester) async {
    final timeline = _timeline(mixlistCount: 1);
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            FeatureTrendChart(points: timeline.points),
            GenreDriftChart(
              points: timeline.points,
              bands: timeline.genreBands,
              windows: timeline.genreWindows,
            ),
            MusicAgeChart(
              points: timeline.points,
              overallMedianYears: timeline.overallMedianMusicAgeYears,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
