import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/timeline/artist_lifespan_list.dart';
import 'package:mixlists_project/widgets/timeline/timeline_layout.dart';

/// One of the artist's songs on a given mixlist.
class ArtistTimelineSong {
  const ArtistTimelineSong({
    required this.songId,
    required this.songName,
    required this.albumCoverImageURL,
  });

  final int songId;
  final String songName;
  final String? albumCoverImageURL;
}

/// One artist's lifespan row from the Timelines screen, blown up for the
/// artist page: every mixlist under the filter on the x-axis, and small
/// album art per mixlist the artist is on (hover for songs, tap to open).
class ArtistTimelineStrip extends StatelessWidget {
  const ArtistTimelineStrip({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.points,
    required this.songsByPosition,
    this.onSongTap,
    this.showArtistName = true,
    this.playlistNounSingularLower = 'mixlist',
    this.playlistNounPluralLower = 'mixlists',
  });

  final int artistId;
  final String artistName;

  /// Every mixlist under the filter, in position order.
  final List<TimelineMixlistPoint> points;

  /// Position -> the artist's songs on that mixlist (non-empty lists).
  final Map<int, List<ArtistTimelineSong>> songsByPosition;

  /// Called with the mixlist and its first song by this artist, so the
  /// mixlist can open scrolled to that song.
  final void Function(TimelineMixlistPoint point, ArtistTimelineSong song)?
  onSongTap;

  /// Off on the artist's own page: drops the name gutter so the plot spans
  /// the full width.
  final bool showArtistName;
  final String playlistNounSingularLower;
  final String playlistNounPluralLower;

  static const _height = 36.0;
  static const _artSize = 18.0;
  static const _maxTooltipSongs = 6;

  /// Matches [TimelineLayout.rightPadding] when there's no name gutter.
  static const _bareGutter = 16.0;

  @override
  Widget build(BuildContext context) {
    final positions = songsByPosition.keys.toList()..sort();
    if (positions.isEmpty || points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Not on any $playlistNounPluralLower under this filter.',
          style: metaTextStyle,
        ),
      );
    }

    final lifespan = ArtistLifespan(
      artistId: artistId,
      name: artistName,
      positions: positions,
      appearanceCount: songsByPosition.values.fold(0, (a, b) => a + b.length),
    );
    final pointByPosition = {for (final p in points) p.position: p};
    final first = pointByPosition[lifespan.firstPosition]!;
    final last = pointByPosition[lifespan.lastPosition]!;
    final colors = Theme.of(context).colorScheme;
    final gutter = showArtistName ? TimelineLayout.gutterWidth : _bareGutter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            positions.length == 1
                ? 'Only on #${first.position} ${first.mixlist.title} '
                      '(${_date(first)}).'
                : 'On ${positions.length} of ${points.length} '
                      '$playlistNounPluralLower, from #${first.position} '
                      '(${_date(first)}) to #${last.position} (${_date(last)}).',
            style: metaTextStyle,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = TimelineLayout.fromWidth(
              points.length,
              constraints.maxWidth,
              gutter: gutter,
            );
            return Row(
              children: [
                SizedBox(
                  width: gutter,
                  child: !showArtistName
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          // Two lines at most, so the row height (and the art
                          // centered in it) stays fixed.
                          child: Text(
                            artistName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: metaTextStyle.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: layout.plotWidth,
                  height: _height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LifespanPainter(
                            lifespan: lifespan,
                            layout: layout,
                            lineColor: colors.primary.withValues(alpha: 0.4),
                            dotColor: colors.primary,
                            showDots: false,
                          ),
                        ),
                      ),
                      for (final position in positions)
                        Positioned(
                          left: layout.xFor(position) - _artSize / 2 - 1,
                          top: (_height - _artSize) / 2 - 1,
                          child: _art(
                            context,
                            pointByPosition[position]!,
                            songsByPosition[position]!,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        TimelineXAxis(points: points, gutter: gutter),
      ],
    );
  }

  static String _date(TimelineMixlistPoint p) =>
      p.mixlist.dateCreated.split('T')[0];

  String _tooltip(TimelineMixlistPoint point, List<ArtistTimelineSong> songs) {
    return [
      '#${point.position} ${point.mixlist.title} · ${_date(point)}',
      for (final song in songs.take(_maxTooltipSongs)) '♪ ${song.songName}',
      if (songs.length > _maxTooltipSongs)
        '+${songs.length - _maxTooltipSongs} more',
    ].join('\n');
  }

  Widget _art(
    BuildContext context,
    TimelineMixlistPoint point,
    List<ArtistTimelineSong> songs,
  ) {
    final onTap = onSongTap;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _tooltip(point, songs),
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap == null ? null : () => onTap(point, songs.first),
          // Surface ring keeps neighbouring covers apart where they overlap.
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: AlbumArtThumbnail(
              imageUrl: songs.first.albumCoverImageURL,
              size: _artSize,
              borderRadius: 3,
            ),
          ),
        ),
      ),
    );
  }
}
