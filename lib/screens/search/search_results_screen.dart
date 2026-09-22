import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
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
import 'package:mixlists_project/widgets/shared/mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/shared/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  /// Unscoped -- re-filtered in memory by [_scopedResults] on every build,
  /// rather than re-searching, whenever [MixlistFilterController] changes.
  SearchResults? _rawResults;
  bool _isLoading = true;
  String? _error;

  SearchResults? get _scopedResults =>
      _rawResults?.scopedTo(getIt<MixlistFilterController>().value);

  @override
  void initState() {
    super.initState();
    getIt<MixlistFilterController>().addListener(_onFilterChanged);
    _loadData();
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  Future<void> _loadData() async {
    try {
      final results = await getIt<MusicLibraryRepository>().searchLibrary(
        widget.query,
      );
      if (!mounted) return;
      setState(() {
        _rawResults = results;
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
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.mixlist,
        entityId: fullMixlistData.id,
        title: fullMixlistData.title,
      ),
      builder: (context) => MixlistDetailScreen(
        mixlist: fullMixlistData,
        highlightSongId: highlightSongId,
      ),
    );
  }

  void _openArtist(ArtistOverview artist) {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.artist,
        entityId: artist.id,
        title: artist.name,
        mosaicUrls: [for (final a in artist.albums.take(4)) a.coverImageURL],
      ),
      builder: (context) => ArtistDetailScreen(artist: artist),
    );
  }

  void _openAlbum(AlbumOverview album) {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.album,
        entityId: album.id,
        title: album.name,
        subtitle: album.artistName,
        imageUrl: album.coverImageURL,
      ),
      builder: (context) => AlbumDetailScreen(album: album),
    );
  }

  void _openGenre(String genre) {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.genre,
        key: genre,
        title: genre,
      ),
      builder: (context) => GenreArtistsScreen(genre: genre),
    );
  }

  void _openLabel(String label) {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.label,
        key: label,
        title: label,
      ),
      builder: (context) => AlbumsGridScreen(recordLabel: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _scopedResults;
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
          SectionHeader(
            '${getIt<MixlistFilterController>().value.playlistNounPlural} '
            '(${results.mixlists.length})',
          ),
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
