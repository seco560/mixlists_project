import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/mixlist_summary.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// This one you may want to modify to behave like the one that's in use
/// over in the main mixlists detail screen i.e. with the nice little
/// pop-down animation.
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
  final String leadingImageUrl;
  final List<MixlistSummary> mixlists;
  final void Function(int mixlistId, int songId) onOpenMixlist;

  @override
  State<SongMixlistTile> createState() => _SongMixlistTileState();
}

class _SongMixlistTileState extends State<SongMixlistTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final mixlists = widget.mixlists;
    final hasSingleMixlist = mixlists.length == 1;

    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          leading: CachedNetworkImage(
            imageUrl: widget.leadingImageUrl,
            width: 48,
            height: 48,
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
                              (mixlists.first.dateCreated ?? '').split(
                                'T',
                              )[0],
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
              : Chip(label: Text('${mixlists.length} mixlists')),
          onTap: hasSingleMixlist
              ? () => widget.onOpenMixlist(mixlists.first.id, widget.songId)
              : () => setState(() => _isExpanded = !_isExpanded),
        ),
        if (!hasSingleMixlist && _isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: .start,
              children: mixlists
                  .map(
                    (mixlist) => MixlistRow(
                      mixlist: mixlist,
                      onTap: () =>
                          widget.onOpenMixlist(mixlist.id, widget.songId),
                    ),
                  )
                  .toList(),
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
