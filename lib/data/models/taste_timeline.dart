import 'dart:math';

import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/models/audio_feature_field.dart';

/// One song-on-a-mixlist row, the raw input to [TasteTimeline].
class TimelineAppearance {
  const TimelineAppearance({
    required this.mixlistId,
    required this.songId,
    this.artistId,
    this.artistName,
    this.genres = const [],
    this.releaseDate,
    this.dateAdded,
    this.features = const {},
  });

  final int mixlistId;
  final int songId;

  /// The album artist (`Albums.artist`), since songs have no per-artist FK.
  final int? artistId;
  final String? artistName;
  final List<String> genres;
  final String? releaseDate;
  final String? dateAdded;

  /// Only continuous fields that have a value.
  final Map<AudioFeatureField, double> features;
}

class TimelineMixlistPoint {
  const TimelineMixlistPoint({
    required this.position,
    required this.mixlist,
    required this.trackCount,
    required this.featureMeans,
    required this.featureTrackCount,
    required this.medianMusicAgeYears,
  });

  /// 1-based position in id order under the filter, i.e. the display number.
  final int position;
  final Mixlist mixlist;
  final int trackCount;
  final Map<AudioFeatureField, double> featureMeans;

  /// How many tracks had any audio-feature data.
  final int featureTrackCount;
  final double? medianMusicAgeYears;
}

/// One stacked band: a single genre, or an `other <family>` bucket.
class GenreBand {
  const GenreBand({required this.label, required this.family});

  final String label;
  final String family;

  bool get isFamilyBucket => label == 'other $family';
}

class GenreWindow {
  const GenreWindow({
    required this.firstPosition,
    required this.lastPosition,
    required this.shares,
  });

  final int firstPosition;
  final int lastPosition;

  /// Genre (or [TasteTimeline.otherGenre]) -> share in 0..1. Empty when no
  /// appearance in the window has genre data.
  final Map<String, double> shares;
}

class ArtistLifespan {
  const ArtistLifespan({
    required this.artistId,
    required this.name,
    required this.positions,
    required this.appearanceCount,
  });

  final int artistId;
  final String name;

  /// Sorted, distinct positions of the mixlists this artist appears on.
  final List<int> positions;
  final int appearanceCount;

  int get firstPosition => positions.first;
  int get lastPosition => positions.last;
  int get span => lastPosition - firstPosition;
}

/// Library-wide trends across mixlists in chronological (id) order.
class TasteTimeline {
  const TasteTimeline({
    required this.points,
    required this.genreBands,
    required this.genreWindows,
    required this.artistLifespans,
    required this.overallMedianMusicAgeYears,
  });

  static const otherGenre = 'other';
  static const namedGenreCoverage = 0.8;
  static const minBandShare = 0.01;
  static const minArtistMixlists = 3;
  static const _targetWindowCount = 14;
  static const _minWindowSize = 3;

  final List<TimelineMixlistPoint> points;

  /// Bands in stacking order (bottom first); [genreWindows] shares use
  /// their labels plus [otherGenre], which always stacks on top.
  final List<GenreBand> genreBands;
  final List<GenreWindow> genreWindows;

  /// Ordered by first appearance, then name.
  final List<ArtistLifespan> artistLifespans;
  final double? overallMedianMusicAgeYears;

  bool get isEmpty => points.isEmpty;

  /// [mixlists] are every mixlist under the filter (so empty ones still take
  /// a position); [appearances] are their tracks.
  factory TasteTimeline.fromAppearances({
    required List<Mixlist> mixlists,
    required List<TimelineAppearance> appearances,
  }) {
    final ordered = [...mixlists]..sort((a, b) => a.id.compareTo(b.id));
    final positionById = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i + 1,
    };
    final byMixlist = <int, List<TimelineAppearance>>{};
    for (final a in appearances) {
      if (!positionById.containsKey(a.mixlistId)) continue;
      byMixlist.putIfAbsent(a.mixlistId, () => []).add(a);
    }

