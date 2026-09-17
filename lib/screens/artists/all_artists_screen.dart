import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/artists/artist_table_cell.dart';

/// Hardcoded bespoke grid; not extensible enough to reuse for another
/// grid, reimplement the general shape as a new widget instead.
class AllArtistsScreen extends StatefulWidget {
  const AllArtistsScreen({super.key});

  @override
  State<AllArtistsScreen> createState() => _AllArtistsScreenState();
}

class _AllArtistsScreenState extends State<AllArtistsScreen> {
  static const _columnLabels = [
    '#',
    'ID',
    'Name',
    'Appearances',
    'Songs',
    'Albums',
    'Mixlists',
  ];
  static const _fixedColumnWidths = [60.0, 60.0, 90.0, 100.0, 90.0, 80.0];
  static const _minNameWidth = 220.0;
  static const _columnIsNumeric = [true, true, false, true, true, true, true];
  static const _columnIsSortable = [false, true, true, true, true, true, true];
  static const _nameColumnIndex = 2;
  static const _smallHeaderFontLabels = {'Appearances', 'Mixlists'};

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
    return [
      _fixedColumnWidths[0],
      _fixedColumnWidths[1],
      nameWidth,
      ..._fixedColumnWidths.skip(2),
    ];
  }

  List<ArtistOverview> _artists = [];
  bool _isLoading = false;
  int _sortColumnIndex = 1;
  bool _sortAscending = true;
  bool _oneHitWondersExpanded = false;

  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();

  /// If an artist features only once, show them underneath
  static bool _isOneHitWonder(ArtistOverview artist) =>
      artist.uniqueSongCount == 1;

  @override
  void initState() {
    super.initState();
    _bodyHorizontalController.addListener(_syncHeaderScroll);
    _loadData();
  }

  @override
  void dispose() {
    _bodyHorizontalController.removeListener(_syncHeaderScroll);
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
      final result = await getIt<MusicLibraryRepository>().getArtistOverviews();
      _sortArtists(result, _sortColumnIndex, _sortAscending);

      setState(() {
        _artists = result;
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

  void _sortArtists(
    List<ArtistOverview> artists,
    int columnIndex,
    bool ascending,
  ) {
    switch (columnIndex) {
      case 1: // ID
        artists.sort(
          (a, b) => ascending ? a.id.compareTo(b.id) : b.id.compareTo(a.id),
        );
        break;
      case 2: // Name
        artists.sort(
          (a, b) => ascending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case 3: // Appearances
        artists.sort(
          (a, b) => ascending
              ? a.appearanceCount.compareTo(b.appearanceCount)
              : b.appearanceCount.compareTo(a.appearanceCount),
        );
        break;
      case 4: // Songs
        artists.sort(
          (a, b) => ascending
              ? a.uniqueSongCount.compareTo(b.uniqueSongCount)
              : b.uniqueSongCount.compareTo(a.uniqueSongCount),
        );
        break;
      case 5: // Albums
        artists.sort(
          (a, b) => ascending
              ? a.albums.length.compareTo(b.albums.length)
              : b.albums.length.compareTo(a.albums.length),
        );
        break;
      case 6: // Mixlists
        artists.sort(
          (a, b) => ascending
              ? a.mixlists.length.compareTo(b.mixlists.length)
              : b.mixlists.length.compareTo(a.mixlists.length),
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
      _sortArtists(_artists, _sortColumnIndex, _sortAscending);
    });
  }

  @override
  Widget build(BuildContext context) {
    final oneHitWonders = _artists.where(_isOneHitWonder).toList();
    final regularArtists = _artists.where((a) => !_isOneHitWonder(a)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("All Artists"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artists.isEmpty
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
                              for (var i = 0; i < regularArtists.length; i++)
                                _buildRow(regularArtists[i], widths, i + 1),
                              if (oneHitWonders.isNotEmpty)
                                _buildOneHitWondersRow(
                                  oneHitWonders.length,
                                  widths,
                                ),
                              if (_oneHitWondersExpanded)
                                for (var i = 0; i < oneHitWonders.length; i++)
                                  _buildRow(
                                    oneHitWonders[i],
                                    widths,
                                    regularArtists.length + i + 1,
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
          ArtistTableHeaderCell(
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
                ArtistTableCell(
                  width: widths[0],
                  numeric: _columnIsNumeric[0],
                  child: Icon(
                    _oneHitWondersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ),
                ArtistTableCell(
                  width: widths[1],
                  numeric: _columnIsNumeric[1],
                  child: const Text('—', style: _countTextStyle),
                ),
                ArtistTableCell(
                  width: widths[2],
                  numeric: _columnIsNumeric[2],
                  child: Text(
                    '$count one-hit wonder${count == 1 ? '' : 's'}',
                    style: _nameTextStyle.copyWith(
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ArtistTableCell(
                  width: widths[3],
                  numeric: _columnIsNumeric[3],
                  child: const Text('1', style: _countTextStyle),
                ),
                ArtistTableCell(
                  width: widths[4],
                  numeric: _columnIsNumeric[4],
                  child: const Text('1', style: _countTextStyle),
                ),
                ArtistTableCell(
                  width: widths[5],
                  numeric: _columnIsNumeric[5],
                  child: const Text('1', style: _countTextStyle),
                ),
                ArtistTableCell(
                  width: widths[6],
                  numeric: _columnIsNumeric[6],
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

  Widget _buildRow(ArtistOverview artist, List<double> widths, int rowNumber) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtistDetailScreen(artist: artist),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArtistTableCell(
                width: widths[0],
                numeric: _columnIsNumeric[0],
                child: Text('$rowNumber', style: _countTextStyle),
              ),
              ArtistTableCell(
                width: widths[1],
                numeric: _columnIsNumeric[1],
                child: Text('${artist.id}', style: _countTextStyle),
              ),
              ArtistTableCell(
                width: widths[2],
                numeric: _columnIsNumeric[2],
                child: Text(
                  artist.name,
                  style: _nameTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ArtistTableCell(
                width: widths[3],
                numeric: _columnIsNumeric[3],
                child: Text(
                  '${artist.appearanceCount}',
                  style: _countTextStyle,
                ),
              ),
              ArtistTableCell(
                width: widths[4],
                numeric: _columnIsNumeric[4],
                child: Text(
                  '${artist.uniqueSongCount}',
                  style: _countTextStyle,
                ),
              ),

              ArtistTableCell(
                width: widths[5],
                numeric: _columnIsNumeric[5],
                child: Text('${artist.albums.length}', style: _countTextStyle),
              ),
              ArtistTableCell(
                width: widths[6],
                numeric: _columnIsNumeric[6],
                child: Text(
                  '${artist.mixlists.length}',
                  style: _countTextStyle,
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
