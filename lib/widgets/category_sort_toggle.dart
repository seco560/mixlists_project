import 'package:flutter/material.dart';

/// How [CategorySortToggle] orders a list of named categories (genres,
/// record labels, ...) each with a count attached.
enum CategorySortOrder {
  /// Highest count first.
  byCount,

  /// A-Z by name.
  alphabetical,
}

/// Two-state segmented toggle between [CategorySortOrder]s -- drop into
/// an AppBar's `actions` next to [MixlistFilterToggle]. Unlike that
/// toggle, this one is screen-local state (each browse-by-category
/// screen controls its own list ordering), so it's a plain controlled
/// widget rather than reading a shared getIt controller.
class CategorySortToggle extends StatelessWidget {
  const CategorySortToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CategorySortOrder value;
  final ValueChanged<CategorySortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<CategorySortOrder>(
        segments: const [
          ButtonSegment(
            value: CategorySortOrder.byCount,
            icon: Icon(Icons.sort),
            tooltip: 'Sort by count',
          ),
          ButtonSegment(
            value: CategorySortOrder.alphabetical,
            icon: Icon(Icons.sort_by_alpha),
            tooltip: 'Sort alphabetically',
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}
