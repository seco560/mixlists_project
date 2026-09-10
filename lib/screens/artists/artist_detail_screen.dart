import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/models/view_models/artist_song_appearance.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/text_styles.dart';
import 'package:mixlists_project/widgets/year_histogram_chart.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistOverview artist;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<ArtistSongAppearance> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await getIt<MusicLibraryRepository>()
          .getArtistSongAppearances(widget.artist.id);
      if (!mounted) return;
      setState(() {
        _songs = songs;
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

  /// How many times any of this artist's songs were added to a mixlist,
  /// bucketed by the calendar year of `SongsMixlists.dateAdded` -- reuses
  /// the `datesAdded` already carried by each [ArtistSongAppearance] (one
  /// entry per mixlist a song is on), so no extra query is needed.
  Map<int, int> _addedOverTimeCounts() {
    final counts = <int, int>{};
    for (final song in _songs) {
      for (final dateAdded in song.datesAdded) {
        final year = DateTime.tryParse(dateAdded)?.year;
        if (year == null) continue;
        counts[year] = (counts[year] ?? 0) + 1;
      }
    }
    return counts;
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

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                SectionHeader('Added to Mixlists Over Time'),
                YearHistogramChart(countsByYear: _addedOverTimeCounts()),
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
                      leading: CachedNetworkImage(
                        imageUrl: album.coverImageURL,
                        width: 48,
                        height: 48,
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
                              // AlbumSummary has no artist name (it's
                              // always shown alongside the artist already,
                              // like right here) -- fill it in from
                              // `artist`, which we already have.
                              album: AlbumOverview(
                                id: album.id,
                                name: album.name,
                                releaseDate: album.releaseDate,
                                coverImageURL: album.coverImageURL,
                                artistName: artist.name,
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
