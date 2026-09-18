import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/screens/songs/song_table_cell.dart';

/// A single row in [AllSongsScreen]'s grid. Owns its own expand/collapse
/// state and animation (unlike Artists' stateless `_buildRow` helper)
/// because a one-hit wonder needs none of that -- tapping it opens its
/// one mixlist directly -- while a song with more than one appearance
/// needs to reveal the full list in place, right under its own row.
///
/// Callers MUST key this with `ValueKey(song.id)`: the parent renders
/// rows in a plain eagerly-built `Column`, not a `ListView.builder`, so
/// without an identity key a re-sort or filter reload could reconcile a
/// different song into an already-expanded row's position/State.
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

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final widths = widget.widths;
    final isOneHitWonder = song.appearanceCount == 1;
    final totalRowWidth = widths.reduce((a, b) => a + b);

    return InkWell(
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
                child: Text(
                  song.name,
                  style: _nameTextStyle,
                  overflow: TextOverflow.ellipsis,
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
                    // A concrete width is needed here (not just Align)
                    // because this row sits inside the grid's
                    // horizontally-scrolling body, which hands rows an
                    // unbounded width -- without an explicit anchor,
                    // Align has no extra space to work with and shrinks
                    // to its child, leaving the outer Column's default
                    // center alignment to (mis)place the whole panel.
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
