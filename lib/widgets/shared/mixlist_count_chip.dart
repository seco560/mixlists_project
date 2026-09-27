import 'package:flutter/material.dart';

/// The one "this song is on N mixlists" affordance: a chip that expands an
/// inline [OtherMixlistsList], used by every song tile/row.
class MixlistCountChip extends StatelessWidget {
  const MixlistCountChip({
    super.key,
    required this.label,
    required this.isExpanded,
    required this.onPressed,
  });

  final String label;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.queue_music, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, size: 16),
          ),
        ],
      ),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
