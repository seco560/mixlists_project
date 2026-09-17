import 'package:flutter/material.dart';

/// A tappable substring (e.g. artist/album name) that underlines on hover
/// so it reads as a link.
class HoverableLink extends StatefulWidget {
  const HoverableLink({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<HoverableLink> createState() => _HoverableLinkState();
}

class _HoverableLinkState extends State<HoverableLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: .w500,
            decoration: _isHovered ? .underline : .none,
          ),
        ),
      ),
    );
  }
}
