import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/album_song_appearance.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/category_tile.dart';
import 'package:mixlists_project/widgets/shared/detail_header.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/shared/song_mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

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
      final songs = await getIt<MusicLibraryRepository>()
          .getAlbumSongAppearances(
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

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final recordLabel = album.recordLabel;
    // Compilations/splits credit some songs to their own artists; if every
    // song is, the album artist is a placeholder (e.g. Various Artists).
    final isCompilation = _songs.any((s) => s.creditedArtistId != null);
    final isPlaceholderArtist =
        _songs.isNotEmpty && _songs.every((s) => s.creditedArtistId != null);
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name, overflow: TextOverflow.ellipsis),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: detailListBottomPadding,
                  children: [
                    DetailHeader(
                      artwork: AlbumArtThumbnail(
                        imageUrl: album.coverImageURL,
                        size: DetailHeader.artSize,
                      ),
                      overline: 'Album',
                      title: album.name,
                      lines: [
                        LinkLine(
                          parts: [
                            (
                              album.artistName,
                              isPlaceholderArtist
                                  ? null
                                  : () =>
                                        openArtistById(context, album.artistId),
                            ),
                          ],
                        ),
                        DetailFacts([
                          album.releaseDate.split('T')[0],
                          '${_songs.length} ${_songs.length == 1 ? 'song' : 'songs'} featured',
                        ]),
                      ],
                      chips: [
                        if (recordLabel != null && recordLabel.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(
                              CategoryTile.labelIcon,
                              size: 16,
                            ),
                            label: Text(recordLabel),
                            onPressed: () => openLabel(context, recordLabel),
                          ),
                      ],
                    ),
                    const Divider(),
                    SectionHeader('Songs (${_songs.length})'),
                    if (_songs.isEmpty)
                      const EmptySectionTile()
                    else
                      for (final song in _songs)
                        SongMixlistTile(
                          songId: song.songId,
                          title:
                              '${song.albumTrackNumber ?? '?'}) ${song.songName}',
                          isExplicit: song.isExplicit == true,
                          leadingImageUrl: album.coverImageURL,
                          subtitle: Column(
                            crossAxisAlignment: .start,
                            children: [
                              if (isCompilation)
                                LinkLine(
                                  singleLine: true,
                                  parts: [
                                    (
                                      song.artistNames,
                                      () => openArtistById(
                                        context,
                                        song.creditedArtistId ?? album.artistId,
                                      ),
                                    ),
                                  ],
                                ),
                              Text(
                                'Added on ${song.datesAdded.map((d) => d.split('T')[0]).join(', ')}',
                                style: metaTextStyle,
                              ),
                            ],
                          ),
                          mixlists: song.mixlists,
                        ),
                  ],
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
