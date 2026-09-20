import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/search_results.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/artists/genre_artists_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/search/album_result_tile.dart';
import 'package:mixlists_project/screens/search/artist_result_tile.dart';
import 'package:mixlists_project/widgets/mixlist_tile.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  SearchResults? _results;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await getIt<MusicLibraryRepository>().searchLibrary(
        widget.query,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error searching: $e';
        _isLoading = false;
      });
    }
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

  void _openArtist(ArtistOverview artist) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _openAlbum(AlbumOverview album) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _openGenre(String genre) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => GenreArtistsScreen(genre: genre),
      ),
    );
  }

  void _openLabel(String label) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumsGridScreen(recordLabel: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : results!.isEmpty
          ? const Center(child: Text('No results found'))
          : ListView(children: _buildSections(results)),
    );
  }

  List<Widget> _buildSections(SearchResults results) {
    final sections = <List<Widget>>[
      if (results.mixlists.isNotEmpty)
        [
          SectionHeader('Mixlists (${results.mixlists.length})'),
          for (final mixlist in results.mixlists) MixlistTile(mixlist: mixlist),
        ],
      if (results.artists.isNotEmpty)
        [
          SectionHeader('Artists (${results.artists.length})'),
          for (final artist in results.artists)
            ArtistResultTile(artist: artist, onTap: () => _openArtist(artist)),
        ],
      if (results.genres.isNotEmpty)
        [
          SectionHeader('Genres (${results.genres.length})'),
          for (final genre in results.genres)
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(genre),
              onTap: () => _openGenre(genre),
            ),
        ],
      if (results.albums.isNotEmpty)
        [
          SectionHeader('Albums (${results.albums.length})'),
          for (final album in results.albums)
            AlbumResultTile(album: album, onTap: () => _openAlbum(album)),
        ],
      if (results.labels.isNotEmpty)
        [
          SectionHeader('Labels (${results.labels.length})'),
          for (final label in results.labels)
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(label),
              onTap: () => _openLabel(label),
            ),
        ],
      if (results.songs.isNotEmpty)
        [
          SectionHeader('Songs (${results.songs.length})'),
          for (final song in results.songs)
            SongMixlistTile(
              songId: song.songId,
              title: song.songName,
              isExplicit: song.isExplicit == true,
              leadingImageUrl: song.albumCoverImageURL,
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.albumName, style: subtitleTextStyle),
                  Text(song.artistNames, style: metaTextStyle),
                ],
              ),
              mixlists: song.mixlists,
              onOpenMixlist: _openMixlist,
            ),
        ],
    ];

    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const Divider(height: 32),
        ...sections[i],
      ],
    ];
  }
}
