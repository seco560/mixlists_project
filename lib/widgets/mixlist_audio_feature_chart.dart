import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/mixlist_track.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// The Spotify audio-feature fields available to chart, in the order they
/// appear in the picker. Labels are what the dropdown shows.
enum AudioFeatureField {
  danceability('Danceability'),
  energy('Energy'),
  valence('Valence'),
  acousticness('Acousticness'),
  instrumentalness('Instrumentalness'),
  liveness('Liveness'),
  speechiness('Speechiness'),
  loudness('Loudness'),
  tempo('Tempo'),
  key('Key'),
  mode('Mode'),
  timeSignature('Time Signature');

  const AudioFeatureField(this.label);
  final String label;
}

enum _SortMode { trackOrder, ascending, descending }

const _keyNames = [
  'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B',
];

/// One bar per track on a mixlist, showing a single Spotify audio-feature
/// value (picked from the dropdown), orderable either by the mixlist's own
/// track order or by the selected value. Only ever one series/hue at a
/// time -- switching features swaps the whole chart rather than adding a
/// second axis. Tracks with no audio-feature data (older, never
/// re-exported mixlists; see the CSV ingestion feature notes) render as a
/// muted "no data" marker instead of a misleading zero-height bar.
class MixlistAudioFeatureChart extends StatefulWidget {
  const MixlistAudioFeatureChart({super.key, required this.tracks});

  final List<MixlistTrack> tracks;

  @override
  State<MixlistAudioFeatureChart> createState() =>
      _MixlistAudioFeatureChartState();
}

class _MixlistAudioFeatureChartState extends State<MixlistAudioFeatureChart> {
  AudioFeatureField _field = AudioFeatureField.danceability;
  _SortMode _sortMode = _SortMode.trackOrder;

  static const _barWidth = 28.0;
  static const _maxBarHeight = 120.0;
  // Space below the bar for the album art thumbnail + track position label
  // (SizedBox(4) + art(24) + SizedBox(2) + label line, with slack for the
  // label's real rendered height) -- must be >= _TrackBar's actual footer
  // height, since the chart area's fixed height and the y-axis's alignment
  // both assume every column's footer fits within this much space.
  static const _footerHeight = 56.0;
  static const _artSize = 24.0;

  double? _valueFor(MixlistTrack track) {
    switch (_field) {
      case AudioFeatureField.danceability:
        return track.danceability;
      case AudioFeatureField.energy:
        return track.energy;
      case AudioFeatureField.valence:
        return track.valence;
      case AudioFeatureField.acousticness:
        return track.acousticness;
      case AudioFeatureField.instrumentalness:
        return track.instrumentalness;
      case AudioFeatureField.liveness:
        return track.liveness;
      case AudioFeatureField.speechiness:
        return track.speechiness;
      case AudioFeatureField.loudness:
        return track.loudness;
      case AudioFeatureField.tempo:
        return track.tempo;
      case AudioFeatureField.key:
        return track.key?.toDouble();
      case AudioFeatureField.mode:
        return track.mode?.toDouble();
      case AudioFeatureField.timeSignature:
        return track.timeSignature?.toDouble();
    }
  }

  String _formatValue(double value) {
    switch (_field) {
      case AudioFeatureField.loudness:
        return '${value.toStringAsFixed(1)} dB';
      case AudioFeatureField.tempo:
        return '${value.toStringAsFixed(0)} BPM';
      case AudioFeatureField.key:
        final i = value.round();
        return i >= 0 && i < _keyNames.length ? _keyNames[i] : '?';
      case AudioFeatureField.mode:
        return value.round() == 1 ? 'Major' : 'Minor';
      case AudioFeatureField.timeSignature:
        return '${value.round()}/4';
      default:
        return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.tracks;
    if (tracks.isEmpty) return const SizedBox.shrink();

    final ordered = List<MixlistTrack>.from(tracks);
    if (_sortMode != _SortMode.trackOrder) {
      ordered.sort((a, b) {
        final valueA = _valueFor(a);
        final valueB = _valueFor(b);
        if (valueA == null && valueB == null) return 0;
        if (valueA == null) return 1; // nulls sort last either direction
        if (valueB == null) return -1;
        return _sortMode == _SortMode.ascending
            ? valueA.compareTo(valueB)
            : valueB.compareTo(valueA);
      });
    }

    final presentValues = [
      for (final t in ordered) _valueFor(t),
    ].whereType<double>().toList();

    if (presentValues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _controls(),
            const SizedBox(height: 12),
            const Text(
              'No audio feature data for this mixlist yet.',
              style: metaTextStyle,
            ),
          ],
        ),
      );
    }

    // Loudness is (almost) always <= 0dB -- floor the domain at the
    // quietest track present, ceiling at 0, so a taller bar always means
    // "louder." Every other field floors at 0 and ceilings at the loudest
    // value actually present in this mixlist, so the chart uses its full
    // height to show relative variation within the mixlist rather than
    // against each field's theoretical range.
    double domainMin;
    double domainMax;
    if (_field == AudioFeatureField.loudness) {
      domainMin = min(0.0, presentValues.reduce(min));
      domainMax = max(0.0, presentValues.reduce(max));
    } else {
      domainMin = 0;
      domainMax = presentValues.reduce(max);
      if (domainMax <= domainMin) domainMax = domainMin + 1;
    }

    final barColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _controls(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _maxBarHeight + _footerHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _YAxis(
                  domainMin: domainMin,
                  domainMax: domainMax,
                  height: _maxBarHeight,
                  formatValue: _formatValue,
                ),
              ),
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < ordered.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          _TrackBar(
                            track: ordered[i],
                            value: _valueFor(ordered[i]),
                            domainMin: domainMin,
                            domainMax: domainMax,
                            color: barColor,
                            width: _barWidth,
                            maxHeight: _maxBarHeight,
                            artSize: _artSize,
                            formatValue: _formatValue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<AudioFeatureField>(
          value: _field,
          items: [
            for (final field in AudioFeatureField.values)
              DropdownMenuItem(value: field, child: Text(field.label)),
          ],
          onChanged: (field) {
            if (field != null) setState(() => _field = field);
          },
        ),
        SegmentedButton<_SortMode>(
          segments: const [
            ButtonSegment(
              value: _SortMode.trackOrder,
              label: Text('Mixlist Order'),
            ),
            ButtonSegment(
              value: _SortMode.ascending,
              label: Text('Low → High'),
            ),
            ButtonSegment(
              value: _SortMode.descending,
              label: Text('High → Low'),
            ),
          ],
          selected: {_sortMode},
          onSelectionChanged: (selection) =>
              setState(() => _sortMode = selection.first),
        ),
      ],
    );
  }
}

