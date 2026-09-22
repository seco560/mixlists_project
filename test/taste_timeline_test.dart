import 'package:flutter_test/flutter_test.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/models/audio_feature_field.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';

Mixlist _mixlist(int id) => Mixlist(
  id: id,
  title: 'Mixlist $id',
  description: '',
  dateCreated: '2020-01-01T00:00:00Z',
);

TimelineAppearance _appearance(
  int mixlistId, {
  int songId = 1,
  int? artistId,
  String? artistName,
  List<String> genres = const [],
  String? releaseDate,
  String? dateAdded,
  Map<AudioFeatureField, double> features = const {},
}) => TimelineAppearance(
  mixlistId: mixlistId,
  songId: songId,
  artistId: artistId,
  artistName: artistName ?? (artistId == null ? null : 'Artist $artistId'),
  genres: genres,
  releaseDate: releaseDate,
  dateAdded: dateAdded,
  features: features,
);

void main() {
  group('musicAgeYears', () {
    test('full date', () {
      expect(
        musicAgeYears(
          releaseDate: '2010-01-01',
          dateAdded: '2020-01-01T00:00:00Z',
        ),
        closeTo(10, 0.01),
      );
    });

    test('year-only release takes July 1', () {
      expect(
        musicAgeYears(releaseDate: '2010', dateAdded: '2011-07-01T00:00:00Z'),
        closeTo(1, 0.01),
      );
    });

    test('month-only release takes the 15th', () {
      expect(
        musicAgeYears(
          releaseDate: '2010-03',
          dateAdded: '2010-03-15T00:00:00Z',
        ),
        0,
      );
    });

    test('added before release clamps to 0', () {
      expect(
        musicAgeYears(
          releaseDate: '2021-05-01',
          dateAdded: '2021-04-01T00:00:00Z',
        ),
        0,
      );
    });

    test('unparseable or missing dates give null', () {
      expect(
        musicAgeYears(releaseDate: 'unknown', dateAdded: '2021-04-01'),
        isNull,
      );
      expect(musicAgeYears(releaseDate: '2010', dateAdded: null), isNull);
      expect(musicAgeYears(releaseDate: '2010', dateAdded: 'garbage'), isNull);
    });
  });

  test('median and rollingMean', () {
    expect(median([]), isNull);
    expect(median([3, 1, 2]), 2);
    expect(median([4, 1, 2, 3]), 2.5);
    expect(rollingMean([1, null, 3, null, null, null, null], 3), [
      1,
      2,
      3,
      3,
      null,
      null,
      null,
    ]);
  });

  test('positions follow id order and include empty mixlists', () {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [_mixlist(7), _mixlist(3), _mixlist(5)],
      appearances: [_appearance(7), _appearance(3)],
    );
    expect([for (final p in timeline.points) p.mixlist.id], [3, 5, 7]);
    expect([for (final p in timeline.points) p.position], [1, 2, 3]);
    expect([for (final p in timeline.points) p.trackCount], [1, 0, 1]);
  });

  test('appearances outside the given mixlists are ignored', () {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [_mixlist(1)],
      appearances: [_appearance(1), _appearance(2, artistId: 9)],
    );
    expect(timeline.points.single.trackCount, 1);
  });

  test('feature means skip tracks without that feature', () {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [_mixlist(1)],
      appearances: [
        _appearance(1, features: {AudioFeatureField.energy: 0.2}),
        _appearance(1, features: {AudioFeatureField.energy: 0.6}),
        _appearance(1),
      ],
    );
    final point = timeline.points.single;
    expect(point.featureMeans[AudioFeatureField.energy], closeTo(0.4, 1e-9));
    expect(point.featureMeans.containsKey(AudioFeatureField.valence), isFalse);
    expect(point.featureTrackCount, 2);
  });

  test('median music age per mixlist and overall', () {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [_mixlist(1), _mixlist(2)],
      appearances: [
        _appearance(
          1,
          releaseDate: '2010-01-01',
          dateAdded: '2011-01-01T00:00:00Z',
        ),
        _appearance(
          1,
          releaseDate: '2010-01-01',
          dateAdded: '2013-01-01T00:00:00Z',
        ),
        _appearance(
          2,
          releaseDate: '2010-01-01',
          dateAdded: '2020-01-01T00:00:00Z',
        ),
        _appearance(2, releaseDate: 'n/a', dateAdded: '2020-01-01T00:00:00Z'),
      ],
    );
    expect(timeline.points[0].medianMusicAgeYears, closeTo(2, 0.01));
    expect(timeline.points[1].medianMusicAgeYears, closeTo(10, 0.01));
    expect(timeline.overallMedianMusicAgeYears, closeTo(3, 0.01));
  });

  group('genre windows', () {
    test('window size stays at least 3, targeting ~14 windows', () {
      expect(TasteTimeline.windowSizeFor(1), 3);
      expect(TasteTimeline.windowSizeFor(20), 3);
      expect(TasteTimeline.windowSizeFor(167), 12);
    });

    test('small library gets a single window', () {
      final timeline = TasteTimeline.fromAppearances(
        mixlists: [_mixlist(1), _mixlist(2)],
        appearances: [
          _appearance(1, genres: ['a']),
        ],
      );
      expect(timeline.genreWindows, hasLength(1));
      expect(timeline.genreWindows.single.firstPosition, 1);
      expect(timeline.genreWindows.single.lastPosition, 2);
    });

    test('multi-genre artists split 1/k and shares sum to 1', () {
      final timeline = TasteTimeline.fromAppearances(
        mixlists: [_mixlist(1)],
        appearances: [
          _appearance(1, genres: ['rock', 'pop']),
          _appearance(1, genres: ['rock']),
          _appearance(1), // no genres: left out of the shares
        ],
      );
      final shares = timeline.genreWindows.single.shares;
      expect([for (final b in timeline.genreBands) b.label], ['rock', 'pop']);
      expect(shares['rock'], closeTo(0.75, 1e-9));
      expect(shares['pop'], closeTo(0.25, 1e-9));
      expect(shares[TasteTimeline.otherGenre], closeTo(0, 1e-9));
    });

    test('names genres up to 80%, bunches the rest by family', () {
      final counts = {
        'indie rock': 100, // 50%
        'pop punk': 50, // cumulative 75%, still under 80%
        'noise rock': 20, // named: coverage was < 80% before it
        'garage rock': 10,
        'skate punk': 10,
        'hard rock': 8,
        'polka': 1, // its family is under 1%: plain "other"
      };
      final timeline = TasteTimeline.fromAppearances(
        mixlists: [_mixlist(1)],
        appearances: [
          for (final entry in counts.entries)
            for (var i = 0; i < entry.value; i++)
              _appearance(1, genres: [entry.key]),
        ],
      );
      // Families stack together, heaviest family first, bucket last.
      expect(
        [for (final b in timeline.genreBands) b.label],
        ['indie rock', 'noise rock', 'other rock', 'pop punk', 'other punk'],
      );
      expect(timeline.genreBands[2].isFamilyBucket, isTrue);
      expect(timeline.genreBands[0].isFamilyBucket, isFalse);

      final shares = timeline.genreWindows.single.shares;
      const total = 199;
      expect(shares['other rock'], closeTo(18 / total, 1e-9));
      expect(shares['other punk'], closeTo(10 / total, 1e-9));
      expect(shares[TasteTimeline.otherGenre], closeTo(1 / total, 1e-9));
      expect(shares.values.reduce((a, b) => a + b), closeTo(1, 1e-9));
    });

    test('genre families', () {
      expect(TasteTimeline.genreFamily('midwest emo'), 'emo');
      expect(TasteTimeline.genreFamily('Southern Hip Hop'), 'hip hop');
      expect(TasteTimeline.genreFamily('post-hardcore'), 'post-hardcore');
    });

    test('a window without genre data has empty shares', () {
      final timeline = TasteTimeline.fromAppearances(
        mixlists: [for (var i = 1; i <= 6; i++) _mixlist(i)],
        appearances: [
          _appearance(1, genres: ['a']),
        ],
      );
      expect(timeline.genreWindows, hasLength(2));
      expect(timeline.genreWindows[1].shares, isEmpty);
    });
  });

  test('artist lifespans need 3+ mixlists and sort by first appearance', () {
    final timeline = TasteTimeline.fromAppearances(
      mixlists: [for (var i = 1; i <= 5; i++) _mixlist(i)],
      appearances: [
        // Artist 1: mixlists 2, 3, 5 (twice on 5).
        _appearance(2, artistId: 1),
        _appearance(3, artistId: 1),
        _appearance(5, artistId: 1),
        _appearance(5, artistId: 1, songId: 2),
        // Artist 2: mixlists 1, 4, 5.
        _appearance(1, artistId: 2),
        _appearance(4, artistId: 2),
        _appearance(5, artistId: 2),
        // Artist 3: only 2 mixlists, excluded.
        _appearance(1, artistId: 3),
        _appearance(2, artistId: 3),
      ],
    );
    final lifespans = timeline.artistLifespans;
    expect([for (final l in lifespans) l.artistId], [2, 1]);
    expect(lifespans[0].positions, [1, 4, 5]);
    expect(lifespans[0].span, 4);
    expect(lifespans[1].positions, [2, 3, 5]);
    expect(lifespans[1].appearanceCount, 4);
  });
}
