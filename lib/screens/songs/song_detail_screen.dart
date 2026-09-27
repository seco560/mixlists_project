import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/detail_header.dart';
import 'package:mixlists_project/widgets/shared/empty_state.dart';
import 'package:mixlists_project/widgets/shared/explicit_badge.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/mixlist_tile.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
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
  /// The song's mixlists under the current filter, oldest first, with
  /// their filtered display numbers. Null until the first load finishes:
  /// `widget.song` may have been fetched unfiltered, so its list isn't shown.
  List<(Mixlist mixlist, int number)>? _mixlists;

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
    final filter = getIt<MixlistFilterController>().value;
    final repository = getIt<MusicLibraryRepository>();
    final allFuture = repository.getAllMixlists(filter: filter);
    final overview = await repository.getSongOverviewById(
      widget.song.id,
      filter: filter,
    );
    final all = await allFuture;
    if (!mounted) return;
    final onSong = {for (final m in overview?.mixlists ?? const []) m.id};
    setState(() {
      _mixlists = [
        for (var i = 0; i < all.length; i++)
          if (onSong.contains(all[i].id)) (all[i], i + 1),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final mixlists = _mixlists;
    final filter = getIt<MixlistFilterController>().value;
    return Scaffold(
      appBar: AppBar(
        title: Text(song.name, overflow: TextOverflow.ellipsis),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          ListView(
            padding: detailListBottomPadding,
            children: [
              DetailHeader(
                artwork: AlbumArtThumbnail(
                  imageUrl: song.albumCoverImageURL,
                  size: DetailHeader.artSize,
                ),
                overline: 'Song',
                title: song.name,
                titleTrailing: song.isExplicit == true
                    ? const ExplicitBadge()
                    : null,
                lines: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(song.artistNames, style: subtitleTextStyle),
                  ),
                  LinkLine(
                    parts: [
                      (
                        song.albumName,
                        () => openAlbumById(context, song.albumID),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              if (mixlists == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (mixlists.isEmpty)
                EmptyState(
                  message:
                      'Not on any ${filter.playlistNounPluralLower} under '
                      'this filter.',
                )
              else ...[
                SectionHeader(
                  'On ${mixlists.length} '
                  '${mixlists.length == 1 ? filter.playlistNounSingularLower : filter.playlistNounPluralLower}',
                ),
                for (final (mixlist, number) in mixlists)
                  MixlistTile(
                    mixlist: mixlist,
                    displayNumber: number,
                    highlightSongId: song.id,
                  ),
              ],
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
