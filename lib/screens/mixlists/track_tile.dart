import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/explicit_badge.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class TrackTile extends StatefulWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.durationLabel,
    required this.otherMixlists,
    required this.onOtherMixlistTap,
    required this.mixlistCreationDate,
    this.isHighlighted = false,
  });

  final MixlistTrack track;
  final String durationLabel;
  final List<MixlistSummary> otherMixlists;
  final void Function(int mixlistId, int songId) onOtherMixlistTap;
  final String mixlistCreationDate;

  final bool isHighlighted;

  @override
  State<TrackTile> createState() => _TrackTileState();
}

/// Holds the sacred keys to the highlight animation.
class _TrackTileState extends State<TrackTile> with TickerProviderStateMixin {
  static final _highlightRed = Colors.red.withValues(alpha: 0.35);
  static final _highlightYellow = Colors.yellow.withValues(alpha: 0.4);
  static final _highlightGreen = Colors.green.withValues(alpha: 0.3);

  late final AnimationController _controller;
  AnimationController? _highlightController;
  Animation<Color?>? _highlightColorAnimation;

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
    if (widget.isHighlighted) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      _highlightController = controller;
      _highlightColorAnimation = TweenSequence<Color?>([
        TweenSequenceItem(
          tween: ColorTween(begin: Colors.transparent, end: _highlightRed),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: _highlightRed, end: _highlightYellow),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ColorTween(begin: _highlightYellow, end: _highlightGreen),
          weight: 1,
        ),
      ]).animate(controller);
      controller.forward();
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _highlightController?.dispose();
    super.dispose();
  }

  Future<void> _openArtist(int artistId) async {
    final overview = await getIt<MusicLibraryRepository>()
        .getArtistOverviewById(artistId);
    if (!mounted || overview == null) return;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.artist,
        entityId: overview.id,
        title: overview.name,
        mosaicUrls: [for (final a in overview.albums.take(4)) a.coverImageURL],
      ),
      builder: (context) => ArtistDetailScreen(artist: overview),
    );
  }

  Future<void> _openAlbum(int albumId) async {
    final overview = await getIt<MusicLibraryRepository>().getAlbumOverviewById(
      albumId,
    );
    if (!mounted || overview == null) return;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.album,
        entityId: overview.id,
        title: overview.name,
        subtitle: overview.artistName,
        imageUrl: overview.coverImageURL,
      ),
      builder: (context) => AlbumDetailScreen(album: overview),
    );
  }

  Widget _wrapWithHighlight(Widget child) {
    final animation = _highlightColorAnimation;
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => ColoredBox(
        color: animation.value ?? Colors.transparent,
        child: child,
      ),
      child: child,
    );
  }

  Widget _buildTitle(MixlistTrack track, {required bool isCompact}) {
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Text(
            "${track.position}) ${track.songName}",
            style: TextStyle(fontSize: isCompact ? 15 : 18, fontWeight: .bold),
            overflow: .ellipsis,
          ),
        ),
        if (track.isExplicit == true) ...[
          const SizedBox(width: 6),
          const ExplicitBadge(),
        ],
      ],
    );
  }

  /// Desktop/wide layout -- unchanged from before mobile/web made
  /// condensing necessary.
  Widget _buildWideTile(MixlistTrack track, bool hasDuplicates) {
    return ListTile(
      title: _buildTitle(track, isCompact: false),
      subtitle: Wrap(
        crossAxisAlignment: .center,
        children: [
          HoverableLink(
            text: track.artistNames,
            onTap: () => _openArtist(track.artistId),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('•', style: TextStyle(fontSize: 14, fontWeight: .w500)),
          ),
          HoverableLink(
            text: track.albumName,
            onTap: () => _openAlbum(track.albumId),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (hasDuplicates)
            Padding(
              padding: .only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.repeat, size: 16),
                label: Text('${widget.otherMixlists.length}'),
                onPressed: _toggleExpanded,
              ),
            ),
          Text(
            widget.durationLabel,
            style: TextStyle(fontSize: 20, fontWeight: .bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Text(
                  widget.track.dateAdded.split("T")[0],
                  style: TextStyle(
                    fontSize: 12.0,
                    color:
                        widget.mixlistCreationDate ==
                            widget.track.dateAdded.split("T")[0]
                        ? Colors.green.shade400
                        : Colors.blue.shade700,
                  ),
                ),
                Text(
                  widget.track.dateAdded.split("T")[1].split("Z")[0],
                  style: TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: AlbumArtThumbnail(
        imageUrl: track.albumCoverImageURL,
        size: 50,
        borderRadius: 0,
      ),
    );
  }

  /// Condensed mobile layout -- fixed-height single-line title/subtitle,
  /// duplicate-mixlist badge moved onto the album art instead of trailing.
  Widget _buildCompactTile(MixlistTrack track, bool hasDuplicates) {
    final art = AlbumArtThumbnail(
      imageUrl: track.albumCoverImageURL,
      size: 44,
      borderRadius: 4,
    );
    return ListTile(
      leading: hasDuplicates
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _toggleExpanded,
                child: Badge(
                  label: Text('${widget.otherMixlists.length}'),
                  child: art,
                ),
              ),
            )
          : art,
      title: _buildTitle(track, isCompact: true),
      subtitle: Row(
        children: [
          Flexible(
            child: HoverableLink(
              text: track.artistNames,
              onTap: () => _openArtist(track.artistId),
              overflow: .ellipsis,
              maxLines: 1,
            ),
          ),
          const Text(' • ', style: TextStyle(fontSize: 12)),
          Flexible(
            child: HoverableLink(
              text: track.albumName,
              onTap: () => _openAlbum(track.albumId),
              overflow: .ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          Text(
            widget.durationLabel,
            style: TextStyle(fontSize: 15, fontWeight: .bold),
          ),
          Text(
            widget.track.dateAdded.split("T")[0],
            style: TextStyle(
              fontSize: 11.0,
              color:
                  widget.mixlistCreationDate ==
                      widget.track.dateAdded.split("T")[0]
                  ? Colors.green.shade400
                  : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMixlistsPanel(
    MixlistTrack track, {
    required bool isCompact,
  }) {
    return Align(
      alignment: .topRight,
      child: SizeTransition(
        sizeFactor: _revealAnimation,
        alignment: .bottomLeft,
        child: ScaleTransition(
          scale: _popAnimation,
          alignment: .topRight,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: isCompact ? .centerLeft : .centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 280 : 330),
                child: OtherMixlistsList(
                  mixlists: widget.otherMixlists,
                  onTap: (mixlistId) =>
                      widget.onOtherMixlistTap(mixlistId, track.songId),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final hasDuplicates = widget.otherMixlists.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < compactLayoutBreakpoint;
        return Column(
          crossAxisAlignment: .start,
          children: [
            _wrapWithHighlight(
              isCompact
                  ? _buildCompactTile(track, hasDuplicates)
                  : _buildWideTile(track, hasDuplicates),
            ),
            if (hasDuplicates)
              _buildOtherMixlistsPanel(track, isCompact: isCompact),
          ],
        );
      },
    );
  }
}
