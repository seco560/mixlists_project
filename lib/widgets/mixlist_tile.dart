import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/widgets/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';

class MixlistTile extends StatelessWidget {
  final Mixlist mixlist;

  /// What to show before the title -- the real `mixlist.id` when
  /// browsing unfiltered, or a simple ascending position when a filter
  /// is narrowing the list (display-only; `mixlist.id` is never changed).
  final int displayNumber;
  final bool isMarking;
  final bool isMarked;
  final ValueChanged<int>? onToggleMarked;

  MixlistTile({
    super.key,
    required this.mixlist,
    int? displayNumber,
    this.isMarking = false,
    this.isMarked = false,
    this.onToggleMarked,
  }) : displayNumber = displayNumber ?? mixlist.id;

  @override
  Widget build(BuildContext context) {
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
              builder: (context, snapshot) => PlaylistCoverGrid(
                coverImageUrls: snapshot.data ?? const [],
              ),
            ),
      title: Text("$displayNumber) ${mixlist.title}", style: TextStyle(fontSize: 20, fontWeight: .bold)),
      subtitle: Text(mixlist.dateCreated.split('T')[0], style: TextStyle(fontSize: 16, fontWeight: .w600)),
      onTap: isMarking
          ? () => onToggleMarked?.call(mixlist.id)
          : () {
              Navigator.push(
                context,
                QuickStylePageRoute(
                  builder: (context) => MixlistDetailScreen(mixlist: mixlist),
                ),
              );
            },
    );
  }
}
