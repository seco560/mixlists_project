import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// Every artist tagged with [genre] -- reached from a genre chip on
/// [ArtistDetailScreen], a "Genres" search result, or [AllGenresScreen].
/// A plain flat list, not the sortable All Artists grid -- genres are
/// typically small, browsable groupings that don't need column sorting.
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

  void _openArtist(ArtistOverview artist) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _goToGenre(String genre, {bool asBack = false}) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => GenreArtistsScreen(genre: genre),
        isReverse: asBack,
      ),
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
        backgroundColor: Colors.lightBlueAccent,
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Divider(color: Colors.blueGrey),
                if (_artists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text("No data found")),
                  )
                else
                  for (var i = 0; i < _artists.length; i++) ...[
                    ListTile(
                      title: Text(_artists[i].name, style: titleTextStyle),
                      subtitle: Text(
                        '${_artists[i].uniqueSongCount} song${_artists[i].uniqueSongCount == 1 ? '' : 's'} • '
                        '${_artists[i].mixlists.length} mixlist${_artists[i].mixlists.length == 1 ? '' : 's'}',
                        style: metaTextStyle,
                      ),
                      onTap: () => _openArtist(_artists[i]),
                    ),
                    if (i != _artists.length - 1)
                      Divider(color: Colors.blueGrey),
                  ],
                Divider(color: Colors.blueGrey),
                _buildGenreNavigationPane(),
              ],
            ),
    );
  }
}
