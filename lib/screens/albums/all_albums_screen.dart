import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_grid_tile.dart';

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
    const step = AlbumGridTile.width + _tileSpacing;
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
                      columns * AlbumGridTile.width +
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
                              mainAxisExtent: AlbumGridTile.height,
                            ),
                        itemCount: _albums.length,
                        itemBuilder: (context, index) =>
                            AlbumGridTile(album: _albums[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
