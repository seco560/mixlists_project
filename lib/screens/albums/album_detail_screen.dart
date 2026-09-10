import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/models/view_models/album_song_appearance.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await getIt<MusicLibraryRepository>()
          .getAlbumSongAppearances(widget.album.id);
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

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>().getMixlistById(mixlistId);
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
    final album = widget.album;
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
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
                      ClipRRect(
                        borderRadius: .circular(4),
                        child: CachedNetworkImage(
                          imageUrl: album.coverImageURL,
                          width: 96,
                          height: 96,
                          fit: .cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(album.name, style: titleTextStyle),
                            Text(album.artistName, style: subtitleTextStyle),
                            Text(
                              album.releaseDate.split('T')[0],
                              style: metaTextStyle,
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
                      title: song.songName,
                      leadingImageUrl: album.coverImageURL,
                      subtitle: Text(
                        'On ${song.mixlists.length} mixlist${song.mixlists.length == 1 ? '' : 's'}',
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
