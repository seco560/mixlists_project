import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// A genre or record label row: icon, name and an optional count line.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.icon,
    required this.name,
    required this.onTap,
    this.countLabel,
  });

  static const genreIcon = Icons.sell_outlined;
  static const labelIcon = Icons.business_outlined;

  final IconData icon;
  final String name;
  final String? countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: scheme.onSecondaryContainer),
      ),
      title: Text(name, style: titleTextStyle, overflow: TextOverflow.ellipsis),
      subtitle: countLabel == null
          ? null
          : Text(
              countLabel!,
              style: metaTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
