import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/search_results.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/search/album_result_tile.dart';
import 'package:mixlists_project/screens/search/artist_result_tile.dart';
import 'package:mixlists_project/widgets/shared/category_tile.dart';
import 'package:mixlists_project/widgets/shared/empty_state.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/shared/song_mixlist_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    final results = _scopedResults;
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : results!.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              message: 'Nothing matches "${widget.query}" under this filter.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: _buildSections(results),
            ),
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
            ArtistResultTile(
              artist: artist,
              onTap: () => openArtist(context, artist),
            ),
        ],
      if (results.genres.isNotEmpty)
        [
          SectionHeader('Genres (${results.genres.length})'),
          for (final genre in results.genres)
            CategoryTile(
              icon: CategoryTile.genreIcon,
              name: genre,
              onTap: () => openGenre(context, genre),
            ),
        ],
      if (results.albums.isNotEmpty)
        [
          SectionHeader('Albums (${results.albums.length})'),
          for (final album in results.albums)
            AlbumResultTile(
              album: album,
              onTap: () => openAlbum(context, album),
            ),
        ],
      if (results.labels.isNotEmpty)
        [
          SectionHeader('Labels (${results.labels.length})'),
          for (final label in results.labels)
            CategoryTile(
              icon: CategoryTile.labelIcon,
              name: label,
              onTap: () => openLabel(context, label),
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
              subtitle: LinkLine(
                parts: [
                  (song.artistNames, null),
                  (song.albumName, () => openAlbumById(context, song.albumId)),
                ],
              ),
              mixlists: song.mixlists,
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
