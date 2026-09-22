import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/audio_feature_field.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/chart_y_axis.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

enum _SortMode { trackOrder, ascending, descending }

const _keyNames = [
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];

/// One bar per track, showing a single selected audio-feature value,
/// orderable by track order or by value. Tracks with no data render as a
/// muted "no data" marker instead of a misleading zero-height bar.
class MixlistAudioFeatureChart extends StatefulWidget {
  const MixlistAudioFeatureChart({
    super.key,
    required this.tracks,
    this.playlistNounSingular = 'Mixlist',
  });

  final List<MixlistTrack> tracks;

  /// The caller's `playlistNounSingular`, passed in so this widget stays
  /// DI-free (its test builds it with no service locator).
  final String playlistNounSingular;

  @override
  State<MixlistAudioFeatureChart> createState() =>
      _MixlistAudioFeatureChartState();
}

class _MixlistAudioFeatureChartState extends State<MixlistAudioFeatureChart> {
  AudioFeatureField _field = AudioFeatureField.danceability;
  _SortMode _sortMode = _SortMode.trackOrder;
  final _scrollController = ScrollController();

  static const _barWidth = 28.0;
  static const _maxBarHeight = 120.0;
  // Must be >= _TrackBar's actual footer height (art + label) plus
  // _scrollbarClearance, since the chart's fixed height and y-axis
  // alignment both assume it fits here.
  static const _footerHeight = 56.0;
  // Keeps the horizontal Scrollbar from covering the position-index text.
  static const _scrollbarClearance = 14.0;
  static const _artSize = 24.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
            Text(
              'No audio feature data for this '
              '${widget.playlistNounSingular.toLowerCase()} yet.',
              style: metaTextStyle,
            ),
          ],
        ),
      );
    }

    // Loudness is ~always <= 0dB, so a taller bar means "louder"; other
    // fields floor at 0 and ceiling at the max value present in this mixlist.
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
          height: _maxBarHeight + _footerHeight + _scrollbarClearance,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ChartYAxis(
                  domainMin: domainMin,
                  domainMax: domainMax,
                  height: _maxBarHeight,
                  formatValue: _formatValue,
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
          segments: [
            ButtonSegment(
              value: _SortMode.trackOrder,
              label: Text('${widget.playlistNounSingular} Order'),
            ),
            const ButtonSegment(
              value: _SortMode.ascending,
              label: Text('Low → High'),
            ),
            const ButtonSegment(
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

  static const _positionTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

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
          Text('${track.position}', style: _positionTextStyle),
        ],
      ),
    );
  }
}
