import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// An artist row wherever artists are listed: album mosaic (as in the
/// breadcrumb trail), name, and song/album/mixlist counts.
class ArtistResultTile extends StatelessWidget {
  const ArtistResultTile({
    super.key,
    required this.artist,
    required this.onTap,
  });

  final ArtistOverview artist;
  final VoidCallback onTap;

  static String _count(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  @override
  Widget build(BuildContext context) {
    final filter = getIt<MixlistFilterController>().value;
    return ListTile(
      leading: PlaylistCoverGrid(
        coverImageUrls: [for (final a in artist.albums.take(4)) a.coverImageURL],
      ),
      title: Text(
        artist.name,
        style: titleTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _count(artist.uniqueSongCount, 'song', 'songs'),
          _count(artist.albums.length, 'album', 'albums'),
          _count(
            artist.mixlists.length,
            filter.playlistNounSingularLower,
            filter.playlistNounPluralLower,
          ),
        ].join(' · '),
        style: metaTextStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
