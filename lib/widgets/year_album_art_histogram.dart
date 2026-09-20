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
/// cover art wrapped into sub-columns so a busy year grows sideways.
class YearAlbumArtHistogram extends StatefulWidget {
  const YearAlbumArtHistogram({super.key, required this.entriesByYear});

  final Map<int, List<AlbumArtHistogramEntry>> entriesByYear;

  static const _maxRowsPerColumn = 6;
  static const _thumbnailSize = 48.0;

  /// Gap between items within a sub-column and between sub-columns alike.
  static const _gridItemSpacing = 6.0;

  /// Wider than [_gridItemSpacing] so a year's sub-columns still read as
  /// one group, with room for the divider line itself.
  static const _yearDividerWidth = 24.0;

  /// Fixed so the divider (see `Positioned` below) sits at a consistent
  /// height across every year regardless of label text.
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
    );

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        // Stack so one continuous divider line can be drawn across the
        // whole width instead of a separate one per year block.
        child: Stack(
          children: [
            // Gives VerticalDivider a real (not unbounded) height to fill.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  divider,
                  for (var i = 0; i < years.length; i++) ...[
                    if (i > 0) divider,
                    // Row stretches this to full height; Align keeps the
                    // block's own content bottom-aligned within it.
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _YearArtBlock(
                        year: years[i],
                        entries: entriesByYear[years[i]] ?? const [],
                        thumbnailSize: YearAlbumArtHistogram._thumbnailSize,
                        gridItemSpacing: YearAlbumArtHistogram._gridItemSpacing,
                        maxRowsPerColumn:
                            YearAlbumArtHistogram._maxRowsPerColumn,
                      ),
                    ),
                  ],
                  divider,
                ],
              ),
            ),
            // Every block's trailing (gap + label) section is the same
            // fixed height, so this divider lands at a consistent depth.
            const Positioned(
              left: 0,
              right: 0,
              bottom:
                  YearAlbumArtHistogram._yearLabelHeight +
                  YearAlbumArtHistogram._labelGap / 2,
              child: Divider(height: 1, thickness: 1),
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
    // Gives the Divider below a real (not unbounded) width to stretch across.
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${entries.length}', style: metaTextStyle),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            // Bottom-align so a shorter last sub-column settles to the
            // floor like the rest instead of floating with a gap under it.
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
