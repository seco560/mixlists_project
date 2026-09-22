import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';

class OtherMixlistsList extends StatelessWidget {
  const OtherMixlistsList({
    super.key,
    required this.mixlists,
    required this.onTap,
    this.header = 'Also appears in',
  });

  final List<MixlistSummary> mixlists;
  final ValueChanged<int> onTap;

  /// Shown above the list -- defaults to the "also appears in" wording
  /// that fits a track already sitting in one mixlist, but callers
  /// without that framing (e.g. a global songs list) can override it.
  final String header;

  @override
  Widget build(BuildContext context) {
    final filter = getIt<MixlistFilterController>().value;
    return Container(
      margin: .only(top: 4, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: .circular(12),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .only(left: 12, top: 8, right: 12, bottom: 4),
            child: Text(header, style: Theme.of(context).textTheme.labelLarge),
          ),
          for (final mixlist in mixlists)
            Material(
              child: FutureBuilder<int>(
                // The filtered display number, not the raw id.
                future: getIt<MusicLibraryRepository>().getMixlistPosition(
                  mixlist.id,
                  filter: filter,
                ),
                builder: (context, snapshot) {
                  final number = snapshot.data;
                  return ListTile(
                    dense: true,
                    visualDensity: .compact,
                    title: Text(
                      number == null
                          ? mixlist.title
                          : "$number) ${mixlist.title}",
                      style: TextStyle(fontSize: 12, fontWeight: .w600),
                    ),
                    onTap: () => onTap(mixlist.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
