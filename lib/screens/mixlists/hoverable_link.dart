import 'package:flutter/material.dart';

/// A tappable substring (e.g. artist/album name) that underlines on
/// hover and ripples on tap, padded out vertically for a bigger touch target.
class HoverableLink extends StatefulWidget {
  const HoverableLink({
    super.key,
    required this.text,
    required this.onTap,
    this.overflow,
    this.maxLines,
    this.style,
    this.verticalPadding = 8,
  });

  final String text;
  final VoidCallback onTap;

  /// Unset by default; pass to hold the link to a single line instead.
  final TextOverflow? overflow;
  final int? maxLines;

  /// Overrides the default subtitle-sized link style -- for a caller that
  /// needs this tappable/hover behavior on text that isn't a subtitle
  /// (e.g. a title-sized song name). The hover underline still applies.
  final TextStyle? style;

  /// Touch-target padding above and below; dense lists shrink it.
  final double verticalPadding;

  static const defaultStyle = TextStyle(fontSize: 15, fontWeight: .w500);

  @override
  State<HoverableLink> createState() => _HoverableLinkState();
}

class _HoverableLinkState extends State<HoverableLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: .transparency,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) => setState(() => _isHovered = hovering),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 2,
            vertical: widget.verticalPadding,
          ),
          child: Text(
            widget.text,
            overflow: widget.overflow,
            maxLines: widget.maxLines,
            style: (widget.style ?? HoverableLink.defaultStyle).copyWith(
              decoration: _isHovered ? .underline : .none,
              color: _isHovered ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// One "A • B" line of entity names; parts with an `onTap` are
/// [HoverableLink]s, the rest plain text in the same style.
class LinkLine extends StatelessWidget {
  const LinkLine({
    super.key,
    required this.parts,
    this.singleLine = false,
    this.verticalPadding = 8,
  });

  final List<(String text, VoidCallback? onTap)> parts;

  /// Ellipsizes each part instead of wrapping (condensed layouts).
  final bool singleLine;

  /// Passed to each [HoverableLink].
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    Widget part((String, VoidCallback?) p) {
      final (text, onTap) = p;
      return onTap == null
          ? Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 2,
                vertical: verticalPadding,
              ),
              child: Text(
                text,
                style: HoverableLink.defaultStyle,
                maxLines: singleLine ? 1 : null,
                overflow: singleLine ? TextOverflow.ellipsis : null,
              ),
            )
          : HoverableLink(
              text: text,
              onTap: onTap,
              maxLines: singleLine ? 1 : null,
              overflow: singleLine ? TextOverflow.ellipsis : null,
              verticalPadding: verticalPadding,
            );
    }

    const separator = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('•', style: HoverableLink.defaultStyle),
    );
    if (singleLine) {
      return Row(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) separator,
            Flexible(child: part(parts[i])),
          ],
        ],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) separator,
          part(parts[i]),
        ],
      ],
    );
  }
}
