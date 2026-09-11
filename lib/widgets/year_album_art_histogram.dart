import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/text_styles.dart' show metaTextStyle;

class AlbumArtHistogramEntry {
  const AlbumArtHistogramEntry({
    required this.imageUrl,
    required this.tooltip,
    this.onTap,
  });

  final String imageUrl;
  final String tooltip;

  final VoidCallback? onTap;
}

/// The album-art counterpart to `YearHistogramChart`: instead of a solid
/// bar, each year is a column stacked with the cover art of the songs
/// added that year, so the chart reads as a grid of album art while still
/// being laid out as one column per year in a horizontally-scrollable row.
///
/// A year renders only if it's a key in [entriesByYear] -- an absent year
/// isn't shown at all, unlike `YearHistogramChart`, which always fills
/// gaps between the lowest and highest year with an empty bar. There's no
/// bar here to make a gap meaningful against, so it's on the caller to
/// decide whether gap years matter for what it's charting; if they do,
/// include them explicitly with an empty list (see
/// `ArtistDetailScreen._addedOverTimeEntries`).
///
/// There is no chart-level tooltip -- each thumbnail carries its own via
/// [AlbumArtHistogramEntry.tooltip].
class YearAlbumArtHistogram extends StatefulWidget {
  const YearAlbumArtHistogram({super.key, required this.entriesByYear});

  final Map<int, List<AlbumArtHistogramEntry>> entriesByYear;

  static const _columnWidth = 40.0;
  static const _thumbnailSize = 36.0;
  static const _thumbnailSpacing = 4.0;

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

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < years.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _YearArtColumn(
                year: years[i],
                entries: entriesByYear[years[i]] ?? const [],
                width: YearAlbumArtHistogram._columnWidth,
                thumbnailSize: YearAlbumArtHistogram._thumbnailSize,
                spacing: YearAlbumArtHistogram._thumbnailSpacing,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _YearArtColumn extends StatelessWidget {
  const _YearArtColumn({
    required this.year,
    required this.entries,
    required this.width,
    required this.thumbnailSize,
    required this.spacing,
  });

  final int year;
  final List<AlbumArtHistogramEntry> entries;
  final double width;
  final double thumbnailSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${entries.length}', style: metaTextStyle),
          const SizedBox(height: 4),
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
          Text('$year', style: metaTextStyle),
        ],
      ),
    );
  }
}
