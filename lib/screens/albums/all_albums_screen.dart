import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_grid_tile.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';

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
      final result = await getIt<MusicLibraryRepository>().getAlbumOverviews(
        filter: getIt<MixlistFilterController>().value,
      );
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
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _albums.isEmpty
          ? const Center(child: Text("No data found"))
          : Padding(
              padding: const EdgeInsets.all(_gridPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Prevent tile size from modifying when resizing
                  final columns = _columnsThatFit(constraints.maxWidth);
                  final gridWidth =
                      columns * AlbumGridTile.width +
                      (columns - 1) * _tileSpacing;
                  return Align(
                    alignment: .topLeft,
                    child: SizedBox(
                      width: gridWidth,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
