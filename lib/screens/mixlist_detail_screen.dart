import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/mixlist.dart';
import 'package:mixlists_project/models/mixlist_summary.dart';
import 'package:mixlists_project/models/mixlist_track.dart';
import 'package:mixlists_project/screens/album_detail_screen.dart';
import 'package:mixlists_project/screens/artist_detail_screen.dart';

class MixlistDetailScreen extends StatefulWidget {
  const MixlistDetailScreen({
    super.key,
    required this.mixlist,
    this.highlightSongId,
  });

  final Mixlist mixlist;

  /// When arriving from a specific song (an artist's "songs on mixlists"
  /// entry, or an "also appears in" chip), the id of that song -- its
  /// track gets scrolled into view and highlighted once the list is up.
  final int? highlightSongId;

  @override
  State<MixlistDetailScreen> createState() => _MixlistDetailScreenState();
}

class _MixlistDetailScreenState extends State<MixlistDetailScreen> {
  List<MixlistTrack> _tracks = [];
  Map<int, List<MixlistSummary>> _duplicateSongIndex = {};
  Map<int, GlobalKey> _trackKeys = {};
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _durationInSeconds(int durationMs) {
    final minutes = (durationMs / 1000 / 60).toInt();
    final seconds = (durationMs / 1000 % 60).toInt();
    return "$minutes:${seconds < 10 ? '0' : ''}$seconds";
  }

  Future<void> _loadData() async {
    final repository = getIt<MusicLibraryRepository>();
    try {
      final tracksFuture = repository.getTracksForMixlist(widget.mixlist.id);
      final duplicateIndexFuture = repository.duplicateSongIndex;
      final tracks = await tracksFuture;
      final duplicateIndex = await duplicateIndexFuture;
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _duplicateSongIndex = duplicateIndex;
        _trackKeys = {for (final t in tracks) t.position: GlobalKey()};
        _isLoading = false;
      });
      unawaited(_scrollToHighlightedTrack());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading tracks: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scrollToHighlightedTrack() async {
    final highlightSongId = widget.highlightSongId;
    if (highlightSongId == null) return;
    MixlistTrack? highlighted;
    var index = -1;
    for (var i = 0; i < _tracks.length; i++) {
      if (_tracks[i].songId == highlightSongId) {
        highlighted = _tracks[i];
        index = i;
        break;
      }
    }
    if (highlighted == null) return;
    final key = _trackKeys[highlighted.position];
    if (key == null) return;

    // Wait for the list to actually be laid out (it's still the loading
    // spinner in the same frame this was scheduled from).
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // ListView only mounts tiles near the viewport, so a track far down a
    // long mixlist may not exist in the tree yet -- key.currentContext is
    // null and there's nothing for ensureVisible to scroll to. Jump close
    // to its estimated position (by fraction of the list) to force it to
    // build, then let ensureVisible do the precise, animated alignment.
    if (key.currentContext == null && _scrollController.hasClients) {
      final fraction = _tracks.length <= 1 ? 0.0 : index / (_tracks.length - 1);
      _scrollController.jumpTo(
        fraction * _scrollController.position.maxScrollExtent,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final renderContext = key.currentContext;
    if (renderContext == null || !renderContext.mounted) return;
    await Scrollable.ensureVisible(
      renderContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>().mixlists
        .getById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MixlistDetailScreen(
          mixlist: fullMixlistData,
          highlightSongId: highlightSongId,
        ),
      ),
    );
  }

  Widget _buildTrackTile(MixlistTrack track) {
    final otherMixlists =
        (_duplicateSongIndex[track.songId] ?? const <MixlistSummary>[])
            .where((m) => m.id != widget.mixlist.id)
            .toList();

    return _TrackTile(
      key: _trackKeys[track.position],
      track: track,
      durationLabel: _durationInSeconds(track.durationMs!),
      otherMixlists: otherMixlists,
      onOtherMixlistTap: _openMixlist,
      mixlistCreationDate: widget.mixlist.dateCreated.split('T')[0],
      isHighlighted: track.songId == widget.highlightSongId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.mixlist.id}) ${widget.mixlist.title} | ${widget.mixlist.dateCreated.split('T')[0]}",
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              controller: _scrollController,
              children:
                  [
                    Divider(color: Colors.blueGrey),
                    for (var i = 0; i < _tracks.length; i++) ...[
                      _buildTrackTile(_tracks[i]),
                      if (i != _tracks.length - 1)
                        Divider(color: Colors.blueGrey),
                    ],
                  ] +
                  [Divider(color: Colors.blueGrey), SizedBox(height: 40)],
            ),
    );
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile({
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

  /// True for the one track (if any) this screen was navigated to for --
  /// flashes red then yellow then settles into a lingering green
  /// background so it stays easy to spot.
  final bool isHighlighted;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> with TickerProviderStateMixin {
  // Washed-out red -> yellow -> a pleasant green that the tile then just
  // keeps as its background -- a one-way trip, not a pulse, so the green
  // stays on screen as a permanent "you scrolled in from here" marker.
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(artist: overview),
      ),
    );
  }

  Future<void> _openAlbum(int albumId) async {
    final overview = await getIt<MusicLibraryRepository>()
        .getAlbumOverviewById(albumId);
    if (!mounted || overview == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(album: overview),
      ),
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

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final hasDuplicates = widget.otherMixlists.isNotEmpty;

    return Column(
      crossAxisAlignment: .start,
      children: [
        _wrapWithHighlight(
          ListTile(
            title: Text(
              "${track.position}) ${track.songName}",
              style: TextStyle(fontSize: 18, fontWeight: .bold),
            ),
            subtitle: Wrap(
              crossAxisAlignment: .center,
              children: [
                _HoverableLink(
                  text: track.artistNames,
                  onTap: () => _openArtist(track.artistId),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '\u2022',
                    style: TextStyle(fontSize: 14, fontWeight: .w500),
                  ),
                ),
                _HoverableLink(
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
            leading: CachedNetworkImage(
              imageUrl: track.albumCoverImageURL,
              width: 50,
            ),
          ),
        ),
        if (hasDuplicates)
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
                  child: Align(
                    alignment: .centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: _OtherMixlistsList(
                        mixlists: widget.otherMixlists,
                        onTap: (mixlistId) =>
                            widget.onOtherMixlistTap(mixlistId, track.songId),
                      ),
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

/// The artist/album name in a track's subtitle, tappable to jump to that
/// artist's or album's detail screen. Underlines on hover so it reads as a
/// link -- there's no other in-app precedent for a
/// tappable substring (existing nav taps are always a whole row), so this
/// is a fresh small widget rather than a shared one.
class _HoverableLink extends StatefulWidget {
  const _HoverableLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_HoverableLink> createState() => _HoverableLinkState();
}

class _HoverableLinkState extends State<_HoverableLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: .w500,
            decoration: _isHovered ? .underline : .none,
          ),
        ),
      ),
    );
  }
}

class _OtherMixlistsList extends StatelessWidget {
  const _OtherMixlistsList({required this.mixlists, required this.onTap});

  final List<MixlistSummary> mixlists;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .only(top: 4, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: .circular(12),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .only(left: 12, top: 8, right: 12, bottom: 4),
            child: Text(
              'Also appears in',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final mixlist in mixlists)
            Material(
              child: ListTile(
                dense: true,
                visualDensity: .compact,
                title: Text(
                  "${mixlist.id}) ${mixlist.title}",
                  style: TextStyle(fontSize: 12, fontWeight: .w600),
                ),
                onTap: () => onTap(mixlist.id),
              ),
            ),
        ],
      ),
    );
  }
}
