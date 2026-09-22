import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Floating "open the trail" arrow -- embedded by each detail screen in
/// its own `Stack` (there's no shared app scaffold to hook into instead),
/// the same way [ThemeModeToggle] is embedded on [HomeScreen]. Renders
/// nothing once the trail is empty, i.e. on every top-level category
/// screen, and on a detail screen only until its own push is recorded.
class BreadcrumbTrailButton extends StatelessWidget {
  const BreadcrumbTrailButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<BreadcrumbController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.trail.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Trail',
              onPressed: controller.open,
              child: const Icon(Icons.arrow_upward),
            ),
    );
  }
}
