import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/album_overview.dart';
import 'package:mixlists_project/models/artist_overview.dart';
import 'package:mixlists_project/models/search_results.dart';
import 'package:mixlists_project/screens/album_detail_screen.dart';
import 'package:mixlists_project/screens/all_mixlists_screen.dart';
import 'package:mixlists_project/screens/artist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/song_mixlist_tile.dart';

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

  /// Only sections with at least one result are shown at all (no heading
  /// for an empty category), separated by a divider between whichever
  /// sections do end up present.
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
            _ArtistResultTile(artist: artist, onTap: () => _openArtist(artist)),
        ],
      if (results.albums.isNotEmpty)
        [
          SectionHeader('Albums (${results.albums.length})'),
          for (final album in results.albums)
            _AlbumResultTile(album: album, onTap: () => _openAlbum(album)),
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

/// Artists section row -- no reusable artist ListTile exists elsewhere in
/// the app (AllArtistsScreen builds a bespoke sortable table), so this is
/// new. Subtitle reuses fields ArtistOverview already carries.
class _ArtistResultTile extends StatelessWidget {
  const _ArtistResultTile({required this.artist, required this.onTap});

  final ArtistOverview artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(artist.name, style: titleTextStyle),
      subtitle: Text(
        '${artist.albums.length} album${artist.albums.length == 1 ? '' : 's'} • '
        '${artist.uniqueSongCount} song${artist.uniqueSongCount == 1 ? '' : 's'} on mixlists',
        style: metaTextStyle,
      ),
      onTap: onTap,
    );
  }
}

/// Albums section row -- same visual shape as the inline ListTile
/// ArtistDetailScreen builds per-album (48x48 cover, titleTextStyle,
/// metaTextStyle release date), plus an artistName line since search
/// results aren't pre-scoped to one artist the way that screen is.
class _AlbumResultTile extends StatelessWidget {
  const _AlbumResultTile({required this.album, required this.onTap});

  final AlbumOverview album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: album.coverImageURL,
        width: 48,
        height: 48,
      ),
      title: Text(album.name, style: titleTextStyle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(album.artistName, style: subtitleTextStyle),
          Text(album.releaseDate.split('T')[0], style: metaTextStyle),
        ],
      ),
      onTap: onTap,
    );
  }
}
