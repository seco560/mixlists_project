import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/text_styles.dart' show metaTextStyle;

class AlbumArtHistogramEntry {
  const AlbumArtHistogramEntry({
    required this.imageUrl,
    required this.tooltip,
    this.onTap,
  });

  final String? imageUrl;
  final String tooltip;

  final VoidCallback? onTap;
}

/// Album-art counterpart to `YearHistogramChart`: each year is a block of
/// cover art, wrapped into sub-columns of at most [_maxRowsPerColumn] so a
/// year with lots of entries grows sideways instead of forcing a long
/// vertical scroll. Entries fill column-major (top-to-bottom within a
/// sub-column, then start the next sub-column to the right), preserving
/// whatever chronological order [entriesByYear] already puts them in.
/// Only renders years present as keys in [entriesByYear].
class YearAlbumArtHistogram extends StatefulWidget {
  const YearAlbumArtHistogram({super.key, required this.entriesByYear});

  final Map<int, List<AlbumArtHistogramEntry>> entriesByYear;

  static const _maxRowsPerColumn = 6;
  static const _thumbnailSize = 48.0;

  /// Uniform spacing between grid items themselves -- both the vertical
  /// gap within a sub-column and the horizontal gap between sub-columns
  /// of the same year, so the grid reads as one evenly-spaced unit.
  static const _gridItemSpacing = 6.0;

  /// Total width of the vertical divider between years (and bookending
  /// the first/last year) -- deliberately larger than [_gridItemSpacing]
  /// so a year's sub-columns still read as one group and the divider
  /// line itself gets breathing room on both sides.
  static const _yearDividerWidth = 24.0;

  /// Fixed height for the year-label row (rather than however tall the
  /// text happens to render) so the horizontal divider line has a known,
  /// consistent distance from the bottom to sit at across every year --
  /// see the `Positioned` divider in `_YearAlbumArtHistogramState.build`.
  static const _yearLabelHeight = 20.0;
  static const _labelGap = 6.0;

  @override
  State<YearAlbumArtHistogram> createState() => _YearAlbumArtHistogramState();
}

class _YearAlbumArtHistogramState extends State<YearAlbumArtHistogram> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesByYear = widget.entriesByYear;
    if (entriesByYear.isEmpty) return const SizedBox.shrink();

    final years = entriesByYear.keys.toList()..sort();

    const divider = VerticalDivider(
      width: YearAlbumArtHistogram._yearDividerWidth,
      thickness: 1,
      color: Colors.blueGrey,
    );

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        // Stack so one continuous horizontal line can be drawn across the
        // whole width, on top of the per-year content underneath it,
        // rather than a separate short line per year block.
        child: Stack(
          children: [
            // IntrinsicHeight so VerticalDivider (which otherwise wants
            // to fill an already-bounded height) gets a real height to
            // fill, sized to the tallest year block.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  divider,
                  for (var i = 0; i < years.length; i++) ...[
                    if (i > 0) divider,
                    // Stretched to the full (intrinsic) row height by the
                    // Row above so the divider has something to fill --
                    // Align keeps the block's own content bottom-aligned
                    // within that space, same as before.
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _YearArtBlock(
                        year: years[i],
                        entries: entriesByYear[years[i]] ?? const [],
                        thumbnailSize: YearAlbumArtHistogram._thumbnailSize,
                        gridItemSpacing: YearAlbumArtHistogram._gridItemSpacing,
                        maxRowsPerColumn: YearAlbumArtHistogram._maxRowsPerColumn,
                      ),
                    ),
                  ],
                  divider,
                ],
              ),
            ),
            // Every year block is bottom-aligned and its trailing
            // (gap + fixed-height label) section is the same height for
            // all of them, so this sits at a consistent distance from
            // the bottom regardless of how tall any given year's art is.
            const Positioned(
              left: 0,
              right: 0,
              bottom: YearAlbumArtHistogram._yearLabelHeight +
                  YearAlbumArtHistogram._labelGap / 2,
              child: Divider(height: 1, thickness: 1, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearArtBlock extends StatelessWidget {
  const _YearArtBlock({
    required this.year,
    required this.entries,
    required this.thumbnailSize,
    required this.gridItemSpacing,
    required this.maxRowsPerColumn,
  });

  final int year;
  final List<AlbumArtHistogramEntry> entries;
  final double thumbnailSize;
  final double gridItemSpacing;
  final int maxRowsPerColumn;

  List<List<AlbumArtHistogramEntry>> get _subColumns {
    if (entries.isEmpty) return const [[]];
    return [
      for (var i = 0; i < entries.length; i += maxRowsPerColumn)
        entries.sublist(
          i,
          i + maxRowsPerColumn > entries.length
              ? entries.length
              : i + maxRowsPerColumn,
        ),
    ];
  }

  static const _yearTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    final subColumns = _subColumns;
    // IntrinsicWidth so the Divider below (which otherwise wants to fill
    // unbounded width, since this Column sits in an Align with no width
    // constraint of its own) gets a real width to stretch across, sized
    // to the block's own content.
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${entries.length}', style: metaTextStyle),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            // A year's last sub-column can be shorter than the others (its
            // entry count isn't always a multiple of maxRowsPerColumn) --
            // bottom-align so it settles to the floor like the rest,
            // rather than floating at the top with a gap underneath.
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < subColumns.length; i++) ...[
                if (i > 0) SizedBox(width: gridItemSpacing),
                _ArtSubColumn(
                  entries: subColumns[i],
                  thumbnailSize: thumbnailSize,
                  spacing: gridItemSpacing,
                ),
              ],
            ],
          ),
          const SizedBox(height: YearAlbumArtHistogram._labelGap),
          SizedBox(
            height: YearAlbumArtHistogram._yearLabelHeight,
            child: Center(child: Text('$year', style: _yearTextStyle)),
          ),
        ],
      ),
    );
  }
}

class _ArtSubColumn extends StatelessWidget {
  const _ArtSubColumn({
    required this.entries,
    required this.thumbnailSize,
    required this.spacing,
  });

  final List<AlbumArtHistogramEntry> entries;
  final double thumbnailSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: thumbnailSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Tooltip(
                message: entry.tooltip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  mouseCursor: entry.onTap == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  onTap: entry.onTap,
                  child: AlbumArtThumbnail(
                    imageUrl: entry.imageUrl,
                    size: thumbnailSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
