import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/explicit_badge.dart';
import 'package:mixlists_project/widgets/shared/mixlist_count_chip.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

class TrackTile extends StatefulWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.durationLabel,
    required this.otherMixlists,
    required this.mixlistCreationDate,
    this.isHighlighted = false,
  });

  final MixlistTrack track;
  final String durationLabel;
  final List<MixlistSummary> otherMixlists;
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

  String get _dateAdded => widget.track.dateAdded.split('T')[0];

  String get _timeAdded => widget.track.dateAdded.split('T')[1].split('Z')[0];

  /// Tracks added after the mixlist's creation day stand out in primary.
  bool get _addedLater => widget.mixlistCreationDate != _dateAdded;

  Widget _buildDateAdded({required double fontSize, bool withTime = false}) {
    final scheme = Theme.of(context).colorScheme;
    final dateStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: _addedLater ? FontWeight.w700 : null,
      color: _addedLater ? scheme.primary : scheme.onSurfaceVariant,
    );
    return Tooltip(
      message: _addedLater
          ? 'Added after the playlist was created'
          : 'Added on the day the playlist was created',
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          Text(_dateAdded, style: dateStyle),
          if (withTime)
            Text(
              _timeAdded,
              style: TextStyle(
                fontSize: fontSize,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(MixlistTrack track, {required bool isCompact}) {
    final style = TextStyle(fontSize: isCompact ? 15 : 18, fontWeight: .bold);
    return Row(
      mainAxisSize: .min,
      children: [
        Text('${track.position}) ', style: style),
        Flexible(
          child: HoverableLink(
            text: track.songName,
            onTap: () => openSongById(context, track.songId),
            style: style,
            overflow: .ellipsis,
            maxLines: 1,
            verticalPadding: 2,
          ),
        ),
        if (track.isExplicit == true) ...[
          const SizedBox(width: 6),
          const ExplicitBadge(),
        ],
      ],
    );
  }

  LinkLine _buildLinks(MixlistTrack track, {required bool isCompact}) {
    return LinkLine(
      singleLine: isCompact,
      verticalPadding: 2,
      parts: [
        (track.artistNames, () => openArtistById(context, track.artistId)),
        (track.albumName, () => openAlbumById(context, track.albumId)),
      ],
    );
  }

  Widget _buildWideTile(MixlistTrack track, bool hasDuplicates) {
    return ListTile(
      leading: AlbumArtThumbnail(imageUrl: track.albumCoverImageURL, size: 44),
      title: _buildTitle(track, isCompact: false),
      subtitle: _buildLinks(track, isCompact: false),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          if (hasDuplicates)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MixlistCountChip(
                label: 'Also on ${widget.otherMixlists.length}',
                isExpanded: _isExpanded,
                onPressed: _toggleExpanded,
              ),
            ),
          Text(
            widget.durationLabel,
            style: const TextStyle(fontSize: 18, fontWeight: .bold),
          ),
          const SizedBox(width: 12),
          _buildDateAdded(fontSize: 12, withTime: true),
        ],
      ),
    );
  }

  /// Condensed mobile layout -- fixed-height single-line title/subtitle,
  /// duplicate-mixlist badge moved onto the album art instead of trailing.
  Widget _buildCompactTile(MixlistTrack track, bool hasDuplicates) {
    final art = AlbumArtThumbnail(imageUrl: track.albumCoverImageURL, size: 44);
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
      subtitle: _buildLinks(track, isCompact: true),
      trailing: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          Text(
            widget.durationLabel,
            style: const TextStyle(fontSize: 15, fontWeight: .bold),
          ),
          _buildDateAdded(fontSize: 11),
        ],
      ),
    );
  }

  Widget _buildOtherMixlistsPanel(
    MixlistTrack track, {
    required bool isCompact,
  }) {
    return SizeTransition(
      sizeFactor: _revealAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: isCompact ? .centerLeft : .centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? 280 : 360),
            child: OtherMixlistsList(
              mixlists: widget.otherMixlists,
              onTap: (mixlistId) => openMixlistById(
                context,
                mixlistId,
                highlightSongId: track.songId,
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