    final allAges = <double>[];
    final points = <TimelineMixlistPoint>[];
    for (final mixlist in ordered) {
      final tracks = byMixlist[mixlist.id] ?? const <TimelineAppearance>[];
      final sums = <AudioFeatureField, double>{};
      final counts = <AudioFeatureField, int>{};
      var featureTrackCount = 0;
      final ages = <double>[];
      for (final t in tracks) {
        if (t.features.isNotEmpty) featureTrackCount++;
        t.features.forEach((field, value) {
          sums[field] = (sums[field] ?? 0) + value;
          counts[field] = (counts[field] ?? 0) + 1;
        });
        final age = musicAgeYears(
          releaseDate: t.releaseDate,
          dateAdded: t.dateAdded,
        );
        if (age != null) ages.add(age);
      }
      allAges.addAll(ages);
      points.add(
        TimelineMixlistPoint(
          position: positionById[mixlist.id]!,
          mixlist: mixlist,
          trackCount: tracks.length,
          featureMeans: {
            for (final field in sums.keys) field: sums[field]! / counts[field]!,
          },
          featureTrackCount: featureTrackCount,
          medianMusicAgeYears: median(ages),
        ),
      );
    }

    final (genreBands, genreWindows) = _genreWindows(
      ordered.length,
      positionById,
      appearances,
    );

    return TasteTimeline(
      points: points,
      genreBands: genreBands,
      genreWindows: genreWindows,
      artistLifespans: _artistLifespans(positionById, appearances),
      overallMedianMusicAgeYears: median(allAges),
    );
  }

  /// Mixlists per genre window: about [_targetWindowCount] windows, but
  /// never fewer than [_minWindowSize] mixlists each.
  static int windowSizeFor(int mixlistCount) =>
      max(_minWindowSize, (mixlistCount / _targetWindowCount).ceil());

  static (List<GenreBand>, List<GenreWindow>) _genreWindows(
    int mixlistCount,
    Map<int, int> positionById,
    List<TimelineAppearance> appearances,
  ) {
    if (mixlistCount == 0) return (const [], const []);
    final windowSize = windowSizeFor(mixlistCount);
    final windowCount = (mixlistCount / windowSize).ceil();

    // An artist with k genres gives each 1/k, so every appearance weighs 1.
    final weightsByWindow = List.generate(
      windowCount,
      (_) => <String, double>{},
    );
    final totalByGenre = <String, double>{};
    for (final a in appearances) {
      final position = positionById[a.mixlistId];
      if (position == null || a.genres.isEmpty) continue;
      final weights = weightsByWindow[(position - 1) ~/ windowSize];
      final share = 1 / a.genres.length;
      for (final genre in a.genres) {
        weights[genre] = (weights[genre] ?? 0) + share;
        totalByGenre[genre] = (totalByGenre[genre] ?? 0) + share;
      }
    }

    final (bands, bandOf) = _genreBands(totalByGenre);

    final windows = <GenreWindow>[];
    for (var i = 0; i < windowCount; i++) {
      final weights = weightsByWindow[i];
      final total = weights.values.fold(0.0, (sum, w) => sum + w);
      final shares = <String, double>{};
      if (total > 0) {
        for (final band in bands) {
          shares[band.label] = 0;
        }
        shares[otherGenre] = 0;
        weights.forEach((genre, w) {
          final label = bandOf[genre] ?? otherGenre;
          shares[label] = shares[label]! + w / total;
        });
      }
      windows.add(
        GenreWindow(
          firstPosition: i * windowSize + 1,
          lastPosition: min((i + 1) * windowSize, mixlistCount),
          shares: shares,
        ),
      );
    }
    return (bands, windows);
  }

  /// Names genres largest-first until they cover [namedGenreCoverage] (each
  /// at least [minBandShare]); leftovers bunch into `other <family>` buckets
  /// that clear [minBandShare], the rest into [otherGenre]. Returns the
  /// bands stacked family by family, plus genre -> band label.
  static (List<GenreBand>, Map<String, String>) _genreBands(
    Map<String, double> totalByGenre,
  ) {
    final total = totalByGenre.values.fold(0.0, (sum, w) => sum + w);
    if (total == 0) return (const [], const {});
    final sorted = totalByGenre.keys.toList()
      ..sort((a, b) {
        final byWeight = totalByGenre[b]!.compareTo(totalByGenre[a]!);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });

    final bandOf = <String, String>{};
    final bandWeight = <String, double>{};
    final bandFamily = <String, String>{};
    var covered = 0.0;
    final leftovers = <String>[];
    for (final genre in sorted) {
      final weight = totalByGenre[genre]!;
      if (covered / total < namedGenreCoverage &&
          weight / total >= minBandShare) {
        bandOf[genre] = genre;
        bandWeight[genre] = weight;
        bandFamily[genre] = genreFamily(genre);
        covered += weight;
      } else {
        leftovers.add(genre);
      }
    }

    final familyWeight = <String, double>{};
    for (final genre in leftovers) {
      final family = genreFamily(genre);
      familyWeight[family] = (familyWeight[family] ?? 0) + totalByGenre[genre]!;
    }
    for (final genre in leftovers) {
      final family = genreFamily(genre);
      final weight = familyWeight[family]!;
      if (weight / total < minBandShare) continue;
      final label = 'other $family';
      bandOf[genre] = label;
      bandWeight[label] = weight;
      bandFamily[label] = family;
    }

    // Stack each family together (heaviest family first), named genres
    // before their family's bucket.
    final familyTotal = <String, double>{};
    bandWeight.forEach((label, w) {
      final family = bandFamily[label]!;
      familyTotal[family] = (familyTotal[family] ?? 0) + w;
    });
    final labels = bandWeight.keys.toList()
      ..sort((a, b) {
        final fa = bandFamily[a]!, fb = bandFamily[b]!;
        if (fa != fb) {
          final byFamily = familyTotal[fb]!.compareTo(familyTotal[fa]!);
          return byFamily != 0 ? byFamily : fa.compareTo(fb);
        }
        final aBucket = a == 'other $fa', bBucket = b == 'other $fb';
        if (aBucket != bBucket) return aBucket ? 1 : -1;
        final byWeight = bandWeight[b]!.compareTo(bandWeight[a]!);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });
    return (
      [
        for (final label in labels)
          GenreBand(label: label, family: bandFamily[label]!),
      ],
      bandOf,
    );
  }

  /// Rough genre family: the last word ("midwest emo" -> "emo"), keeping
  /// "hip hop" whole.
  static String genreFamily(String genre) {
    final g = genre.trim().toLowerCase();
    if (g.endsWith('hip hop')) return 'hip hop';
    final space = g.lastIndexOf(' ');
    return space == -1 ? g : g.substring(space + 1);
  }

  static List<ArtistLifespan> _artistLifespans(
    Map<int, int> positionById,
    List<TimelineAppearance> appearances,
  ) {
    final positions = <int, Set<int>>{};
    final counts = <int, int>{};
    final names = <int, String>{};
    for (final a in appearances) {
      final artistId = a.artistId;
      final position = positionById[a.mixlistId];
      if (artistId == null || position == null) continue;
      positions.putIfAbsent(artistId, () => {}).add(position);
      counts[artistId] = (counts[artistId] ?? 0) + 1;
      names[artistId] ??= a.artistName ?? '';
    }
    final lifespans = [
      for (final entry in positions.entries)
        if (entry.value.length >= minArtistMixlists)
          ArtistLifespan(
            artistId: entry.key,
            name: names[entry.key]!,
            positions: entry.value.toList()..sort(),
            appearanceCount: counts[entry.key]!,
          ),
    ];
    lifespans.sort((a, b) {
      final byFirst = a.firstPosition.compareTo(b.firstPosition);
      return byFirst != 0 ? byFirst : a.name.compareTo(b.name);
    });
    return lifespans;
  }
}

