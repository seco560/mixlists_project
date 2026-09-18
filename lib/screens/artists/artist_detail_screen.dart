import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/artist_song_appearance.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/artists/genre_artists_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/text_styles.dart';
import 'package:mixlists_project/widgets/year_album_art_histogram.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistOverview artist;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  /// Starts as whatever the caller passed in, then gets replaced by a
  /// freshly-fetched, filter-scoped overview on every load -- this
  /// screen doesn't otherwise re-query albums/mixlists independently, so
  /// `artist.albums`/`artist.mixlists` must come from here, not
  /// `widget.artist`, for the filter to actually affect what's shown.
  late ArtistOverview _artist = widget.artist;
  List<ArtistSongAppearance> _songs = [];
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
      final songs = await songsFuture;
      final artist = await artistFuture;
      if (!mounted) return;
      setState(() {
        _songs = songs;
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
                    : () => _openMixlist(mixlist.id, song.songId),
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

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>()
        .getMixlistById(mixlistId);
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

  void _openGenre(String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenreArtistsScreen(genre: genre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                SectionHeader('Genres'),
                if (artist.genres.isEmpty)
                  const EmptySectionTile()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final genre in artist.genres)
                          ActionChip(
                            label: Text(genre),
                            onPressed: () => _openGenre(genre),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 32),
                SectionHeader('Added to Mixlists Over Time'),
                YearAlbumArtHistogram(entriesByYear: _addedOverTimeEntries()),
                const Divider(height: 32),
                SectionHeader('Songs on Mixlists (${_songs.length})'),
                if (_songs.isEmpty)
                  const EmptySectionTile()
                else
                  for (final song in _songs)
                    SongMixlistTile(
                      songId: song.songId,
                      title: song.songName,
                      leadingImageUrl: song.albumCoverImageURL,
                      subtitle: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(song.albumName, style: subtitleTextStyle),
                          Text(
                            'Added on ${song.datesAdded.map((d) => d.split('T')[0]).join(', ')}',
                            style: metaTextStyle,
                          ),
                        ],
                      ),
                      mixlists: song.mixlists,
                      onOpenMixlist: _openMixlist,
                    ),
                const Divider(height: 32),
                SectionHeader('Albums Featured (${artist.albums.length})'),
                if (artist.albums.isEmpty)
                  const EmptySectionTile()
                else
                  for (final album in artist.albums)
                    ListTile(
                      leading: AlbumArtThumbnail(
                        imageUrl: album.coverImageURL,
                        size: 48,
                        borderRadius: 0,
                      ),
                      title: Text(album.name, style: titleTextStyle),
                      subtitle: Text(
                        album.releaseDate.split('T')[0],
                        style: metaTextStyle,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumDetailScreen(
                              // AlbumSummary has no artist name; fill it in
                              // from `artist`, which we already have.
                              album: AlbumOverview(
                                id: album.id,
                                name: album.name,
                                releaseDate: album.releaseDate,
                                coverImageURL: album.coverImageURL,
                                artistId: artist.id,
                                artistName: artist.name,
                                recordLabel: album.recordLabel,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
    );
  }
}
