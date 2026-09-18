import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/songs/song_table_cell.dart';
import 'package:mixlists_project/screens/songs/song_table_row.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';

/// Hardcoded bespoke grid mirroring [AllArtistsScreen]; see that class's
/// doc comment for why this is duplicated rather than shared.
class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  static const _columnLabels = ['#', 'Name', 'Artist', 'Album', 'Appearances'];
  static const _fixedColumnWidths = [60.0, 160.0, 160.0, 110.0];
  static const _minNameWidth = 220.0;
  static const _columnIsNumeric = [true, false, false, false, true];
  static const _columnIsSortable = [false, true, true, true, true];
  static const _nameColumnIndex = 1;
  static const _smallHeaderFontLabels = {'Appearances'};

  static const _headerTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  static const _nameTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const _countTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  List<double> _resolveColumnWidths(double availableWidth) {
    final fixedTotal = _fixedColumnWidths.reduce((a, b) => a + b);
    final nameWidth = (availableWidth - fixedTotal) < _minNameWidth
        ? _minNameWidth
        : availableWidth - fixedTotal;
    return [_fixedColumnWidths[0], nameWidth, ..._fixedColumnWidths.skip(1)];
  }

  List<SongOverview> _songs = [];
  bool _isLoading = false;
  int _sortColumnIndex = _nameColumnIndex;
  bool _sortAscending = true;
  bool _oneHitWondersExpanded = false;

  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();

  /// If a song features only once, show it underneath
  static bool _isOneHitWonder(SongOverview song) => song.appearanceCount == 1;

  @override
  void initState() {
    super.initState();
    _bodyHorizontalController.addListener(_syncHeaderScroll);
    getIt<MixlistFilterController>().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    _bodyHorizontalController.removeListener(_syncHeaderScroll);
    getIt<MixlistFilterController>().removeListener(_loadData);
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (_headerHorizontalController.hasClients) {
      _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<MusicLibraryRepository>().getSongOverviews(
        filter: getIt<MixlistFilterController>().value,
      );
      _sortSongs(result, _sortColumnIndex, _sortAscending);

      setState(() {
        _songs = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading songs: $e')));
      }
    }
  }

  void _sortSongs(List<SongOverview> songs, int columnIndex, bool ascending) {
    switch (columnIndex) {
      case 1: // Name
        songs.sort(
          (a, b) => ascending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case 2: // Artist
        songs.sort(
          (a, b) => ascending
              ? a.artistNames.toLowerCase().compareTo(
                  b.artistNames.toLowerCase(),
                )
              : b.artistNames.toLowerCase().compareTo(
                  a.artistNames.toLowerCase(),
                ),
        );
        break;
      case 3: // Album
        songs.sort(
          (a, b) => ascending
              ? a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase())
              : b.albumName.toLowerCase().compareTo(a.albumName.toLowerCase()),
        );
        break;
      case 4: // Appearances
        songs.sort(
          (a, b) => ascending
              ? a.appearanceCount.compareTo(b.appearanceCount)
              : b.appearanceCount.compareTo(a.appearanceCount),
        );
        break;
    }
  }

  void _onHeaderTap(int columnIndex) {
    if (!_columnIsSortable[columnIndex]) return;
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = columnIndex == _nameColumnIndex;
      }
      _sortSongs(_songs, _sortColumnIndex, _sortAscending);
    });
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>()
        .getMixlistById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MixlistDetailScreen(
          mixlist: fullMixlistData,
          highlightSongId: highlightSongId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oneHitWonders = _songs.where(_isOneHitWonder).toList();
    final regularSongs = _songs.where((s) => !_isOneHitWonder(s)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("All Songs"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? const Center(child: Text("No data found"))
          : LayoutBuilder(
              builder: (context, constraints) {
                final widths = _resolveColumnWidths(constraints.maxWidth);
                return Column(
                  children: [
                    Material(
                      elevation: 2,
                      child: SingleChildScrollView(
                        controller: _headerHorizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: _buildHeaderRow(widths),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          controller: _bodyHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              for (var i = 0; i < regularSongs.length; i++)
                                SongTableRow(
                                  key: ValueKey(regularSongs[i].id),
                                  song: regularSongs[i],
                                  widths: widths,
                                  rowNumber: i + 1,
                                  onOpenMixlist: _openMixlist,
                                ),
                              if (oneHitWonders.isNotEmpty)
                                _buildOneHitWondersRow(
                                  oneHitWonders.length,
                                  widths,
                                ),
                              if (_oneHitWondersExpanded)
                                for (var i = 0; i < oneHitWonders.length; i++)
                                  SongTableRow(
                                    key: ValueKey(oneHitWonders[i].id),
                                    song: oneHitWonders[i],
                                    widths: widths,
                                    rowNumber: regularSongs.length + i + 1,
                                    onOpenMixlist: _openMixlist,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHeaderRow(List<double> widths) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _columnLabels.length; i++)
          SongTableHeaderCell(
            width: widths[i],
            label: _columnLabels[i],
            textStyle: _smallHeaderFontLabels.contains(_columnLabels[i])
                ? _headerTextStyle.copyWith(fontSize: 12)
                : _headerTextStyle,
            numeric: _columnIsNumeric[i],
            isSorted: _sortColumnIndex == i,
            sortAscending: _sortAscending,
            onTap: _columnIsSortable[i] ? () => _onHeaderTap(i) : null,
          ),
      ],
    );
  }

  Widget _buildOneHitWondersRow(int count, List<double> widths) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () =>
            setState(() => _oneHitWondersExpanded = !_oneHitWondersExpanded),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SongTableCell(
                  width: widths[0],
                  numeric: _columnIsNumeric[0],
                  child: Icon(
                    _oneHitWondersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ),
                SongTableCell(
                  width: widths[1],
                  numeric: _columnIsNumeric[1],
                  child: Text(
                    '$count one-hit wonder${count == 1 ? '' : 's'}',
                    style: _nameTextStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SongTableCell(
                  width: widths[2],
                  numeric: _columnIsNumeric[2],
                  child: const Text('—', style: _countTextStyle),
                ),
                SongTableCell(
                  width: widths[3],
                  numeric: _columnIsNumeric[3],
                  child: const Text('—', style: _countTextStyle),
                ),
                SongTableCell(
                  width: widths[4],
                  numeric: _columnIsNumeric[4],
                  child: const Text('1', style: _countTextStyle),
                ),
              ],
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
