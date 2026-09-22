import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/audio_feature_field.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/timeline_dot_chart.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// Per-mixlist mean of one continuous audio feature, with a trend line.
class FeatureTrendChart extends StatefulWidget {
  const FeatureTrendChart({
    super.key,
    required this.points,
    this.onPointTap,
    this.playlistNounSingularLower = 'mixlist',
    this.playlistNounPluralLower = 'mixlists',
  });

  final List<TimelineMixlistPoint> points;
  final void Function(TimelineMixlistPoint point)? onPointTap;

  /// The caller's filter wording, passed in so this widget stays DI-free.
  final String playlistNounSingularLower;
  final String playlistNounPluralLower;

  static final fields = [
    for (final f in AudioFeatureField.values)
      if (f.isContinuous) f,
  ];

  @override
  State<FeatureTrendChart> createState() => _FeatureTrendChartState();
}

class _FeatureTrendChartState extends State<FeatureTrendChart> {
  AudioFeatureField _field = AudioFeatureField.energy;

  String _formatValue(double value) => switch (_field) {
    AudioFeatureField.loudness => '${value.toStringAsFixed(1)} dB',
    AudioFeatureField.tempo => '${value.toStringAsFixed(0)} BPM',
    _ => value.toStringAsFixed(2),
  };

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final values = [for (final p in points) p.featureMeans[_field]];
    final present = values.whereType<double>().toList();
    final covered = points.where((p) => p.featureTrackCount > 0).length;

    final Widget chart;
    if (present.isEmpty) {
      chart = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No audio feature data for these ${widget.playlistNounPluralLower}.',
          style: metaTextStyle,
        ),
      );
    } else {
      // Tempo sits far from 0, so its domain hugs the data instead.
      final (domainMin, domainMax) = switch (_field) {
        AudioFeatureField.loudness => (present.reduce(min), 0.0),
        AudioFeatureField.tempo => (
          present.reduce(min).floorToDouble(),
          present.reduce(max).ceilToDouble(),
        ),
        _ => (0.0, present.reduce(max)),
      };
      chart = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimelineDotChart(
            points: points,
            values: values,
            domainMin: domainMin,
            domainMax: domainMax > domainMin ? domainMax : domainMin + 1,
            formatValue: _formatValue,
            onPointTap: widget.onPointTap,
          ),
          TimelineXAxis(points: points),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<AudioFeatureField>(
                value: _field,
                items: [
                  for (final field in FeatureTrendChart.fields)
                    DropdownMenuItem(value: field, child: Text(field.label)),
                ],
                onChanged: (field) {
                  if (field != null) setState(() => _field = field);
                },
              ),
              Text(
                'Mean per ${widget.playlistNounSingularLower}, with a '
                '5-${widget.playlistNounSingularLower} rolling average. '
                '$covered of ${points.length} ${widget.playlistNounPluralLower}'
                ' have audio feature data.',
                style: metaTextStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        chart,
      ],
    );
  }
}
