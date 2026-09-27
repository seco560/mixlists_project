import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// The inline panel every song tile/row expands to list its mixlists.
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4, right: 16, bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                header,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final mixlist in mixlists)
              FutureBuilder<int>(
                // The filtered display number, not the raw id.
                future: getIt<MusicLibraryRepository>().getMixlistPosition(
                  mixlist.id,
                  filter: filter,
                ),
                builder: (context, snapshot) {
                  final number = snapshot.data;
                  final date = mixlist.dateCreated?.split('T')[0];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      number == null
                          ? mixlist.title
                          : '$number) ${mixlist.title}',
                      style: compactTitleTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: date == null
                        ? null
                        : Text(
                            date,
                            style: metaTextStyle.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                    onTap: () => onTap(mixlist.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
