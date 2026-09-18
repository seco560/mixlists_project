import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/track_tile.dart';
import 'package:mixlists_project/widgets/mixlist_audio_feature_chart.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/year_album_art_histogram.dart';

class MixlistDetailScreen extends StatefulWidget {
  const MixlistDetailScreen({
    super.key,
    required this.mixlist,
    this.highlightSongId,
  });

  final Mixlist mixlist;

  /// When arriving from a specific song, its track gets scrolled into
  /// view and highlighted once the list is up.
  final int? highlightSongId;

  @override
  State<MixlistDetailScreen> createState() => _MixlistDetailScreenState();
}

class _MixlistDetailScreenState extends State<MixlistDetailScreen> {
  List<MixlistTrack> _tracks = [];
  Map<int, List<MixlistSummary>> _duplicateSongIndex = {};
  Map<int, GlobalKey> _trackKeys = {};
  Mixlist? _previousMixlist;
  Mixlist? _nextMixlist;

  /// Shown in the AppBar title in place of the raw id -- starts as the id
  /// itself so the title has *something* before the position query resolves
  late int _displayNumber = widget.mixlist.id;
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

  /// Tracks bucketed by the calendar year prefix of `Albums.releaseDate`
  Map<int, List<AlbumArtHistogramEntry>> _releaseYearEntries() {
    final entries = <int, List<AlbumArtHistogramEntry>>{};
    final seenAlbumIdsByYear = <int, Set<int>>{};
    for (final track in _tracks) {
      final releaseDate = track.albumReleaseDate;
      if (releaseDate.length < 4) continue;
      final year = int.tryParse(releaseDate.substring(0, 4));
      if (year == null) continue;
      if (!(seenAlbumIdsByYear.putIfAbsent(year, () => {}).add(track.albumId))) {
        continue;
      }
      entries
          .putIfAbsent(year, () => [])
          .add(
            AlbumArtHistogramEntry(
              imageUrl: track.albumCoverImageURL,
              tooltip: '${track.albumName}\n${track.songName}',
              onTap: () => _openAlbum(track.albumId),
            ),
          );
    }
    return entries;
  }

  Future<void> _loadData() async {
    final repository = getIt<MusicLibraryRepository>();
    try {
      final tracksFuture = repository.getTracksForMixlist(widget.mixlist.id);
      final filter = getIt<MixlistFilterController>().value;
      final duplicateIndexFuture = repository.duplicateSongIndex(
        filter: filter,
      );
      final adjacentFuture = repository.getAdjacentMixlists(
        widget.mixlist,
        filter: filter,
      );
      final positionFuture = repository.getMixlistPosition(
        widget.mixlist.id,
        filter: filter,
      );

      final tracks = await tracksFuture;
      final duplicateIndex = await duplicateIndexFuture;
      final adjacent = await adjacentFuture;
      final position = await positionFuture;
      if (!mounted) return;

      setState(() {
        _tracks = tracks;
        _duplicateSongIndex = duplicateIndex;
        _trackKeys = {for (final t in tracks) t.position: GlobalKey()};
        _previousMixlist = adjacent.$1;
        _nextMixlist = adjacent.$2;
        _displayNumber = position;
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

    // A far-off track may not be built yet; jump near its estimated
    // position to force it to build, then let ensureVisible align it.
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

  void _goToMixlist(Mixlist mixlist, {bool asBack = false}) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => MixlistDetailScreen(mixlist: mixlist),
        isReverse: asBack,
      ),
    );
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>()
        .getMixlistById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => MixlistDetailScreen(
          mixlist: fullMixlistData,
          highlightSongId: highlightSongId,
        ),
      ),
    );
  }

  Future<void> _openAlbum(int albumId) async {
    final overview = await getIt<MusicLibraryRepository>().getAlbumOverviewById(
      albumId,
    );
    if (!mounted || overview == null) return;
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumDetailScreen(album: overview),
      ),
    );
  }

  Widget _buildTrackTile(MixlistTrack track) {
    final otherMixlists =
        (_duplicateSongIndex[track.songId] ?? const <MixlistSummary>[])
            .where((m) => m.id != widget.mixlist.id)
            .toList();

    return TrackTile(
      key: _trackKeys[track.position],
      track: track,
      durationLabel: _durationInSeconds(track.durationMs!),
      otherMixlists: otherMixlists,
      onOtherMixlistTap: _openMixlist,
      mixlistCreationDate: widget.mixlist.dateCreated.split('T')[0],
      isHighlighted: track.songId == widget.highlightSongId,
    );
  }

  Widget _buildMixlistNavButton({
    required IconData icon,
    required String label,
    required Mixlist? mixlist,
    required bool alignEnd,
    required bool isPrevious,
  }) {
    final children = [
      Icon(icon),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              mixlist?.title ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (mixlist != null)
              Text(
                mixlist.dateCreated.split('T')[0],
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    ];
    return Expanded(
      child: InkWell(
        onTap: mixlist == null
            ? null
            : () => _goToMixlist(mixlist, asBack: isPrevious),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Opacity(
            opacity: mixlist == null ? 0.4 : 1,
            child: Row(
              mainAxisAlignment: alignEnd
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: alignEnd ? children.reversed.toList() : children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMixlistNavigationPane() {
    return Row(
      children: [
        _buildMixlistNavButton(
          icon: Icons.arrow_back,
          label: 'Previous mixlist',
          mixlist: _previousMixlist,
          alignEnd: false,
          isPrevious: true,
        ),
        _buildMixlistNavButton(
          icon: Icons.arrow_forward,
          label: 'Next mixlist',
          mixlist: _nextMixlist,
          alignEnd: true,
          isPrevious: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$_displayNumber) ${widget.mixlist.title} | ${widget.mixlist.dateCreated.split('T')[0]}",
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
                    _buildMixlistNavigationPane(),
                    Divider(color: Colors.blueGrey),
                    for (var i = 0; i < _tracks.length; i++) ...[
                      _buildTrackTile(_tracks[i]),
                      if (i != _tracks.length - 1)
                        Divider(color: Colors.blueGrey),
                    ],
                  ] +
                  [
                    Divider(color: Colors.blueGrey),
                    SectionHeader('Album Release Year Spread'),
                    YearAlbumArtHistogram(entriesByYear: _releaseYearEntries()),
                    Divider(color: Colors.blueGrey),
                    SectionHeader('Audio Features'),
                    MixlistAudioFeatureChart(tracks: _tracks),
                    Divider(color: Colors.blueGrey),
                    _buildMixlistNavigationPane(),
                    const SizedBox(height: 16),
                  ],
            ),
    );
  }
}
