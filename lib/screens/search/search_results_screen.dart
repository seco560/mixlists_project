import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/models/view_models/search_results.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/search/album_result_tile.dart';
import 'package:mixlists_project/screens/search/artist_result_tile.dart';
import 'package:mixlists_project/widgets/mixlist_tile.dart';
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

  void _openArtist(ArtistOverview artist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArtistDetailScreen(artist: artist)),
    );
  }

  void _openAlbum(AlbumOverview album) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlbumDetailScreen(album: album)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
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
      if (results.albums.isNotEmpty)
        [
          SectionHeader('Albums (${results.albums.length})'),
          for (final album in results.albums)
            AlbumResultTile(album: album, onTap: () => _openAlbum(album)),
        ],
      if (results.songs.isNotEmpty)
        [
          SectionHeader('Songs (${results.songs.length})'),
          for (final song in results.songs)
            SongMixlistTile(
              songId: song.songId,
              title: song.songName,
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
