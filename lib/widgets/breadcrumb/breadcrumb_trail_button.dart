import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Floating "open the trail" button, embedded in each detail screen's
/// `Stack`. Renders nothing while the trail is empty.
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