class _TrackBar extends StatelessWidget {
  const _TrackBar({
    required this.track,
    required this.value,
    required this.domainMin,
    required this.domainMax,
    required this.color,
    required this.width,
    required this.maxHeight,
    required this.artSize,
    required this.formatValue,
  });

  final MixlistTrack track;
  final double? value;
  final double domainMin;
  final double domainMax;
  final Color color;
  final double width;
  final double maxHeight;
  final double artSize;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final message = v == null
        ? '${track.songName}\n${track.artistNames}\nNo data'
        : '${track.songName}\n${track.artistNames}\n${formatValue(v)}';

    final Widget bar;
    if (v == null) {
      bar = Container(
        width: width,
        height: 6,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      );
    } else {
      final range = domainMax - domainMin;
      final fraction = range <= 0 ? 0.0 : (v - domainMin) / range;
      final barHeight = (maxHeight * fraction.clamp(0.0, 1.0)).clamp(
        2.0,
        maxHeight,
      );
      bar = Container(
        width: width,
        height: barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      );
    }

    return Tooltip(
      message: message,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bar,
          const SizedBox(height: 4),
          AlbumArtThumbnail(
            imageUrl: track.albumCoverImageURL,
            size: artSize,
            borderRadius: 3,
          ),
          const SizedBox(height: 2),
          Text('${track.position}', style: metaTextStyle),
        ],
      ),
    );
  }
}

/// A lightweight, illustrative y-axis for the bar area only (not the album
/// art / label footer below it) -- three ticks (max, midpoint, min) plus a
/// vertical rule, positioned to align exactly with where the bars
/// themselves are drawn. "Illustrative" rather than exact: this chart's
/// domain is recomputed per field/mixlist (see the domain comment in
/// MixlistAudioFeatureChart.build), so the ticks exist to give a sense of
/// scale and range, not to support precise readoff -- exact values are a
/// hover away on every bar.
class _YAxis extends StatelessWidget {
  const _YAxis({
    required this.domainMin,
    required this.domainMax,
    required this.height,
    required this.formatValue,
  });

  final double domainMin;
  final double domainMax;
  final double height;
  final String Function(double) formatValue;

  static const _width = 68.0;
  static const _tickLength = 5.0;

  @override
  Widget build(BuildContext context) {
    final mid = (domainMin + domainMax) / 2;
    final axisColor = Colors.blueGrey.shade200;

    Widget tickRow(double value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatValue(value), style: metaTextStyle),
          const SizedBox(width: 4),
          Container(width: _tickLength, height: 1, color: axisColor),
        ],
      );
    }

    return SizedBox(
      width: _width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: axisColor),
          ),
          // Anchored to their own edge (not centered past it) so the label
          // text never extends outside the SizedBox's bounds -- Stack
          // clips to its bounds by default, so a centered label at the
          // very top/bottom would have its far side clipped off.
          Positioned(right: 0, top: 0, child: tickRow(domainMax)),
          Positioned(
            right: 0,
            top: height / 2,
            child: FractionalTranslation(
              translation: const Offset(0, -0.5),
              child: tickRow(mid),
            ),
          ),
          Positioned(right: 0, bottom: 0, child: tickRow(domainMin)),
        ],
      ),
    );
  }
}
