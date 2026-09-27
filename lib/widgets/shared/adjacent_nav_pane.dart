import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// One side of an [AdjacentNavPane]; the pane greys out a missing side.
class AdjacentNavTarget {
  const AdjacentNavTarget({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// "Previous X / Next X" pair of cards shared by every screen that steps
/// through a sequence (mixlists, genres, labels).
class AdjacentNavPane extends StatelessWidget {
  const AdjacentNavPane({
    super.key,
    required this.noun,
    required this.previous,
    required this.next,
    this.dense = false,
  });

  /// Lower-case, e.g. "mixlist" -> "Previous mixlist".
  final String noun;
  final AdjacentNavTarget? previous;
  final AdjacentNavTarget? next;

  /// Tighter padding for list-heavy pages (the mixlist page).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 4 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavCard(
              label: 'Previous $noun',
              target: previous,
              isPrevious: true,
              dense: dense,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NavCard(
              label: 'Next $noun',
              target: next,
              isPrevious: false,
              dense: dense,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.label,
    required this.target,
    required this.isPrevious,
    required this.dense,
  });

  final String label;
  final AdjacentNavTarget? target;
  final bool isPrevious;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final scheme = Theme.of(context).colorScheme;
    final align = isPrevious
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
    final text = Flexible(
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: metaTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
          Text(
            target?.title ?? '—',
            overflow: TextOverflow.ellipsis,
            style: subtitleTextStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          if (target?.subtitle != null)
            Text(
              target!.subtitle!,
              style: metaTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
    final icon = Icon(
      isPrevious ? Icons.arrow_back : Icons.arrow_forward,
      color: scheme.primary,
    );
    return Opacity(
      opacity: target == null ? 0.4 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          mouseCursor: target == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          onTap: target?.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 10 : 12,
              vertical: dense ? 6 : 10,
            ),
            child: Row(
              mainAxisAlignment: isPrevious
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: isPrevious
                  ? [icon, const SizedBox(width: 10), text]
                  : [text, const SizedBox(width: 10), icon],
            ),
          ),
        ),
      ),
    );
  }
}
