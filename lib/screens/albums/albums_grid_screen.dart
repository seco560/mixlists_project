import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_grid_tile.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';

/// Grid of albums, either every album or (via [recordLabel]) just one
/// label's -- repurposed from the original "All Albums" screen once it
/// gained that label-scoping/nav-pane role.
class AlbumsGridScreen extends StatefulWidget {
  const AlbumsGridScreen({super.key, this.recordLabel});

  /// Scopes the grid to one record label, reached from a label chip on
  /// [AlbumDetailScreen], a "Labels" search result, or [AllLabelsScreen].
  /// Null shows every album, as on the home screen.
  final String? recordLabel;

  @override
  State<AlbumsGridScreen> createState() => _AlbumsGridScreenState();
}

class _AlbumsGridScreenState extends State<AlbumsGridScreen> {
  List<AlbumOverview> _albums = [];
  bool _isLoading = false;
  String? _previousLabel;
  String? _nextLabel;

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
      final repository = getIt<MusicLibraryRepository>();
      final albumsFuture = repository.getAlbumOverviews(
        filter: getIt<MixlistFilterController>().value,
      );
      final recordLabel = widget.recordLabel;
      final adjacentFuture = recordLabel == null
          ? Future.value((null, null))
          : repository.getAdjacentLabels(recordLabel);

      var result = await albumsFuture;
      final adjacent = await adjacentFuture;
      if (recordLabel != null) {
        result = result.where((a) => a.recordLabel == recordLabel).toList();
      }

      setState(() {
        _albums = result;
        _previousLabel = adjacent.$1;
        _nextLabel = adjacent.$2;
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

  void _goToLabel(String recordLabel, {bool asBack = false}) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumsGridScreen(recordLabel: recordLabel),
        isReverse: asBack,
      ),
    );
  }

  Widget _buildLabelNavButton({
    required IconData icon,
    required String label,
    required String? recordLabel,
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
              recordLabel ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ];
    return Expanded(
      child: InkWell(
        mouseCursor: recordLabel == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onTap: recordLabel == null
            ? null
            : () => _goToLabel(recordLabel, asBack: isPrevious),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Opacity(
            opacity: recordLabel == null ? 0.4 : 1,
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

  Widget _buildLabelNavigationPane() {
    return Row(
      children: [
        _buildLabelNavButton(
          icon: Icons.arrow_back,
          label: 'Previous label',
          recordLabel: _previousLabel,
          alignEnd: false,
          isPrevious: true,
        ),
        _buildLabelNavButton(
          icon: Icons.arrow_forward,
          label: 'Next label',
          recordLabel: _nextLabel,
          alignEnd: true,
          isPrevious: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLabelScoped = widget.recordLabel != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recordLabel == null
              ? "All Albums"
              : "${widget.recordLabel} Albums",
        ),
        centerTitle: true,
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnsThatFit(
                  constraints.maxWidth - _gridPadding * 2,
                );
                final gridWidth =
                    columns * AlbumGridTile.width +
                    (columns - 1) * _tileSpacing;
                return ListView(
                  padding: const EdgeInsets.all(_gridPadding),
                  children: [
                    if (_albums.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text("No data found")),
                      )
                    else
                      Align(
                        alignment: .topLeft,
                        child: SizedBox(
                          width: gridWidth,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                      ),
                    if (isLabelScoped) ...[
                      Divider(),
                      _buildLabelNavigationPane(),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
