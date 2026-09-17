import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class SongMixlistTile extends StatefulWidget {
  const SongMixlistTile({
    super.key,
    required this.songId,
    required this.title,
    required this.subtitle,
    required this.leadingImageUrl,
    required this.mixlists,
    required this.onOpenMixlist,
  });

  final int songId;
  final String title;
  final Widget subtitle;
  final String? leadingImageUrl;
  final List<MixlistSummary> mixlists;
  final void Function(int mixlistId, int songId) onOpenMixlist;

  @override
  State<SongMixlistTile> createState() => _SongMixlistTileState();
}

class _SongMixlistTileState extends State<SongMixlistTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mixlists = widget.mixlists;
    final hasSingleMixlist = mixlists.length == 1;

    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          leading: AlbumArtThumbnail(
            imageUrl: widget.leadingImageUrl,
            size: 48,
            borderRadius: 0,
          ),
          title: Text(widget.title, style: titleTextStyle),
          subtitle: widget.subtitle,
          trailing: hasSingleMixlist
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .end,
                          children: [
                            Text(
                              mixlists.first.title,
                              style: subtitleTextStyle,
                              textAlign: .right,
                              overflow: .ellipsis,
                            ),
                            Text(
                              (mixlists.first.dateCreated ?? '').split('T')[0],
                              style: metaTextStyle,
                              textAlign: .right,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                )
              : ActionChip(
                  label: Text('${mixlists.length} mixlists'),
                  onPressed: _toggleExpanded,
                ),
          onTap: hasSingleMixlist
              ? () => widget.onOpenMixlist(mixlists.first.id, widget.songId)
              : _toggleExpanded,
        ),
        if (!hasSingleMixlist)
          Align(
            alignment: .topRight,
            child: SizeTransition(
              sizeFactor: _revealAnimation,
              alignment: .bottomLeft,
              child: ScaleTransition(
                scale: _popAnimation,
                alignment: .topRight,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: mixlists
                          .map(
                            (mixlist) => MixlistRow(
                              mixlist: mixlist,
                              onTap: () => widget.onOpenMixlist(
                                mixlist.id,
                                widget.songId,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MixlistRow extends StatelessWidget {
  const MixlistRow({super.key, required this.mixlist, required this.onTap});

  final MixlistSummary mixlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: .compact,
      title: Text(
        mixlist.title,
        style: compactTitleTextStyle,
        textAlign: .right,
      ),
      subtitle: Text(
        (mixlist.dateCreated ?? '').split('T')[0],
        style: metaTextStyle,
        textAlign: .right,
      ),
      onTap: onTap,
    );
  }
}
