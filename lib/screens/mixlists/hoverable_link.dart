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
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Text(
            widget.text,
            overflow: widget.overflow,
            maxLines: widget.maxLines,
            style:
                (widget.style ??
                        const TextStyle(fontSize: 15, fontWeight: .w500))
                    .copyWith(decoration: _isHovered ? .underline : .none),
          ),
        ),
      ),
    );
  }
}
