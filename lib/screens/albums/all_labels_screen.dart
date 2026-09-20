import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/search/album_result_tile.dart';
import 'package:mixlists_project/widgets/category_sort_toggle.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// Every distinct record label, grouped in Dart from [MusicLibraryRepository.getAlbumOverviews].
/// Albums with no label are collapsed at the bottom, one-hit-wonder style.
class AllLabelsScreen extends StatefulWidget {
  const AllLabelsScreen({super.key});

  @override
  State<AllLabelsScreen> createState() => _AllLabelsScreenState();
}

class _AllLabelsScreenState extends State<AllLabelsScreen> {
  List<String> _labels = [];
  Map<String, int> _albumCountByLabel = {};
  List<AlbumOverview> _albumsWithoutLabel = [];
  bool _isLoading = false;
  bool _withoutLabelExpanded = false;
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
      final albums = await getIt<MusicLibraryRepository>().getAlbumOverviews(
        filter: getIt<MixlistFilterController>().value,
      );

      final albumsByLabel = <String, List<AlbumOverview>>{};
      final withoutLabel = <AlbumOverview>[];
      for (final album in albums) {
        final recordLabel = album.recordLabel;
        if (recordLabel == null || recordLabel.isEmpty) {
          withoutLabel.add(album);
          continue;
        }
        albumsByLabel.putIfAbsent(recordLabel, () => []).add(album);
      }
      final labels = albumsByLabel.keys.toList()..sort();
      withoutLabel.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        _labels = labels;
        _albumCountByLabel = {
          for (final label in labels) label: albumsByLabel[label]!.length,
        };
        _albumsWithoutLabel = withoutLabel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading labels: $e')));
      }
    }
  }

  void _openLabel(String recordLabel) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumsGridScreen(recordLabel: recordLabel),
      ),
    );
  }

  void _openAlbum(AlbumOverview album) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumDetailScreen(album: album),
      ),
    );
  }

  /// [_labels] sorted per [_sortOrder] -- computed on demand, not stored.
  List<String> get _sortedLabels {
    if (_sortOrder == CategorySortOrder.alphabetical) return _labels;
    final labels = List.of(_labels);
    labels.sort((a, b) {
      final byCount = _albumCountByLabel[b]!.compareTo(_albumCountByLabel[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _labels.isEmpty && _albumsWithoutLabel.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Labels"),
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
                for (final label in _sortedLabels) ...[
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(label, style: titleTextStyle),
                    subtitle: Text(
                      '${_albumCountByLabel[label]} album${_albumCountByLabel[label] == 1 ? '' : 's'}',
                      style: metaTextStyle,
                    ),
                    onTap: () => _openLabel(label),
                  ),
                  Divider(),
                ],
                if (_albumsWithoutLabel.isNotEmpty) ...[
                  _buildWithoutLabelRow(),
                  if (_withoutLabelExpanded)
                    for (final album in _albumsWithoutLabel)
                      AlbumResultTile(
                        album: album,
                        onTap: () => _openAlbum(album),
                      ),
                  Divider(),
                ],
              ],
            ),
    );
  }

  Widget _buildWithoutLabelRow() {
    final count = _albumsWithoutLabel.length;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () =>
            setState(() => _withoutLabelExpanded = !_withoutLabelExpanded),
        child: ListTile(
          leading: Icon(
            _withoutLabelExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          title: Text(
            '$count album${count == 1 ? '' : 's'} without a record label',
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
