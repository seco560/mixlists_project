import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/album_song_appearance.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/section_header.dart';
import 'package:mixlists_project/widgets/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumOverview album;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<AlbumSongAppearance> _songs = [];
  bool _isLoading = true;
  String? _error;

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
    try {
      final songs = await getIt<MusicLibraryRepository>().getAlbumSongAppearances(
        widget.album.id,
        filter: getIt<MixlistFilterController>().value,
      );
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading songs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openArtist(int artistId) async {
    final overview = await getIt<MusicLibraryRepository>()
        .getArtistOverviewById(artistId);
    if (!mounted || overview == null) return;
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => ArtistDetailScreen(artist: overview),
      ),
    );
  }

  void _openLabel(String recordLabel) {
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => AlbumsGridScreen(recordLabel: recordLabel),
      ),
    );
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>()
        .getMixlistById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => MixlistDetailScreen(
          mixlist: fullMixlistData,
          highlightSongId: highlightSongId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: const [MixlistFilterToggle()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AlbumArtThumbnail(
                        imageUrl: album.coverImageURL,
                        size: 96,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(album.name, style: titleTextStyle),
                            HoverableLink(
                              text: album.artistName,
                              onTap: () => _openArtist(album.artistId),
                            ),
                            Text(
                              album.releaseDate.split('T')[0],
                              style: metaTextStyle,
                            ),
                            if (album.recordLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ActionChip(
                                  label: Text(album.recordLabel!),
                                  onPressed: () => _openLabel(album.recordLabel!),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SectionHeader('Songs (${_songs.length})'),
                if (_songs.isEmpty)
                  const EmptySectionTile()
                else
                  for (final song in _songs)
                    SongMixlistTile(
                      songId: song.songId,
                      title:
                          '${song.albumTrackNumber ?? '?'}) ${song.songName}',
                      leadingImageUrl: album.coverImageURL,
                      subtitle: Text(
                        'Added on ${song.datesAdded.map((d) => d.split('T')[0]).join(', ')}',
                        style: subtitleTextStyle,
                      ),
                      mixlists: song.mixlists,
                      onOpenMixlist: _openMixlist,
                    ),
              ],
            ),
    );
  }
}
