import 'package:flutter/material.dart';

/// Boxed "E" mark after a song's title, same shorthand official
/// packaging/streaming apps use for an explicit track.
class ExplicitBadge extends StatelessWidget {
  const ExplicitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'E',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
