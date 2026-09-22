import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_chip.dart';

/// The almost-fullscreen panel [BreadcrumbOverlay] slides up: a horizontal
/// strip of [BreadcrumbChip]s, connected by arrow glyphs, that mirrors the
/// current navigation trail. Tapping a chip jumps back to that stop and
/// closes the panel in the same motion.
class BreadcrumbTrailPanel extends StatefulWidget {
  const BreadcrumbTrailPanel({super.key});

  @override
  State<BreadcrumbTrailPanel> createState() => _BreadcrumbTrailPanelState();
}

class _BreadcrumbTrailPanelState extends State<BreadcrumbTrailPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isJumping = false;

  @override
  void initState() {
    super.initState();
    // Land already scrolled to the current (last) entry, rather than
    // animating there after the panel has finished sliding up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    if (_isJumping) return;
    _isJumping = true;
    getIt<BreadcrumbController>().jumpTo(context, index);
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
                        'Trail',
                        style: Theme.of(context).textTheme.titleMedium,
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
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          for (final (index, entry) in trail.indexed) ...[
                            if (index > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            BreadcrumbChip(
                              entry: entry,
                              isCurrent: index == trail.length - 1,
                              onTap: () => _jumpTo(index),
                            ),
                          ],
                        ],
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
