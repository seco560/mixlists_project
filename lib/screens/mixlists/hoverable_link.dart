import 'package:flutter/material.dart';

/// The artist/album name in a track's subtitle, tappable to jump to that
/// artist's or album's detail screen. Underlines on hover so it reads as a
/// link -- there's no other in-app precedent for a
/// tappable substring (existing nav taps are always a whole row), so this
/// is a fresh small widget rather than a shared one.
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
