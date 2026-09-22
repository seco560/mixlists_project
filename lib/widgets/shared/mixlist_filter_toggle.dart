import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Tri-state segmented toggle for [MixlistFilterController] -- drop into
/// any AppBar's `actions`. Reads/writes the shared controller directly,
/// so every screen that includes this stays in sync with no extra wiring
/// beyond listening for the reload itself.
class MixlistFilterToggle extends StatelessWidget {
  const MixlistFilterToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<MixlistFilterController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ValueListenableBuilder<MixlistFilter>(
        valueListenable: controller,
        builder: (context, filter, _) {
          return SegmentedButton<MixlistFilter>(
            segments: const [
              ButtonSegment(
                value: MixlistFilter.mixlistsOnly,
                icon: Icon(Icons.star),
                tooltip: 'Mixlists only',
              ),
              ButtonSegment(
                value: MixlistFilter.all,
                icon: Icon(Icons.all_inclusive),
                tooltip: 'All playlists',
              ),
              ButtonSegment(
                value: MixlistFilter.nonMixlistsOnly,
                icon: Icon(Icons.star_border),
                tooltip: 'Non-mixlists only',
              ),
            ],
            selected: {filter},
            showSelectedIcon: false,
            onSelectionChanged: (selected) => controller.value = selected.first,
          );
        },
      ),
    );
  }
}
