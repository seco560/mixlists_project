import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/search/artist_result_tile.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/adjacent_nav_pane.dart';
import 'package:mixlists_project/widgets/shared/category_sort_toggle.dart';
import 'package:mixlists_project/widgets/shared/empty_state.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// Every artist tagged with [genre], sortable via [CategorySortToggle] like
/// [AllGenresScreen].
class GenreArtistsScreen extends StatefulWidget {
  const GenreArtistsScreen({super.key, required this.genre});

  final String genre;

  @override
  State<GenreArtistsScreen> createState() => _GenreArtistsScreenState();
}

class _GenreArtistsScreenState extends State<GenreArtistsScreen> {
  List<ArtistOverview> _artists = [];
  bool _isLoading = false;
  String? _previousGenre;
  String? _nextGenre;
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
      final repository = getIt<MusicLibraryRepository>();
      final artistsFuture = repository.getArtistOverviews(
        filter: getIt<MixlistFilterController>().value,
      );
      final adjacentFuture = repository.getAdjacentGenres(widget.genre);

      final result = await artistsFuture;
      final adjacent = await adjacentFuture;
      final filtered = result
          .where((a) => a.genres.contains(widget.genre))
          .toList();

      setState(() {
        _artists = filtered;
        _previousGenre = adjacent.$1;
        _nextGenre = adjacent.$2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
      }
    }
  }

  /// [_artists] sorted per [_sortOrder] -- computed on demand, not stored.
  List<ArtistOverview> get _sortedArtists {
    final artists = List.of(_artists);
    if (_sortOrder == CategorySortOrder.alphabetical) {
      artists.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return artists;
    }
    artists.sort((a, b) {
      final byCount = b.uniqueSongCount.compareTo(a.uniqueSongCount);
      return byCount != 0
          ? byCount
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return artists;
  }

  AdjacentNavTarget? _navTarget(String? genre, {required bool isPrevious}) {
    if (genre == null) return null;
    return AdjacentNavTarget(
      title: genre,
      onTap: () => openGenre(context, genre, isReverse: isPrevious),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noun = getIt<MixlistFilterController>().value.playlistNounPluralLower;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.genre} Artists'),
        actions: [
          CategorySortToggle(
            value: _sortOrder,
            onChanged: (order) => setState(() => _sortOrder = order),
          ),
          const MixlistFilterToggle(),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: detailListBottomPadding,
                  children: [
                    if (_artists.isEmpty)
                      EmptyState(
                        message:
                            'No ${widget.genre} artists on $noun under this '
                            'filter.',
                      )
                    else
                      for (final (i, artist) in _sortedArtists.indexed) ...[
                        ArtistResultTile(
                          artist: artist,
                          onTap: () => openArtist(context, artist),
                        ),
                        if (i != _artists.length - 1) const Divider(),
                      ],
                    const Divider(),
                    AdjacentNavPane(
                      noun: 'genre',
                      previous: _navTarget(_previousGenre, isPrevious: true),
                      next: _navTarget(_nextGenre, isPrevious: false),
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
