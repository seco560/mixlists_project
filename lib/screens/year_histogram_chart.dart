import 'dart:math';

import 'package:flutter/material.dart';

import 'song_mixlist_tile.dart' show metaTextStyle;

/// A simple bar chart of a per-year count, e.g. how many songs by an
/// artist were added to a mixlist each year, or how many tracks on a
/// mixlist were released in each year. Every year between the lowest and
/// highest key in [countsByYear] gets a bar -- years absent from the map
/// (count 0) still render at zero height, so gaps in the distribution are
/// visible rather than silently skipped.
class YearHistogramChart extends StatelessWidget {
  const YearHistogramChart({super.key, required this.countsByYear});

  /// Year -> count. Need not include every year in range -- missing years
  /// are treated as a count of 0.
  final Map<int, int> countsByYear;

  static const _barWidth = 28.0;
  static const _maxBarHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    if (countsByYear.isEmpty) return const SizedBox.shrink();

    final minYear = countsByYear.keys.reduce(min);
    final maxYear = countsByYear.keys.reduce(max);
    final maxCount = countsByYear.values.reduce(max);
    final barColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: _maxBarHeight + 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var year = minYear; year <= maxYear; year++) ...[
              if (year > minYear) const SizedBox(width: 4),
              _YearBar(
                year: year,
                count: countsByYear[year] ?? 0,
                maxCount: maxCount,
                color: barColor,
                width: _barWidth,
                maxHeight: _maxBarHeight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _YearBar extends StatelessWidget {
  const _YearBar({
    required this.year,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.width,
    required this.maxHeight,
  });

  final int year;
  final int count;
  final int maxCount;
  final Color color;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final barHeight = maxCount == 0 ? 0.0 : maxHeight * count / maxCount;
    return Tooltip(
      message: '$count in $year',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: metaTextStyle),
          const SizedBox(height: 4),
          Container(
            width: width,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 4),
          Text('$year', style: metaTextStyle),
        ],
      ),
    );
  }
}
