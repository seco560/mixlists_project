import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/category_sort_toggle.dart';
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

  String _playlistCountLabel(int count) {
    final filter = getIt<MixlistFilterController>().value;
    return count == 1
        ? filter.playlistNounSingularLower
        : filter.playlistNounPluralLower;
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

  void _goToGenre(String genre, {bool asBack = false}) {
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.genre,
        key: genre,
        title: genre,
      ),
      builder: (context) => GenreArtistsScreen(genre: genre),
      isReverse: asBack,
    );
  }

  Widget _buildGenreNavButton({
    required IconData icon,
    required String label,
    required String? genre,
    required bool alignEnd,
    required bool isPrevious,
  }) {
    final children = [
      Icon(icon),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              genre ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ];
    return Expanded(
      child: InkWell(
        mouseCursor: genre == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onTap: genre == null
            ? null
            : () => _goToGenre(genre, asBack: isPrevious),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Opacity(
            opacity: genre == null ? 0.4 : 1,
            child: Row(
              mainAxisAlignment: alignEnd
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: alignEnd ? children.reversed.toList() : children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreNavigationPane() {
    return Row(
      children: [
        _buildGenreNavButton(
          icon: Icons.arrow_back,
          label: 'Previous genre',
          genre: _previousGenre,
          alignEnd: false,
          isPrevious: true,
        ),
        _buildGenreNavButton(
          icon: Icons.arrow_forward,
          label: 'Next genre',
          genre: _nextGenre,
          alignEnd: true,
          isPrevious: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.genre} Artists"),
        centerTitle: true,
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
                  children: [
                    Divider(),
                    if (_artists.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text("No data found")),
                      )
                    else
                      for (final (i, artist) in _sortedArtists.indexed) ...[
                        ListTile(
                          title: Text(artist.name, style: titleTextStyle),
                          subtitle: Text(
                            '${artist.uniqueSongCount} song${artist.uniqueSongCount == 1 ? '' : 's'} • '
                            '${artist.mixlists.length} ${_playlistCountLabel(artist.mixlists.length)}',
                            style: metaTextStyle,
                          ),
                          onTap: () => _openArtist(artist),
                        ),
                        if (i != _artists.length - 1) Divider(),
                      ],
                    Divider(),
                    _buildGenreNavigationPane(),
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
