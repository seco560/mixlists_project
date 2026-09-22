import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_chip.dart';

/// The two-thirds-height panel [BreadcrumbOverlay] slides up: the current
/// navigation trail as [BreadcrumbChip]s connected by arrow glyphs,
/// snaking back and forth down the panel in as many columns as the width
/// allows (scrolling vertically once it outgrows the panel's height).
/// Tapping a chip jumps back to that stop and closes the panel in the
/// same motion.
class BreadcrumbTrailPanel extends StatefulWidget {
  const BreadcrumbTrailPanel({super.key});

  @override
  State<BreadcrumbTrailPanel> createState() => _BreadcrumbTrailPanelState();
}

class _BreadcrumbTrailPanelState extends State<BreadcrumbTrailPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // BreadcrumbOverlay keeps this panel mounted for the app's whole
    // lifetime (just slid offscreen while closed), so this has to happen
    // on every open, not once in initState.
    getIt<BreadcrumbController>().isOpen.addListener(_onOpenChanged);
  }

  @override
  void dispose() {
    getIt<BreadcrumbController>().isOpen.removeListener(_onOpenChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // Land already scrolled down to the current (last) entry, rather than
  // animating there after the panel has finished sliding up.
  void _onOpenChanged() {
    if (!getIt<BreadcrumbController>().isOpen.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  static const double _arrowSize = 18;
  static const double _arrowSlotWidth = _arrowSize + 4;

  /// How many chips (with the arrows between them) fit side by side in
  /// [width] -- never fewer than one, however narrow the screen.
  static int _columnsFor(double width) => math.max(
    1,
    ((width + _arrowSlotWidth) / (BreadcrumbChip.outerWidth + _arrowSlotWidth))
        .floor(),
  );

  Widget _arrow(BuildContext context, IconData icon) => SizedBox(
    width: _arrowSlotWidth,
    child: Icon(
      icon,
      size: _arrowSize,
      color: Theme.of(context).colorScheme.outline,
    ),
  );

  /// Lays [trail] out as a snake over a fixed grid of [columns]: even rows
  /// run left to right, odd rows right to left (starting under the column
  /// the previous row ended on), with a down arrow at each turn. Every row
  /// keeps all [columns] slots, empty ones included, so columns line up
  /// across rows and a partial last row still starts at the right edge.
  Widget _buildSnake(
    BuildContext context,
    List<BreadcrumbEntry> trail,
    int columns,
  ) {
    const emptyChip = SizedBox(width: BreadcrumbChip.outerWidth);
    const emptyArrow = SizedBox(width: _arrowSlotWidth);
    final rowCount = (trail.length / columns).ceil();

    int? indexAt(int row, int column) {
      final offset = row.isEven ? column : columns - 1 - column;
      final index = row * columns + offset;
      return index < trail.length ? index : null;
    }

    Widget chipRow(int row) {
      final forward = row.isEven;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var column = 0; column < columns; column++) ...[
            if (column > 0)
              indexAt(row, column - 1) != null && indexAt(row, column) != null
                  ? _arrow(
                      context,
                      forward ? Icons.arrow_forward : Icons.arrow_back,
                    )
                  : emptyArrow,
            switch (indexAt(row, column)) {
              null => emptyChip,
              final index => BreadcrumbChip(
                entry: trail[index],
                isCurrent: index == trail.length - 1,
                onTap: () => getIt<BreadcrumbController>().jumpTo(index),
              ),
            },
          ],
        ],
      );
    }

    // Sits under the column the row above ended on: the right edge after
    // a forward row, the left edge after a backward one.
    Widget turn(int row) => Padding(
      padding: EdgeInsets.only(
        left: row.isEven
            ? (columns - 1) * (BreadcrumbChip.outerWidth + _arrowSlotWidth)
            : 0,
      ),
      child: SizedBox(
        width: BreadcrumbChip.outerWidth,
        child: Icon(
          Icons.arrow_downward,
          size: _arrowSize,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < rowCount; row++) ...[
            if (row > 0) turn(row - 1),
            chipRow(row),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = getIt<BreadcrumbController>();
    // This panel lives in BreadcrumbOverlay's own Overlay, outside the
    // app's MaterialApp/Scaffold tree, so it needs its own Material
    // ancestor for the chips' InkWells and the close IconButton.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Breadcrumb Trail',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(fontWeight: .bold),
                        textAlign: .center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: controller.close,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final trail = controller.trail;
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) => _buildSnake(
                          context,
                          trail,
                          _columnsFor(constraints.maxWidth),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
