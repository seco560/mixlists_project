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
  });

  final String text;
  final VoidCallback onTap;

  /// Unset by default; pass to hold the link to a single line instead.
  final TextOverflow? overflow;
  final int? maxLines;

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
            style: TextStyle(
              fontSize: 15,
              fontWeight: .w500,
              decoration: _isHovered ? .underline : .none,
            ),
          ),
        ),
      ),
    );
  }
}
