import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/repository/duplicate_song_index_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/track_tile.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/mixlists/mixlist_audio_feature_chart.dart';
import 'package:mixlists_project/widgets/shared/adjacent_nav_pane.dart';
import 'package:mixlists_project/widgets/shared/detail_header.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/shared/year_album_art_histogram.dart';

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

  /// Shown in place of the raw id -- starts as the id itself so the header
  /// has *something* before the position query resolves.
  late int _displayNumber = widget.mixlist.id;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Duplicate badges, adjacent mixlists and display number depend on the
    // filter, so reload when it changes.
    getIt<MixlistFilterController>().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_loadData);
    _scrollController.dispose();
    super.dispose();
  }

  static String _formatDuration(int durationMs) {
    final totalSeconds = durationMs ~/ 1000;
    final seconds = totalSeconds % 60;
    return "${totalSeconds ~/ 60}:${seconds < 10 ? '0' : ''}$seconds";
  }

  /// "1 h 12 min" / "48 min" for the header.
  static String _formatRuntime(int durationMs) {
    final minutes = (durationMs / 60000).round();
    return minutes >= 60
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : '$minutes min';
  }

  /// Up to 4 distinct album covers in track order, for the header mosaic.
  List<String?> get _coverUrls {
    final seen = <int>{};
    return [
      for (final track in _tracks)
        if (seen.add(track.albumId)) track.albumCoverImageURL,
    ].take(4).toList();
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
      if (!(seenAlbumIdsByYear
          .putIfAbsent(year, () => {})
          .add(track.albumId))) {
        continue;
      }
      entries
          .putIfAbsent(year, () => [])
          .add(
            AlbumArtHistogramEntry(
              imageUrl: track.albumCoverImageURL,
              tooltip: '${track.albumName}\n${track.songName}',
              onTap: () => openAlbumById(context, track.albumId),
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
      final duplicateIndexFuture = getIt<DuplicateSongIndexController>().ready;
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

  Widget _buildTrackTile(MixlistTrack track) {
    final otherMixlists =
        (_duplicateSongIndex[track.songId] ?? const <MixlistSummary>[])
            .where((m) => m.id != widget.mixlist.id)
            .toList();

    return TrackTile(
      key: _trackKeys[track.position],
      track: track,
      durationLabel: track.durationMs == null
          ? '–:––'
          : _formatDuration(track.durationMs!),
      otherMixlists: otherMixlists,
      mixlistCreationDate: widget.mixlist.dateCreated.split('T')[0],
      isHighlighted: track.songId == widget.highlightSongId,
    );
  }

  AdjacentNavTarget? _navTarget(Mixlist? mixlist, {required bool isPrevious}) {
    if (mixlist == null) return null;
    return AdjacentNavTarget(
      title: mixlist.title,
      subtitle: mixlist.dateCreated.split('T')[0],
      onTap: () => openMixlist(context, mixlist, isReverse: isPrevious),
    );
  }

  Widget _buildNavigationPane() {
    return AdjacentNavPane(
      noun: getIt<MixlistFilterController>().value.playlistNounSingularLower,
      previous: _navTarget(_previousMixlist, isPrevious: true),
      next: _navTarget(_nextMixlist, isPrevious: false),
      dense: true,
    );
  }

  Widget _buildHeader() {
    final mixlist = widget.mixlist;
    final noun = getIt<MixlistFilterController>().value.playlistNounSingular;
    final totalMs = _tracks.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0));
    final description = mixlist.description.trim();
    return DetailHeader(
      artwork: PlaylistCoverGrid(
        coverImageUrls: _coverUrls,
        size: DetailHeader.denseArtSize,
      ),
      dense: true,
      overline: '$noun #$_displayNumber',
      title: mixlist.title,
      lines: [
        DetailFacts([
          mixlist.dateCreated.split('T')[0],
          '${_tracks.length} ${_tracks.length == 1 ? 'song' : 'songs'}',
          if (totalMs > 0) _formatRuntime(totalMs),
        ]),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              description,
              style: metaTextStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mixlist.title, overflow: TextOverflow.ellipsis),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : ListTileTheme.merge(
                  // Track lists are long; keep rows tight.
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  horizontalTitleGap: 12,
                  minVerticalPadding: 2,
                  visualDensity: VisualDensity.compact,
                  child: ListView(
                    controller: _scrollController,
                    padding: detailListBottomPadding,
                    children: [
                      _buildHeader(),
                      _buildNavigationPane(),
                      const Divider(),
                      for (var i = 0; i < _tracks.length; i++) ...[
                        _buildTrackTile(_tracks[i]),
                        if (i != _tracks.length - 1) const Divider(),
                      ],
                      const Divider(),
                      const SectionHeader(
                        'Album Release Year Spread',
                        dense: true,
                      ),
                      YearAlbumArtHistogram(
                        entriesByYear: _releaseYearEntries(),
                      ),
                      const Divider(),
                      const SectionHeader('Audio Features', dense: true),
                      MixlistAudioFeatureChart(
                        tracks: _tracks,
                        playlistNounSingular: getIt<MixlistFilterController>()
                            .value
                            .playlistNounSingular,
                      ),
                      const Divider(),
                      _buildNavigationPane(),
                    ],
                  ),
                ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: BreadcrumbTrailButton(),
            ),
          ),
        ],
      ),
    );
  }
}
