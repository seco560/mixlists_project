import 'package:flutter/material.dart';

/// How [ChronologicalSortToggle] orders a chronologically-sortable list
/// (currently just [AllMixlistsScreen]) -- purely a display order, never
/// touches the underlying position numbers (see the toggle's own
/// call site for how that invariant is kept).
enum ChronologicalOrder {
  /// Oldest first -- the default.
  chronological,

  /// Newest first.
  reverseChronological,
}

/// Two-state segmented toggle between [ChronologicalOrder]s -- screen-local
/// state, unlike [MixlistFilterToggle], so it's a plain controlled widget.
class ChronologicalSortToggle extends StatelessWidget {
  const ChronologicalSortToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ChronologicalOrder value;
  final ValueChanged<ChronologicalOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<ChronologicalOrder>(
        segments: const [
          ButtonSegment(
            value: ChronologicalOrder.chronological,
            icon: Icon(Icons.arrow_downward),
            tooltip: 'Chronological (oldest first)',
          ),
          ButtonSegment(
            value: ChronologicalOrder.reverseChronological,
            icon: Icon(Icons.arrow_upward),
            tooltip: 'Reverse chronological (newest first)',
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}
