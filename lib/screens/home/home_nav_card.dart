import 'package:flutter/material.dart';

class HomeNavCard extends StatelessWidget {
  const HomeNavCard({
    super.key,
    required this.icon,
    this.label,
    this.title,
    required this.onTap,
  }) : assert(label != null || title != null);

  final IconData icon;

  /// Ignored when [title] is given -- an override for the common case of
  /// a plain, static label.
  final String? label;

  /// Overrides [label] entirely when given, for a card whose title needs
  /// to be more than static text (e.g. [PlaylistsFilterLabel]'s animated
  /// swap).
  final Widget? title;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title:
            title ??
            Text(
              label!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
