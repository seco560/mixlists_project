import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/chart_y_axis.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// 100%-stacked area of [TasteTimeline.genreBands] (plus "other") across
/// windows of mixlists, with each genre family stacked together.
class GenreDriftChart extends StatelessWidget {
  const GenreDriftChart({
    super.key,
    required this.points,
    required this.bands,
    required this.windows,
    this.playlistNounPluralLower = 'mixlists',
  });

  final List<TimelineMixlistPoint> points;
  final List<GenreBand> bands;
  final List<GenreWindow> windows;
  final String playlistNounPluralLower;

  static const _height = 220.0;

  /// Cool hues only (teal through violet): one per genre family, spread by
  /// golden-ratio steps so neighbouring families differ, members as shades.
  /// Tone follows the theme primary so it reads in light and dark mode.
  static List<Color> bandColors(ColorScheme scheme, List<GenreBand> bands) {
    final base = HSLColor.fromColor(scheme.primary);
    final saturation = base.saturation.clamp(0.4, 0.7);
    final lightness = base.lightness.clamp(0.4, 0.6);
    final families = <String>[];
    final members = <String, List<GenreBand>>{};
    for (final band in bands) {
      if (!members.containsKey(band.family)) families.add(band.family);
      members.putIfAbsent(band.family, () => []).add(band);
    }
    Color colorFor(GenreBand band) {
      final group = members[band.family]!;
      final j = group.indexOf(band);
      final hue = 165 + 130 * ((families.indexOf(band.family) * 0.618034) % 1);
      final shade = group.length == 1
          ? 0.0
          : -0.15 + 0.3 * j / (group.length - 1);
      return HSLColor.fromAHSL(
        1,
        hue,
        band.isFamilyBucket ? saturation * 0.6 : saturation,
        (lightness + shade).clamp(0.2, 0.8),
      ).toColor();
    }

    return [for (final band in bands) colorFor(band)];
  }

  static const _tooltipLines = 12;

  String _tooltip(GenreWindow window) {
    final entries =
        window.shares.entries.where((e) => e.value >= 0.005).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return [
      '#${window.firstPosition}–#${window.lastPosition}',
      for (final entry in entries.take(_tooltipLines))
        '${entry.key} ${(entry.value * 100).toStringAsFixed(0)}%',
      if (entries.length > _tooltipLines)
        '+${entries.length - _tooltipLines} more',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final withData = windows.where((w) => w.shares.isNotEmpty).toList();
    if (bands.isEmpty || withData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No genre data yet.', style: metaTextStyle),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final series = [for (final b in bands) b.label, TasteTimeline.otherGenre];
    final colors = [...bandColors(scheme, bands), scheme.outlineVariant];
    final windowSize =
        windows.first.lastPosition - windows.first.firstPosition + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Share of album-artist genres, in groups of $windowSize '
            '$playlistNounPluralLower. An artist with several genres splits '
            'its weight evenly between them. The largest genres are named up '
            'to 80% of the total; smaller ones bunch into "other <family>" by '
            'their last word (e.g. "other rock"), or plain "other".',
            style: metaTextStyle,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = TimelineLayout.fromWidth(
              points.length,
              constraints.maxWidth,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChartYAxis(
                  domainMin: 0,
                  domainMax: 1,
                  height: _height,
                  formatValue: (v) => '${(v * 100).round()}%',
                  width: TimelineLayout.gutterWidth,
                ),
                SizedBox(
                  width: layout.plotWidth,
                  height: _height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _StackedAreaPainter(
                            windows: withData,
                            series: series,
                            colors: colors,
                            layout: layout,
                          ),
                        ),
                      ),
                      for (final window in withData)
                        Positioned(
                          left:
                              layout.xFor(window.firstPosition) -
                              layout.step / 2,
                          width:
                              (window.lastPosition - window.firstPosition + 1) *
                              layout.step,
                          top: 0,
                          bottom: 0,
                          child: Tooltip(
                            message: _tooltip(window),
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        TimelineXAxis(points: points),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < series.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(series[i], style: metaTextStyle),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StackedAreaPainter extends CustomPainter {
  _StackedAreaPainter({
    required this.windows,
    required this.series,
    required this.colors,
    required this.layout,
  });

  final List<GenreWindow> windows;
  final List<String> series;
  final List<Color> colors;
  final TimelineLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    // Window centers, padded out to both plot edges with the end values.
    final xs = [
      0.0,
      for (final w in windows)
        layout.xFor(w.firstPosition) +
            (w.lastPosition - w.firstPosition) * layout.step / 2,
      size.width,
    ];
    List<double> padEnds(List<double> ys) => [ys.first, ...ys, ys.last];

    var lower = List<double>.filled(windows.length, 0);
    for (var s = 0; s < series.length; s++) {
      final upper = [
        for (var i = 0; i < windows.length; i++)
          lower[i] + (windows[i].shares[series[s]] ?? 0),
      ];
      final lowerYs = padEnds([for (final v in lower) size.height * (1 - v)]);
      final upperYs = padEnds([for (final v in upper) size.height * (1 - v)]);
      final path = Path()..moveTo(xs.first, upperYs.first);
      for (var i = 1; i < xs.length; i++) {
        path.lineTo(xs[i], upperYs[i]);
      }
      for (var i = xs.length - 1; i >= 0; i--) {
        path.lineTo(xs[i], lowerYs[i]);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = colors[s]);
      lower = upper;
    }
  }

  @override
  bool shouldRepaint(_StackedAreaPainter old) =>
      old.windows != windows ||
      old.layout.plotWidth != layout.plotWidth ||
      old.colors.first != colors.first;
}
