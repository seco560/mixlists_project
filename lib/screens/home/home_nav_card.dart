import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// One destination in the home screen's grid: tinted icon, title, caption.
class HomeNavCard extends StatelessWidget {
  const HomeNavCard({
    super.key,
    required this.icon,
    this.label,
    this.title,
    this.caption,
    required this.onTap,
  }) : assert(label != null || title != null);

  static const height = 112.0;

  final IconData icon;

  /// Ignored when [title] is given -- an override for the common case of
  /// a plain, static label.
  final String? label;

  /// Overrides [label] entirely when given, for a card whose title needs
  /// to be more than static text (e.g. [PlaylistsFilterLabel]'s animated
  /// swap).
  final Widget? title;

  /// One muted line under the title.
  final Widget? caption;

  final VoidCallback onTap;

  static const titleStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
              ),
              const Spacer(),
              DefaultTextStyle.merge(
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title ?? Text(label!),
              ),
              if (caption != null)
                DefaultTextStyle.merge(
                  style: metaTextStyle.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: caption!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
