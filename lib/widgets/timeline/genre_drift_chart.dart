import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// Heatmap of [TasteTimeline.genreBands] shares: one row per genre family
/// (expandable into its genres), one cell per window of mixlists.
class GenreDriftChart extends StatefulWidget {
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

  @override
  State<GenreDriftChart> createState() => _GenreDriftChartState();
}

/// A heatmap row: a family's summed bands, or a single band/"other".
class _GenreRow {
  const _GenreRow({
    required this.label,
    required this.labels,
    this.family,
    this.isChild = false,
  });

  final String label;

  /// Band labels summed into this row's shares.
  final List<String> labels;

  /// Set on an expandable family row.
  final String? family;
  final bool isChild;

  double shareIn(GenreWindow window) =>
      labels.fold(0.0, (sum, l) => sum + (window.shares[l] ?? 0));
}

class _GenreDriftChartState extends State<GenreDriftChart> {
  final _expanded = <String>{};

  /// Families in stacking order (heaviest first), each with its bands.
  Map<String, List<GenreBand>> get _families {
    final families = <String, List<GenreBand>>{};
    for (final band in widget.bands) {
      families.putIfAbsent(band.family, () => []).add(band);
    }
    return families;
  }

  List<_GenreRow> _rows(Map<String, List<GenreBand>> families) {
    return [
      for (final MapEntry(key: family, value: members) in families.entries)
        if (members.length == 1)
          _GenreRow(label: members.single.label, labels: [members.single.label])
        else ...[
          _GenreRow(
            label: family,
            labels: [for (final m in members) m.label],
            family: family,
          ),
          if (_expanded.contains(family))
            for (final m in members)
              _GenreRow(label: m.label, labels: [m.label], isChild: true),
        ],
      const _GenreRow(
        label: TasteTimeline.otherGenre,
        labels: [TasteTimeline.otherGenre],
      ),
    ];
  }

  void _toggle(String family) => setState(() {
    if (!_expanded.remove(family)) _expanded.add(family);
  });

  @override
  Widget build(BuildContext context) {
    final withData = widget.windows.where((w) => w.shares.isNotEmpty).toList();
    if (widget.bands.isEmpty || withData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No genre data yet.', style: metaTextStyle),
      );
    }

    final families = _families;
    final expandable = [
      for (final e in families.entries)
        if (e.value.length > 1) e.key,
    ];
    final allExpanded = _expanded.length == expandable.length;
    final rows = _rows(families);
    // One scale for every row (a family row bounds its genres), so a family
    // and its genres compare honestly.
    final maxShare = [
      for (final row in rows)
        for (final w in withData) row.shareIn(w),
    ].fold(0.0, max);
    final windowSize =
        widget.windows.first.lastPosition -
        widget.windows.first.firstPosition +
        1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Share of album-artist genres per group of $windowSize '
                '${widget.playlistNounPluralLower}, by genre family. '
                'Tap a family to see its genres.',
                style: metaTextStyle,
              ),
              if (expandable.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    allExpanded
                        ? _expanded.clear()
                        : _expanded.addAll(expandable);
                  }),
                  icon: Icon(
                    allExpanded ? Icons.unfold_less : Icons.unfold_more,
                    size: 18,
                  ),
                  label: Text(allExpanded ? 'Collapse all' : 'Expand all'),
                ),
              _ScaleLegend(maxShare: maxShare),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = TimelineLayout.fromWidth(
              widget.points.length,
              constraints.maxWidth,
            );
            return Column(
              children: [
                for (final row in rows)
                  _HeatmapRow(
                    key: ValueKey('${row.isChild}:${row.label}'),
                    row: row,
                    windows: withData,
                    layout: layout,
                    maxShare: maxShare,
                    isExpanded: _expanded.contains(row.family),
                    onTap: row.family == null
                        ? null
                        : () => _toggle(row.family!),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 2),
        TimelineXAxis(points: widget.points),
      ],
    );
  }
}

