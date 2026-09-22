import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

enum LifespanSort { firstAppearance, span, mixlistCount }

/// One row per recurring artist: a line from first to last appearance with
/// a dot on every mixlist it's on, on the shared [TimelineLayout] scale.
class ArtistLifespanList extends StatefulWidget {
  const ArtistLifespanList({
    super.key,
    required this.points,
    required this.lifespans,
    this.onArtistTap,
    this.playlistNounPluralLower = 'mixlists',
  });

  final List<TimelineMixlistPoint> points;

  /// Ordered by first appearance, as [TasteTimeline] builds them.
  final List<ArtistLifespan> lifespans;
  final void Function(ArtistLifespan lifespan)? onArtistTap;
  final String playlistNounPluralLower;

  static const collapsedCount = 25;

  @override
  State<ArtistLifespanList> createState() => _ArtistLifespanListState();
}

class _ArtistLifespanListState extends State<ArtistLifespanList> {
  LifespanSort _sort = LifespanSort.firstAppearance;
  bool _expanded = false;

  List<ArtistLifespan> get _sorted {
    final list = [...widget.lifespans];
    switch (_sort) {
      case LifespanSort.firstAppearance:
        break;
      case LifespanSort.span:
        list.sort((a, b) {
          final bySpan = b.span.compareTo(a.span);
          return bySpan != 0
              ? bySpan
              : a.firstPosition.compareTo(b.firstPosition);
        });
      case LifespanSort.mixlistCount:
        list.sort((a, b) {
          final byCount = b.positions.length.compareTo(a.positions.length);
          return byCount != 0
              ? byCount
              : a.firstPosition.compareTo(b.firstPosition);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final noun = widget.playlistNounPluralLower;
    if (widget.lifespans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No artist appears on ${TasteTimeline.minArtistMixlists}+ $noun yet.',
          style: metaTextStyle,
        ),
      );
    }

    final sorted = _sorted;
    final shown = _expanded
        ? sorted
        : sorted.take(ArtistLifespanList.collapsedCount).toList();
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${widget.lifespans.length} artists on '
                '${TasteTimeline.minArtistMixlists}+ $noun, from first to '
                'last appearance.',
                style: metaTextStyle,
              ),
              SegmentedButton<LifespanSort>(
                segments: const [
                  ButtonSegment(
                    value: LifespanSort.firstAppearance,
                    label: Text('First seen'),
                  ),
                  ButtonSegment(
                    value: LifespanSort.span,
                    label: Text('Longest span'),
                  ),
                  ButtonSegment(
                    value: LifespanSort.mixlistCount,
                    label: Text('Most frequent'),
                  ),
                ],
                selected: {_sort},
                onSelectionChanged: (s) => setState(() => _sort = s.first),
              ),
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
                for (final lifespan in shown)
                  _LifespanRow(
                    key: ValueKey(lifespan.artistId),
                    lifespan: lifespan,
                    layout: layout,
                    lineColor: colors.primary.withValues(alpha: 0.4),
                    dotColor: colors.primary,
                    noun: noun,
                    onTap: widget.onArtistTap == null
                        ? null
                        : () => widget.onArtistTap!(lifespan),
                  ),
              ],
            );
          },
        ),
        TimelineXAxis(points: widget.points),
        if (sorted.length > ArtistLifespanList.collapsedCount)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show fewer' : 'Show all ${sorted.length}',
              ),
            ),
          ),
      ],
    );
  }
}

class _LifespanRow extends StatelessWidget {
  const _LifespanRow({
    super.key,
    required this.lifespan,
    required this.layout,
    required this.lineColor,
    required this.dotColor,
    required this.noun,
    this.onTap,
  });

  final ArtistLifespan lifespan;
  final TimelineLayout layout;
  final Color lineColor;
  final Color dotColor;
  final String noun;
  final VoidCallback? onTap;

  static const _height = 22.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${lifespan.name}\n#${lifespan.firstPosition} → '
          '#${lifespan.lastPosition} · ${lifespan.positions.length} $noun',
      child: InkWell(
        mouseCursor: onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              SizedBox(
                width: TimelineLayout.gutterWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    lifespan.name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: metaTextStyle,
                  ),
                ),
              ),
              SizedBox(
                width: layout.plotWidth,
                height: _height,
                child: CustomPaint(
                  painter: _LifespanPainter(
                    lifespan: lifespan,
                    layout: layout,
                    lineColor: lineColor,
                    dotColor: dotColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LifespanPainter extends CustomPainter {
  _LifespanPainter({
    required this.lifespan,
    required this.layout,
    required this.lineColor,
    required this.dotColor,
  });

  final ArtistLifespan lifespan;
  final TimelineLayout layout;
  final Color lineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(layout.xFor(lifespan.firstPosition), y),
      Offset(layout.xFor(lifespan.lastPosition), y),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final radius = (layout.step / 2.5).clamp(1.5, 3.5);
    final dotPaint = Paint()..color = dotColor;
    for (final position in lifespan.positions) {
      canvas.drawCircle(Offset(layout.xFor(position), y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LifespanPainter old) =>
      old.lifespan != lifespan ||
      old.layout.plotWidth != layout.plotWidth ||
      old.dotColor != dotColor;
}
