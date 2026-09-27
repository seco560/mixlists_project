import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.dense = false});

  final String title;

  /// Tighter padding for list-heavy pages (the mixlist page).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: dense
          ? const EdgeInsets.fromLTRB(12, 10, 12, 4)
          : const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EmptySectionTile extends StatelessWidget {
  const EmptySectionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('—'),
    );
  }
}