/// Lerp from an empty cell to full primary; square root so small shares
/// still register next to a dominant family.
Color _cellColor(ColorScheme scheme, double t) => Color.lerp(
  scheme.surfaceContainerHighest,
  scheme.primary,
  sqrt(t.clamp(0.0, 1.0)),
)!;

class _HeatmapRow extends StatelessWidget {
  const _HeatmapRow({
    super.key,
    required this.row,
    required this.windows,
    required this.layout,
    required this.maxShare,
    required this.isExpanded,
    this.onTap,
  });

  final _GenreRow row;
  final List<GenreWindow> windows;
  final TimelineLayout layout;
  final double maxShare;
  final bool isExpanded;
  final VoidCallback? onTap;

  static const _height = 24.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFamily = row.family != null;
    final labelStyle = metaTextStyle.copyWith(
      fontWeight: isFamily ? FontWeight.w700 : null,
      color: row.isChild ? scheme.onSurfaceVariant : null,
    );
    return InkWell(
      mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onTap: onTap,
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            SizedBox(
              width: TimelineLayout.gutterWidth,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        row.label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: labelStyle,
                      ),
                    ),
                    if (isFamily)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: layout.plotWidth,
              height: _height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RowPainter(
                        row: row,
                        windows: windows,
                        layout: layout,
                        maxShare: maxShare,
                        scheme: scheme,
                      ),
                    ),
                  ),
                  for (final window in windows)
                    Positioned(
                      left: (window.firstPosition - 1) * layout.step,
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
        ),
      ),
    );
  }

  String _tooltip(GenreWindow window) {
    String pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
    final lines = [
      '${row.label} · ${pct(row.shareIn(window))}',
      '#${window.firstPosition}–#${window.lastPosition}',
    ];
    if (row.family != null) {
      final members =
          [
              for (final l in row.labels) (l, window.shares[l] ?? 0),
            ].where((m) => m.$2 >= 0.005).toList()
            ..sort((a, b) => b.$2.compareTo(a.$2));
      lines.addAll([for (final (l, v) in members) '  $l ${pct(v)}']);
    }
    return lines.join('\n');
  }
}

class _RowPainter extends CustomPainter {
  _RowPainter({
    required this.row,
    required this.windows,
    required this.layout,
    required this.maxShare,
    required this.scheme,
  });

  final _GenreRow row;
  final List<GenreWindow> windows;
  final TimelineLayout layout;
  final double maxShare;
  final ColorScheme scheme;

  static const _gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final window in windows) {
      final share = row.shareIn(window);
      final t = maxShare <= 0 ? 0.0 : share / maxShare;
      final left = (window.firstPosition - 1) * layout.step + _gap / 2;
      final width =
          (window.lastPosition - window.firstPosition + 1) * layout.step - _gap;
      if (width <= 0) continue;
      final rect = Rect.fromLTWH(left, _gap / 2, width, size.height - _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = _cellColor(scheme, t),
      );

      final percent = (share * 100).round();
      if (percent < 1 || width < 22) continue;
      final text = TextPainter(
        text: TextSpan(
          text: width >= 34 ? '$percent%' : '$percent',
          style: metaTextStyle.copyWith(
            fontSize: 11,
            color: sqrt(t) > 0.6 ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          rect.center.dx - text.width / 2,
          rect.center.dy - text.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_RowPainter old) =>
      old.row.labels != row.labels ||
      old.windows != windows ||
      old.layout.plotWidth != layout.plotWidth ||
      old.maxShare != maxShare ||
      old.scheme != scheme;
}

/// "0% ▭▭▭▭ N%" swatch strip explaining the cell shading.
class _ScaleLegend extends StatelessWidget {
  const _ScaleLegend({required this.maxShare});

  final double maxShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('0%', style: metaTextStyle),
        const SizedBox(width: 4),
        for (var i = 0; i <= 5; i++)
          Container(
            width: 14,
            height: 12,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _cellColor(scheme, (i / 5) * (i / 5)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 2),
        Text('${(maxShare * 100).round()}%', style: metaTextStyle),
      ],
    );
  }
}
