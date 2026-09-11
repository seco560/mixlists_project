import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/entities/mixlist.dart';
import 'package:mixlists_project/models/view_models/mixlist_summary.dart';
import 'package:mixlists_project/models/view_models/mixlist_track.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/track_tile.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/year_album_art_histogram.dart';

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

  /// This mixlist's tracks, bucketed by the calendar year of the first 4
  /// characters of `Albums.releaseDate` -- that column is inconsistently
  /// formatted (a bare "2013" vs. a full "2017-08-25"), but both always
  /// start with the 4-digit year. Unlike the artist screen's "added over
  /// time" chart, bucketing by `SongsMixlists.dateAdded` here doesn't say
  /// much -- a mixlist's tracks are mostly all added in the same window,
  /// with the rare outlier just being a song re-added after Spotify pulled
  /// it -- so release year is the more meaningful axis for one mixlist.
  Map<int, List<AlbumArtHistogramEntry>> _releaseYearEntries() {
    final entries = <int, List<AlbumArtHistogramEntry>>{};
    for (final track in _tracks) {
      final releaseDate = track.albumReleaseDate;
      if (releaseDate.length < 4) continue;
      final year = int.tryParse(releaseDate.substring(0, 4));
      if (year == null) continue;
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
    final fullMixlistData = await getIt<MusicLibraryRepository>().getMixlistById(mixlistId);
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
                  [
                    Divider(color: Colors.blueGrey),
                    SectionHeader('Album Release Year Spread'),
                    YearAlbumArtHistogram(entriesByYear: _releaseYearEntries()),
                    const SizedBox(height: 40),
                  ],
            ),
    );
  }
}
