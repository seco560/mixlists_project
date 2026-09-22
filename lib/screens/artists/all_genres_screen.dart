import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/artists/genre_artists_screen.dart';
import 'package:mixlists_project/screens/search/artist_result_tile.dart';
import 'package:mixlists_project/widgets/category_sort_toggle.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// Every distinct genre, grouped in Dart from [MusicLibraryRepository.getArtistOverviews].
/// Artists with no genre are collapsed at the bottom, one-hit-wonder style.
class AllGenresScreen extends StatefulWidget {
  const AllGenresScreen({super.key});

  @override
  State<AllGenresScreen> createState() => _AllGenresScreenState();
}

class _AllGenresScreenState extends State<AllGenresScreen> {
  List<String> _genres = [];
  Map<String, int> _artistCountByGenre = {};
  List<ArtistOverview> _artistsWithoutGenre = [];
  bool _isLoading = false;
  bool _withoutGenreExpanded = false;
  CategorySortOrder _sortOrder = CategorySortOrder.byCount;

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
    setState(() => _isLoading = true);
    try {
      final artists = await getIt<MusicLibraryRepository>().getArtistOverviews(
        filter: getIt<MixlistFilterController>().value,
      );

      final artistsByGenre = <String, List<ArtistOverview>>{};
      final withoutGenre = <ArtistOverview>[];
      for (final artist in artists) {
        if (artist.genres.isEmpty) {
          withoutGenre.add(artist);
          continue;
        }
        for (final genre in artist.genres) {
          artistsByGenre.putIfAbsent(genre, () => []).add(artist);
        }
      }
      final genres = artistsByGenre.keys.toList()..sort();
      withoutGenre.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        _genres = genres;
        _artistCountByGenre = {
          for (final genre in genres) genre: artistsByGenre[genre]!.length,
        };
        _artistsWithoutGenre = withoutGenre;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading genres: $e')));
      }
    }
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

  /// [_genres] sorted per [_sortOrder] -- computed on demand, not stored.
  List<String> get _sortedGenres {
    if (_sortOrder == CategorySortOrder.alphabetical) return _genres;
    final genres = List.of(_genres);
    genres.sort((a, b) {
      final byCount = _artistCountByGenre[b]!.compareTo(
        _artistCountByGenre[a]!,
      );
      return byCount != 0 ? byCount : a.compareTo(b);
    });
    return genres;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _genres.isEmpty && _artistsWithoutGenre.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Genres"),
        centerTitle: true,
        actions: [
          CategorySortToggle(
            value: _sortOrder,
            onChanged: (order) => setState(() => _sortOrder = order),
          ),
          const MixlistFilterToggle(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
          ? const Center(child: Text("No data found"))
          : ListView(
              children: [
                Divider(),
                for (final genre in _sortedGenres) ...[
                  ListTile(
                    leading: const Icon(Icons.sell_outlined),
                    title: Text(genre, style: titleTextStyle),
                    subtitle: Text(
                      '${_artistCountByGenre[genre]} artist${_artistCountByGenre[genre] == 1 ? '' : 's'}',
                      style: metaTextStyle,
                    ),
                    onTap: () => _openGenre(genre),
                  ),
                  Divider(),
                ],
                if (_artistsWithoutGenre.isNotEmpty) ...[
                  _buildWithoutGenreRow(),
                  if (_withoutGenreExpanded)
                    for (final artist in _artistsWithoutGenre)
                      ArtistResultTile(
                        artist: artist,
                        onTap: () => _openArtist(artist),
                      ),
                  Divider(),
                ],
              ],
            ),
    );
  }

  Widget _buildWithoutGenreRow() {
    final count = _artistsWithoutGenre.length;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () =>
            setState(() => _withoutGenreExpanded = !_withoutGenreExpanded),
        child: ListTile(
          leading: Icon(
            _withoutGenreExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          title: Text(
            '$count artist${count == 1 ? '' : 's'} without a genre',
            style: titleTextStyle.copyWith(
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
