import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/artist_song_appearance.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/search/album_result_tile.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/category_tile.dart';
import 'package:mixlists_project/widgets/shared/detail_header.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/shared/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/shared/year_album_art_histogram.dart';
import 'package:mixlists_project/widgets/timeline/artist_timeline_strip.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistOverview artist;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  /// Replaced by a fresh filter-scoped overview on every load; read albums/
  /// mixlists from here, not `widget.artist`, or the filter won't apply.
  late ArtistOverview _artist = widget.artist;
  List<ArtistSongAppearance> _songs = [];

  /// Every mixlist under the filter, oldest first: the timeline's x-axis.
  List<Mixlist> _allMixlists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    getIt<MixlistFilterController>().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final filter = getIt<MixlistFilterController>().value;
    try {
      final repository = getIt<MusicLibraryRepository>();
      final songsFuture = repository.getArtistSongAppearances(
        widget.artist.id,
        filter: filter,
      );
      final artistFuture = repository.getArtistOverviewById(
        widget.artist.id,
        filter: filter,
      );
      final allMixlistsFuture = repository.getAllMixlists(filter: filter);
      final songs = await songsFuture;
      final artist = await artistFuture;
      final allMixlists = await allMixlistsFuture;
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _allMixlists = allMixlists;
        if (artist != null) _artist = artist;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading songs: $e';
        _isLoading = false;
      });
    }
  }

  /// Songs bucketed by calendar year of `SongsMixlists.dateAdded`. Years
  /// with no additions are still included (empty) so the histogram shows
  /// a blank column instead of skipping the gap.
  Map<int, List<AlbumArtHistogramEntry>> _addedOverTimeEntries() {
    final entries = <int, List<AlbumArtHistogramEntry>>{};
    for (final song in _songs) {
      for (var i = 0; i < song.datesAdded.length; i++) {
        final year = DateTime.tryParse(song.datesAdded[i])?.year;
        if (year == null) continue;
        final mixlist = i < song.mixlists.length ? song.mixlists[i] : null;
        entries
            .putIfAbsent(year, () => [])
            .add(
              AlbumArtHistogramEntry(
                imageUrl: song.albumCoverImageURL,
                tooltip: '${song.songName} — ${mixlist?.title ?? ''}',
                onTap: mixlist == null
                    ? null
                    : () => openMixlistById(
                        context,
                        mixlist.id,
                        highlightSongId: song.songId,
                      ),
              ),
            );
      }
    }
    if (entries.isNotEmpty) {
      final minYear = entries.keys.reduce(min);
      final maxYear = entries.keys.reduce(max);
      for (var year = minYear; year <= maxYear; year++) {
        entries.putIfAbsent(year, () => []);
      }
    }
    return entries;
  }

  Widget _buildTimeline(MixlistFilter filter) {
    final positionById = {
      for (var i = 0; i < _allMixlists.length; i++) _allMixlists[i].id: i + 1,
    };
    final songsByPosition = <int, List<ArtistTimelineSong>>{};
    for (final song in _songs) {
      for (final mixlist in song.mixlists) {
        final position = positionById[mixlist.id];
        if (position == null) continue;
        songsByPosition
            .putIfAbsent(position, () => [])
            .add(
              ArtistTimelineSong(
                songId: song.songId,
                songName: song.songName,
                albumCoverImageURL: song.albumCoverImageURL,
              ),
            );
      }
    }
    return ArtistTimelineStrip(
      artistId: _artist.id,
      artistName: _artist.name,
      points: [
        for (var i = 0; i < _allMixlists.length; i++)
          TimelineMixlistPoint.positionOnly(
            position: i + 1,
            mixlist: _allMixlists[i],
          ),
      ],
      songsByPosition: songsByPosition,
      onSongTap: (point, song) =>
          openMixlist(context, point.mixlist, highlightSongId: song.songId),
      playlistNounSingularLower: filter.playlistNounSingularLower,
      playlistNounPluralLower: filter.playlistNounPluralLower,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    final filter = getIt<MixlistFilterController>().value;
    final playlistNounPlural = filter.playlistNounPlural;
    final mixlistCount = artist.mixlists.length;
    final entries = _addedOverTimeEntries();

    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name, overflow: TextOverflow.ellipsis),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: detailListBottomPadding,
                  children: [
                    DetailHeader(
                      artwork: PlaylistCoverGrid(
                        coverImageUrls: [
                          for (final a in artist.albums.take(4))
                            a.coverImageURL,
                        ],
                        size: DetailHeader.artSize,
                      ),
                      overline: 'Artist',
                      title: artist.name,
                      lines: [
                        DetailFacts([
                          '${_songs.length} ${_songs.length == 1 ? 'song' : 'songs'}',
                          '${artist.albums.length} ${artist.albums.length == 1 ? 'album' : 'albums'}',
                          '$mixlistCount ${mixlistCount == 1 ? filter.playlistNounSingularLower : filter.playlistNounPluralLower}',
                        ]),
                      ],
                      chips: [
                        for (final genre in artist.genres)
                          ActionChip(
                            avatar: const Icon(
                              CategoryTile.genreIcon,
                              size: 16,
                            ),
                            label: Text(genre),
                            onPressed: () => openGenre(context, genre),
                          ),
                      ],
                    ),
                    const Divider(),
                    const SectionHeader('Timeline'),
                    _buildTimeline(filter),
                    const Divider(height: 32),
                    SectionHeader(
                      'Added to $playlistNounPlural ${[for (final e in entries.values) ...e].length} Times',
                    ),
                    YearAlbumArtHistogram(entriesByYear: entries),
                    const Divider(height: 32),
                    SectionHeader(
                      'Songs on $playlistNounPlural (${_songs.length})',
                    ),
                    if (_songs.isEmpty)
                      const EmptySectionTile()
                    else
                      for (final song in _songs)
                        SongMixlistTile(
                          songId: song.songId,
                          title: song.songName,
                          isExplicit: song.isExplicit == true,
                          leadingImageUrl: song.albumCoverImageURL,
                          subtitle: Column(
                            crossAxisAlignment: .start,
                            children: [
                              LinkLine(
                                parts: [
                                  (
                                    song.albumName,
                                    () => openAlbumById(context, song.albumId),
                                  ),
                                ],
                              ),
                              Text(
                                'Added on ${song.datesAdded.map((d) => d.split('T')[0]).join(', ')}',
                                style: metaTextStyle,
                              ),
                            ],
                          ),
                          mixlists: song.mixlists,
                        ),
                    const Divider(height: 32),
                    SectionHeader('Albums Featured (${artist.albums.length})'),
                    if (artist.albums.isEmpty)
                      const EmptySectionTile()
                    else
                      // AlbumSummary has no artist; fill it from `artist`.
                      for (final album in artist.albums.map(
                        (a) => AlbumOverview(
                          id: a.id,
                          name: a.name,
                          releaseDate: a.releaseDate,
                          coverImageURL: a.coverImageURL,
                          artistId: artist.id,
                          artistName: artist.name,
                          recordLabel: a.recordLabel,
                        ),
                      ))
                        AlbumResultTile(
                          showArtist: false,
                          album: album,
                          onTap: () => openAlbum(context, album),
                        ),
                  ],
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
