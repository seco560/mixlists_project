import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/other_mixlists_list.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/explicit_badge.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// A song's detail screen (reached by clicking a song name). Artist names
/// are plain text: the schema only has a denormalized display string, so
/// only the album is linked.
class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({super.key, required this.song});

  final SongOverview song;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  /// Starts as whatever the caller passed in, then gets replaced by a
  /// freshly-fetched, filter-scoped overview on every load -- `mixlists`
  /// is filter-scoped, same as every other detail screen's related list.
  late SongOverview _song = widget.song;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getIt<MixlistFilterController>().addListener(_loadData);
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final overview = await getIt<MusicLibraryRepository>().getSongOverviewById(
      widget.song.id,
      filter: getIt<MixlistFilterController>().value,
    );
    if (!mounted) return;
    setState(() {
      if (overview != null) _song = overview;
      _isLoading = false;
    });
  }

  Future<void> _openAlbum() async {
    final overview = await getIt<MusicLibraryRepository>().getAlbumOverviewById(
      _song.albumID,
    );
    if (!mounted || overview == null) return;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.album,
        entityId: overview.id,
        title: overview.name,
        subtitle: overview.artistName,
        imageUrl: overview.coverImageURL,
      ),
      builder: (context) => AlbumDetailScreen(album: overview),
    );
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>()
        .getMixlistById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.mixlist,
        entityId: fullMixlistData.id,
        title: fullMixlistData.title,
      ),
      builder: (context) => MixlistDetailScreen(
        mixlist: fullMixlistData,
        highlightSongId: highlightSongId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = _song;
    final filter = getIt<MixlistFilterController>().value;
    return Scaffold(
      appBar: AppBar(
        title: Text(song.name),
        centerTitle: true,
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AlbumArtThumbnail(
                      imageUrl: song.albumCoverImageURL,
                      size: 96,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  song.name,
                                  style: titleTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (song.isExplicit == true) ...[
                                const SizedBox(width: 6),
                                const ExplicitBadge(),
                              ],
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              song.artistNames,
                              style: subtitleTextStyle,
                            ),
                          ),
                          HoverableLink(
                            text: song.albumName,
                            onTap: _openAlbum,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (song.mixlists.length == 1)
                ListTile(
                  title: Text('On ${song.mixlists.first.title}'),
                  onTap: () => _openMixlist(song.mixlists.first.id, song.id),
                )
              else
                OtherMixlistsList(
                  header: 'On these ${filter.playlistNounPluralLower}',
                  mixlists: song.mixlists,
                  onTap: (mixlistId) => _openMixlist(mixlistId, song.id),
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
