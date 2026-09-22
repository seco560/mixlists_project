import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/timeline_dot_chart.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// Per-mixlist median of how old the music was when it was added.
class MusicAgeChart extends StatelessWidget {
  const MusicAgeChart({
    super.key,
    required this.points,
    required this.overallMedianYears,
    this.onPointTap,
    this.playlistNounSingularLower = 'mixlist',
  });

  final List<TimelineMixlistPoint> points;
  final double? overallMedianYears;
  final void Function(TimelineMixlistPoint point)? onPointTap;
  final String playlistNounSingularLower;

  static String formatYears(double years) => '${years.toStringAsFixed(1)} yrs';

  @override
  Widget build(BuildContext context) {
    final values = [for (final p in points) p.medianMusicAgeYears];
    final present = values.whereType<double>().toList();
    final overall = overallMedianYears;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Median years between an album\'s release and its track being '
            'added, per $playlistNounSingularLower.'
            '${overall == null ? '' : ' Overall median: ${formatYears(overall)}.'}',
            style: metaTextStyle,
          ),
        ),
        if (present.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No release/added dates to compare.',
              style: metaTextStyle,
            ),
          )
        else ...[
          TimelineDotChart(
            points: points,
            values: values,
            domainMin: 0,
            domainMax: max(1.0, present.reduce(max)),
            formatValue: formatYears,
            onPointTap: onPointTap,
          ),
          TimelineXAxis(points: points),
        ],
      ],
    );
  }
}
