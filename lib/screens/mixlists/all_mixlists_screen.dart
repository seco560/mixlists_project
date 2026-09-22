import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/screens/mixlists/add_mixlist_screen.dart';
import 'package:mixlists_project/widgets/mixlists/chronological_sort_toggle.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';

class AllMixlistsScreen extends StatefulWidget {
  const AllMixlistsScreen({super.key});

  @override
  State<AllMixlistsScreen> createState() => _AllMixlistsScreenState();
}

class _AllMixlistsScreenState extends State<AllMixlistsScreen> {
  List<Mixlist> _mixlists = [];
  bool _isLoading = false;
  bool _isMarkingMode = false;
  Set<int> _markedIds = {};
  ChronologicalOrder _order = ChronologicalOrder.chronological;

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

  /// While marking, always show every playlist regardless of the global
  /// filter -- otherwise a currently-unmarked (or currently-marked)
  /// playlist filtered out of view couldn't be toggled at all.
  MixlistFilter get _effectiveFilter => _isMarkingMode
      ? MixlistFilter.all
      : getIt<MixlistFilterController>().value;

  /// The real global filter (ignoring marking mode's override), for wording.
  MixlistFilter get _globalFilter => getIt<MixlistFilterController>().value;

  /// [_mixlists] (oldest first) with display numbers from that order, then
  /// arranged per [_order], so reversing never renumbers anything.
  List<(Mixlist mixlist, int displayNumber)> get _displayItems {
    final showingAll = _effectiveFilter == MixlistFilter.all;
    final items = [
      for (var i = 0; i < _mixlists.length; i++)
        (_mixlists[i], showingAll ? _mixlists[i].id : i + 1),
    ];
    return _order == ChronologicalOrder.chronological
        ? items
        : items.reversed.toList();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<MusicLibraryRepository>().getAllMixlists(
        filter: _effectiveFilter,
      );

      setState(() {
        _mixlists = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading playlists: $e')));
      }
    }
  }

  void _startMarking() {
    setState(() {
      _isMarkingMode = true;
    });
    _loadData().then((_) {
      if (!mounted) return;
      setState(() {
        _markedIds = _mixlists
            .where((m) => m.isMixlist)
            .map((m) => m.id)
            .toSet();
      });
    });
  }

  void _cancelMarking() {
    setState(() {
      _isMarkingMode = false;
      _markedIds = {};
    });
    _loadData();
  }

  void _toggleMarked(int id) {
    setState(() {
      if (!_markedIds.add(id)) _markedIds.remove(id);
    });
  }

  Future<void> _finishMarking() async {
    final flags = {for (final m in _mixlists) m.id: _markedIds.contains(m.id)};
    await getIt<MusicLibraryRepository>().setMixlistFlags(flags);
    setState(() {
      _isMarkingMode = false;
      _markedIds = {};
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _displayItems;
    return Scaffold(
      appBar: AppBar(
        title: Text(_globalFilter.allScreenHeader),
        centerTitle: true,
        actions: [
          if (!_isMarkingMode)
            ChronologicalSortToggle(
              value: _order,
              onChanged: (order) => setState(() => _order = order),
            ),
          if (!_isMarkingMode) const MixlistFilterToggle(),
          if (!_isMarkingMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add ${_globalFilter.playlistNounSingular}',
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  QuickStylePageRoute(
                    builder: (context) => const AddMixlistScreen(),
                  ),
                );
                if (added == true) _loadData();
              },
            ),
          IconButton(
            icon: Icon(_isMarkingMode ? Icons.close : Icons.playlist_add_check),
            tooltip: _isMarkingMode ? 'Cancel marking' : 'Mark Mixlists',
            onPressed: _isMarkingMode ? _cancelMarking : _startMarking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mixlists.isEmpty
          ? const Center(child: Text("No data found"))
          : ListView.separated(
              separatorBuilder: (_, _) => Divider(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final (mixlist, displayNumber) = displayItems[index];
                return MixlistTile(
                  mixlist: mixlist,
                  displayNumber: displayNumber,
                  isMarking: _isMarkingMode,
                  isMarked: _markedIds.contains(mixlist.id),
                  onToggleMarked: _toggleMarked,
                );
              },
            ),
      floatingActionButton: _isMarkingMode
          ? FloatingActionButton.extended(
              onPressed: _finishMarking,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            )
          : null,
    );
  }
}