/// Years between a release date (`YYYY`, `YYYY-MM` or `YYYY-MM-DD`) and when
/// the track was added, clamped at 0. Partial dates take the mid-period.
double? musicAgeYears({String? releaseDate, String? dateAdded}) {
  if (releaseDate == null || dateAdded == null) return null;
  final match = RegExp(
    r'^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?',
  ).firstMatch(releaseDate.trim());
  final added = DateTime.tryParse(dateAdded);
  if (match == null || added == null) return null;
  final year = int.parse(match.group(1)!);
  final month = match.group(2);
  final day = match.group(3);
  final released = DateTime.utc(
    year,
    month == null ? 7 : int.parse(month),
    day == null ? (month == null ? 1 : 15) : int.parse(day),
  );
  final days = added.toUtc().difference(released).inHours / 24;
  return max(0.0, days / 365.25);
}

/// Centered moving average over the non-null values within [window]; null
/// where the window holds no values at all.
List<double?> rollingMean(List<double?> values, int window) {
  final half = window ~/ 2;
  return [
    for (var i = 0; i < values.length; i++)
      () {
        final present = [
          for (
            var j = max(0, i - half);
            j <= min(values.length - 1, i + half);
            j++
          )
            ?values[j],
        ];
        return present.isEmpty
            ? null
            : present.reduce((a, b) => a + b) / present.length;
      }(),
  ];
}

double? median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
