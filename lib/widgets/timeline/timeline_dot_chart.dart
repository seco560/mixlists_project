import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/chart_y_axis.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// One dot per mixlist plus a rolling-mean trend line, on the shared
/// [TimelineLayout] scale. Hover a column for its value; tap to open it.
class TimelineDotChart extends StatelessWidget {
  const TimelineDotChart({
    super.key,
    required this.points,
    required this.values,
    required this.domainMin,
    required this.domainMax,
    required this.formatValue,
    this.onPointTap,
    this.trendWindow = 5,
    this.height = 140,
  }) : assert(points.length == values.length);

  final List<TimelineMixlistPoint> points;

  /// Parallel to [points]; null means no data for that mixlist.
  final List<double?> values;
  final double domainMin;
  final double domainMax;
  final String Function(double) formatValue;
  final void Function(TimelineMixlistPoint point)? onPointTap;
  final int trendWindow;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trend = rollingMean(values, trendWindow);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = TimelineLayout.fromWidth(
          points.length,
          constraints.maxWidth,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartYAxis(
              domainMin: domainMin,
              domainMax: domainMax,
              height: height,
              formatValue: formatValue,
              width: TimelineLayout.gutterWidth,
            ),
            SizedBox(
              width: layout.plotWidth,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DotChartPainter(
                        values: values,
                        trend: trend,
                        layout: layout,
                        domainMin: domainMin,
                        domainMax: domainMax,
                        dotColor: colors.primary.withValues(alpha: 0.45),
                        lineColor: colors.primary,
                        gridColor: colors.outlineVariant,
                      ),
                    ),
                  ),
                  for (var i = 0; i < points.length; i++)
                    if (values[i] != null)
                      Positioned(
                        left: layout.xFor(points[i].position) - layout.step / 2,
                        width: layout.step,
                        top: 0,
                        bottom: 0,
                        child: Tooltip(
                          message:
                              '#${points[i].position} ${points[i].mixlist.title}'
                              '\n${formatValue(values[i]!)}',
                          child: InkWell(
                            mouseCursor: onPointTap == null
                                ? MouseCursor.defer
                                : SystemMouseCursors.click,
                            onTap: onPointTap == null
                                ? null
                                : () => onPointTap!(points[i]),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotChartPainter extends CustomPainter {
  _DotChartPainter({
    required this.values,
    required this.trend,
    required this.layout,
    required this.domainMin,
    required this.domainMax,
    required this.dotColor,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double?> values;
  final List<double?> trend;
  final TimelineLayout layout;
  final double domainMin;
  final double domainMax;
  final Color dotColor;
  final Color lineColor;
  final Color gridColor;

  double _y(double value, double height) {
    final range = domainMax - domainMin;
    final fraction = range <= 0 ? 0.0 : (value - domainMin) / range;
    return height - height * fraction.clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final y in [0.0, size.height / 2, size.height]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final radius = (layout.step / 2.5).clamp(1.5, 4.0);
    final dotPaint = Paint()..color = dotColor;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      canvas.drawCircle(
        Offset(layout.xFor(i + 1), _y(v, size.height)),
        radius,
        dotPaint,
      );
    }

    // Breaks the line wherever the trend has no data.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    var drawing = false;
    for (var i = 0; i < trend.length; i++) {
      final v = trend[i];
      if (v == null) {
        drawing = false;
        continue;
      }
      final offset = Offset(layout.xFor(i + 1), _y(v, size.height));
      drawing
          ? path.lineTo(offset.dx, offset.dy)
          : path.moveTo(offset.dx, offset.dy);
      drawing = true;
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_DotChartPainter old) =>
      old.values != values ||
      old.layout.plotWidth != layout.plotWidth ||
      old.domainMin != domainMin ||
      old.domainMax != domainMax ||
      old.lineColor != lineColor;
}
