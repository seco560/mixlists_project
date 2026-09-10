import 'package:flutter/material.dart';

/// A full-width, tappable "go to this section" row for the home screen --
/// stacking these instead of sitting three `ElevatedButton`s side by side
/// in a `Row` means nothing has to squeeze to fit a narrow width.
class HomeNavCard extends StatelessWidget {
  const HomeNavCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
