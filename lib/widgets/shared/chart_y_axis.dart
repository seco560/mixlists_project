import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// Illustrative y-axis (max/mid/min ticks) for a chart area; not meant for
/// precise readoff since exact values are a hover away.
class ChartYAxis extends StatelessWidget {
  const ChartYAxis({
    super.key,
    required this.domainMin,
    required this.domainMax,
    required this.height,
    required this.formatValue,
    this.width = 68.0,
  });

  final double domainMin;
  final double domainMax;
  final double height;
  final String Function(double) formatValue;
  final double width;

  static const _tickLength = 5.0;

  @override
  Widget build(BuildContext context) {
    final mid = (domainMin + domainMax) / 2;
    final axisColor = Theme.of(context).dividerColor;

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
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: axisColor),
          ),
          // Anchored to its own edge, not centered, so the label isn't clipped.
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
