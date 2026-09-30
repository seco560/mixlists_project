import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/explicit_badge.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/widgets/shared/mixlist_count_chip.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// A song plus the mixlists it's on, for album/artist/search lists. Same
/// interactions as a mixlist's [TrackTile]: the title opens the song, a
/// single mixlist opens on tap, several expand from a [MixlistCountChip].
class SongMixlistTile extends StatefulWidget {
  const SongMixlistTile({
    super.key,
    required this.songId,
    required this.title,
    required this.subtitle,
    required this.leadingImageUrl,
    required this.mixlists,
    this.isExplicit = false,
  });

  final int songId;
  final String title;
  final Widget subtitle;
  final String? leadingImageUrl;
  final List<MixlistSummary> mixlists;
  final bool isExplicit;

  @override
  State<SongMixlistTile> createState() => _SongMixlistTileState();
}

class _SongMixlistTileState extends State<SongMixlistTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _revealAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
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

  void _openMixlist(int mixlistId) =>
      openMixlistById(context, mixlistId, highlightSongId: widget.songId);

  @override
  Widget build(BuildContext context) {
    final mixlists = widget.mixlists;
    final hasSingleMixlist = mixlists.length == 1;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: .start,
      children: [
        // Cap the trailing mixlist so narrow screens abridge its name instead
        // of squeezing the song info into a one-word-wide column.
        LayoutBuilder(
          builder: (context, constraints) => ListTile(
            leading: AlbumArtThumbnail(
              imageUrl: widget.leadingImageUrl,
              size: 48,
            ),
            title: Row(
              mainAxisSize: .min,
              children: [
                Flexible(
                  child: HoverableLink(
                    text: widget.title,
                    onTap: () => openSongById(context, widget.songId),
                    style: titleTextStyle,
                    overflow: .ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.isExplicit) ...[
                  const SizedBox(width: 6),
                  const ExplicitBadge(),
                ],
              ],
            ),
            subtitle: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: .ellipsis,
              softWrap: false,
              child: widget.subtitle,
            ),
            trailing: hasSingleMixlist
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth * 0.35).clamp(0, 260),
                    ),
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
                                maxLines: 1,
                                overflow: .ellipsis,
                              ),
                              Text(
                                (mixlists.first.dateCreated ?? '').split(
                                  'T',
                                )[0],
                                style: metaTextStyle.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                textAlign: .right,
                                maxLines: 1,
                                softWrap: false,
                                overflow: .fade,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  )
                : MixlistCountChip(
                    label:
                        '${mixlists.length} '
                        '${getIt<MixlistFilterController>().value.playlistNounPluralLower}',
                    isExpanded: _isExpanded,
                    onPressed: _toggleExpanded,
                  ),
            onTap: hasSingleMixlist
                ? () => _openMixlist(mixlists.first.id)
                : _toggleExpanded,
          ),
        ),
        if (!hasSingleMixlist)
          SizeTransition(
            sizeFactor: _revealAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Align(
                alignment: .centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: OtherMixlistsList(
                    header: 'Appears in',
                    mixlists: mixlists,
                    onTap: _openMixlist,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
