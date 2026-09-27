import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// Top-of-page summary shared by every detail screen: artwork, a small
/// overline (entity kind or number), the title, detail lines and chips.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.artwork,
    required this.overline,
    required this.title,
    this.titleTrailing,
    this.lines = const [],
    this.chips = const [],
    this.dense = false,
  });

  /// Sized by the caller at [artSize].
  final Widget artwork;
  final String overline;
  final String title;

  /// E.g. an explicit badge next to the title.
  final Widget? titleTrailing;
  final List<Widget> lines;
  final List<Widget> chips;

  /// Tighter padding for list-heavy pages (the mixlist page).
  final bool dense;

  static const artSize = 112.0;
  static const denseArtSize = 88.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: dense
          ? const EdgeInsets.fromLTRB(12, 10, 12, 6)
          : const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          artwork,
          SizedBox(width: dense ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline.toUpperCase(),
                  style: metaTextStyle.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 8),
                      titleTrailing!,
                    ],
                  ],
                ),
                DefaultTextStyle.merge(
                  style: TextStyle(color: scheme.onSurfaceVariant),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted "a · b · c" line of facts for a [DetailHeader].
class DetailFacts extends StatelessWidget {
  const DetailFacts(this.facts, {super.key});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(facts.join('  ·  '), style: subtitleTextStyle),
    );
  }
}
