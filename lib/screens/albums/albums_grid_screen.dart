import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_grid_tile.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/adjacent_nav_pane.dart';
import 'package:mixlists_project/widgets/shared/empty_state.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';

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

  AdjacentNavTarget? _navTarget(String? label, {required bool isPrevious}) {
    if (label == null) return null;
    return AdjacentNavTarget(
      title: label,
      onTap: () => openLabel(context, label, isReverse: isPrevious),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLabelScoped = widget.recordLabel != null;
    final noun = getIt<MixlistFilterController>().value.playlistNounPluralLower;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recordLabel == null
              ? 'All Albums'
              : '${widget.recordLabel} Albums',
        ),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          _isLoading
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
                      padding: const EdgeInsets.fromLTRB(
                        _gridPadding,
                        _gridPadding,
                        _gridPadding,
                        88,
                      ),
                      children: [
                        if (_albums.isEmpty)
                          EmptyState(
                            message: 'No albums on $noun under this filter.',
                          )
                        else
                          Center(
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
                          const SizedBox(height: 16),
                          AdjacentNavPane(
                            noun: 'label',
                            previous: _navTarget(
                              _previousLabel,
                              isPrevious: true,
                            ),
                            next: _navTarget(_nextLabel, isPrevious: false),
                          ),
                        ],
                      ],
                    );
                  },
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
