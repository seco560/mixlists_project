import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/album_overview.dart';
import 'package:mixlists_project/screens/album_detail_screen.dart';

class AllAlbumsScreen extends StatefulWidget {
  const AllAlbumsScreen({super.key});

  @override
  State<AllAlbumsScreen> createState() => _AllAlbumsScreenState();
}

class _AllAlbumsScreenState extends State<AllAlbumsScreen> {
  List<AlbumOverview> _albums = [];
  bool _isLoading = false;

  static const double _tileSpacing = 16;
  static const double _gridPadding = 16;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<MusicLibraryRepository>().getAlbumOverviews();
      setState(() {
        _albums = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading albums: $e')));
      }
    }
  }

  int _columnsThatFit(double availableWidth) {
    const step = _AlbumTile.width + _tileSpacing;
    final columns = ((availableWidth + _tileSpacing) / step).floor();
    return columns < 1 ? 1 : columns;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Albums"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _albums.isEmpty
          ? const Center(child: Text("No data found"))
          // Deliberately not SliverGridDelegateWithMaxCrossAxisExtent: it
          // stretches every tile to exactly fill each row, so tiles
          // visibly grow and shrink as the window is resized. A real
          // Finder icon grid keeps a fixed icon size and just changes how
          // many columns fit, with leftover width left as trailing
          // margin -- this LayoutBuilder computes that column count
          // itself and pins the grid to a matching fixed-size box so
          // tile size never moves.
          : Padding(
              padding: const EdgeInsets.all(_gridPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _columnsThatFit(constraints.maxWidth);
                  final gridWidth =
                      columns * _AlbumTile.width +
                      (columns - 1) * _tileSpacing;
                  return Align(
                    alignment: .topLeft,
                    child: SizedBox(
                      width: gridWidth,
                      child: GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: _tileSpacing,
                              crossAxisSpacing: _tileSpacing,
                              mainAxisExtent: _AlbumTile.height,
                            ),
                        itemCount: _albums.length,
                        itemBuilder: (context, index) =>
                            _AlbumTile(album: _albums[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// Text scale borrowed from ArtistDetailScreen/MixlistDetailScreen's tiles,
// shrunk one notch since a grid tile has far less width than a full-width
// ListTile: bold ~16px for the tile's identity (album title), ~14px w500
// for the subtitle (artist name), ~12px grey for meta (release date).
// Explicit `height` factors make the text block's rendered height
// predictable, since `_AlbumTile.height` below is a hand-tuned constant
// that has to fit it.
const _titleTextStyle = TextStyle(fontSize: 16, fontWeight: .bold, height: 1.2);
const _subtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: .w500,
  height: 1.2,
);
const _metaTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.black54,
  height: 1.2,
);

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final AlbumOverview album;

  // Fixed pixel sizes, not fractions of the available width -- this is
  // what keeps the grid Finder-style (constant tile size, column count
  // changes instead of the tiles). `height` is `width` (a square cover)
  // plus a fixed allowance for the 6px gap and 3 text lines below, with a
  // little slack so a stray extra pixel of text renders as harmless blank
  // space at the bottom of the tile rather than an overflow.
  static const double width = 200;
  static const double _textAreaHeight = 66;
  static const double height = width + _textAreaHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: .start,
        children: [
          ClipRRect(
            borderRadius: .circular(4),
            child: SizedBox(
              width: width,
              height: width,
              child: CachedNetworkImage(
                imageUrl: album.coverImageURL,
                fit: .cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.album, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            style: _titleTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
          Text(
            album.artistName,
            style: _subtitleTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
          Text(
            album.releaseDate.split('T')[0],
            style: _metaTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ],
      ),
    );
  }
}
