import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

class MixlistTile extends StatelessWidget {
  final Mixlist mixlist;

  /// What to show before the title -- the real `mixlist.id` when
  /// browsing unfiltered, or a simple ascending position when a filter
  /// is narrowing the list (display-only; `mixlist.id` is never changed).
  final int displayNumber;

  /// Shown after the date when given; callers without counts omit it.
  final int? songCount;
  final bool isMarking;
  final bool isMarked;
  final ValueChanged<int>? onToggleMarked;

  /// Scrolled to and flashed when the mixlist opens (e.g. from a song).
  final int? highlightSongId;

  MixlistTile({
    super.key,
    required this.mixlist,
    int? displayNumber,
    this.songCount,
    this.isMarking = false,
    this.isMarked = false,
    this.onToggleMarked,
    this.highlightSongId,
  }) : displayNumber = displayNumber ?? mixlist.id;

  @override
  Widget build(BuildContext context) {
    final date = mixlist.dateCreated.split('T')[0];
    return ListTile(
      leading: isMarking
          ? Checkbox(
              value: isMarked,
              onChanged: (_) => onToggleMarked?.call(mixlist.id),
            )
          : FutureBuilder<List<String?>>(
              future: getIt<MusicLibraryRepository>().getMixlistCoverArt(
                mixlist.id,
              ),
              builder: (context, snapshot) =>
                  PlaylistCoverGrid(coverImageUrls: snapshot.data ?? const []),
            ),
      title: Text(
        '$displayNumber) ${mixlist.title}',
        style: titleTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        songCount == null
            ? date
            : '$date · $songCount ${songCount == 1 ? 'song' : 'songs'}',
        style: subtitleTextStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isMarking ? null : const Icon(Icons.chevron_right),
      onTap: isMarking
          ? () => onToggleMarked?.call(mixlist.id)
          : () =>
                openMixlist(context, mixlist, highlightSongId: highlightSongId),
    );
  }
}
