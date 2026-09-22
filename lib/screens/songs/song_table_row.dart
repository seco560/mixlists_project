import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/screens/songs/song_detail_screen.dart';
import 'package:mixlists_project/screens/songs/song_table_cell.dart';
import 'package:mixlists_project/widgets/shared/explicit_badge.dart';

/// An [AllSongsScreen] row that expands in place to list the song's
/// mixlists (a one-hit wonder opens its mixlist directly). Callers MUST
/// key it with `ValueKey(song.id)`: rows live in an eager `Column`.
class SongTableRow extends StatefulWidget {
  const SongTableRow({
    super.key,
    required this.song,
    required this.widths,
    required this.rowNumber,
    required this.onOpenMixlist,
  });

  final SongOverview song;
  final List<double> widths;
  final int rowNumber;
  final void Function(int mixlistId, int songId) onOpenMixlist;

  @override
  State<SongTableRow> createState() => _SongTableRowState();
}

class _SongTableRowState extends State<SongTableRow>
    with SingleTickerProviderStateMixin {
  static const _nameTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const _countTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _revealAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<double> _popAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSongDetail() {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.song,
        entityId: widget.song.id,
        title: widget.song.name,
        subtitle: widget.song.artistNames,
        imageUrl: widget.song.albumCoverImageURL,
      ),
      builder: (context) => SongDetailScreen(song: widget.song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final widths = widget.widths;
    final isOneHitWonder = song.appearanceCount == 1;
    final totalRowWidth = widths.reduce((a, b) => a + b);

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: isOneHitWonder
          ? () => widget.onOpenMixlist(song.mixlists.first.id, song.id)
          : _toggleExpanded,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SongTableCell(
                width: widths[0],
                numeric: true,
                child: Text('${widget.rowNumber}', style: _countTextStyle),
              ),
              SongTableCell(
                width: widths[1],
                numeric: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: HoverableLink(
                        text: song.name,
                        onTap: _openSongDetail,
                        style: _nameTextStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (song.isExplicit == true) ...[
                      const SizedBox(width: 6),
                      const ExplicitBadge(),
                    ],
                  ],
                ),
              ),
              SongTableCell(
                width: widths[2],
                numeric: false,
                child: Text(
                  song.artistNames,
                  style: _countTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SongTableCell(
                width: widths[3],
                numeric: false,
                child: Text(
                  song.albumName,
                  style: _countTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SongTableCell(
                width: widths[4],
                numeric: true,
                child: Text('${song.appearanceCount}', style: _countTextStyle),
              ),
            ],
          ),
          if (!isOneHitWonder)
            Align(
              alignment: Alignment.topRight,
              child: SizeTransition(
                sizeFactor: _revealAnimation,
                alignment: Alignment.bottomLeft,
                child: ScaleTransition(
                  scale: _popAnimation,
                  alignment: Alignment.topRight,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    // Needs a concrete width: rows get unbounded
                    // width from the scrolling grid, so a bare Align
                    // would shrink and be centered by the Column.
                    child: SizedBox(
                      width: totalRowWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: OtherMixlistsList(
                            header: 'Appears in',
                            mixlists: song.mixlists,
                            onTap: (mixlistId) =>
                                widget.onOpenMixlist(mixlistId, song.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
