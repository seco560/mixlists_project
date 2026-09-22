import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// Shared horizontal scale so every timeline section lines its mixlists up
/// under one another: a fixed left gutter, then the plot fit to the width.
class TimelineLayout {
  const TimelineLayout({required this.count, required this.plotWidth});

  static const gutterWidth = 120.0;
  static const rightPadding = 16.0;

  /// Builds a layout from a [LayoutBuilder]'s total width.
  factory TimelineLayout.fromWidth(int count, double totalWidth) =>
      TimelineLayout(
        count: count,
        plotWidth: (totalWidth - gutterWidth - rightPadding).clamp(
          1.0,
          double.infinity,
        ),
      );

  final int count;
  final double plotWidth;

  double get step => count == 0 ? plotWidth : plotWidth / count;

  /// Center of the 1-based [position]'s column.
  double xFor(int position) => (position - 0.5) * step;
}

/// Year labels (from `dateCreated`, as labels only) at each year's first
/// mixlist, skipping any that would crowd the previous one.
class TimelineXAxis extends StatelessWidget {
  const TimelineXAxis({super.key, required this.points});

  final List<TimelineMixlistPoint> points;

  static const height = 18.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = TimelineLayout.fromWidth(
          points.length,
          constraints.maxWidth,
        );
        return Padding(
          padding: const EdgeInsets.only(left: TimelineLayout.gutterWidth),
          child: SizedBox(
            width: layout.plotWidth,
            height: height,
            child: CustomPaint(
              painter: _XAxisPainter(
                points: points,
                layout: layout,
                color:
                    theme.textTheme.bodySmall?.color ??
                    theme.colorScheme.onSurface,
                tickColor: theme.dividerColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _XAxisPainter extends CustomPainter {
  _XAxisPainter({
    required this.points,
    required this.layout,
    required this.color,
    required this.tickColor,
  });

  final List<TimelineMixlistPoint> points;
  final TimelineLayout layout;
  final Color color;
  final Color tickColor;

  static const _minLabelGap = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    String? lastYear;
    double? lastLabelX;
    for (final point in points) {
      final date = point.mixlist.dateCreated;
      if (date.length < 4) continue;
      final year = date.substring(0, 4);
      if (year == lastYear) continue;
      lastYear = year;
      final x = layout.xFor(point.position);
      if (lastLabelX != null && x - lastLabelX < _minLabelGap) continue;
      lastLabelX = x;
      canvas.drawLine(Offset(x, 0), Offset(x, 4), tickPaint);
      final text = TextPainter(
        text: TextSpan(
          text: year,
          style: metaTextStyle.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x - text.width / 2).clamp(
        0.0,
        (size.width - text.width).clamp(0.0, double.infinity),
      );
      text.paint(canvas, Offset(left, 4));
    }
  }

  @override
  bool shouldRepaint(_XAxisPainter old) =>
      old.points != points ||
      old.layout.plotWidth != layout.plotWidth ||
      old.color != color;
}
