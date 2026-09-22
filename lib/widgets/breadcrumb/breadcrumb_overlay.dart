import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_panel.dart';

/// Wraps the app (via `MaterialApp.builder`) so one [AnimationController]
/// drives both the app pulling back and [BreadcrumbTrailPanel] sliding up.
class BreadcrumbOverlay extends StatefulWidget {
  const BreadcrumbOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<BreadcrumbOverlay> createState() => _BreadcrumbOverlayState();
}

class _BreadcrumbOverlayState extends State<BreadcrumbOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  BreadcrumbController get _breadcrumb => getIt<BreadcrumbController>();

  double _dragExtent = 0;

  // A single persistent entry: Overlay only reads `initialEntries` on first
  // mount, so this entry's own AnimatedBuilder listens to `_t` directly.
  late final List<OverlayEntry> _entries = [
    OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          final panelHeight = MediaQuery.sizeOf(context).height * 2 / 3;
          return Stack(
            children: [
              Transform.translate(
                offset: Offset(0, -40 * t),
                child: Transform.scale(
                  scale: 1 - 0.08 * t,
                  child: widget.child,
                ),
              ),
              if (t > 0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _breadcrumb.close,
                    child: Opacity(
                      opacity: 0.6 * t,
                      child: const ColoredBox(color: Colors.black),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: IgnorePointer(
                  ignoring: t == 0,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - t),
                    child: Opacity(
                      opacity: t.clamp(0, 1),
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) =>
                            _onVerticalDragUpdate(details, panelHeight),
                        onVerticalDragEnd: _onVerticalDragEnd,
                        child: const BreadcrumbTrailPanel(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breadcrumb.isOpen.addListener(_onOpenChanged);
  }

  void _onOpenChanged() {
    _breadcrumb.isOpen.value ? _controller.forward() : _controller.reverse();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double panelHeight) {
    _dragExtent += details.delta.dy;
    if (_dragExtent < 0) _dragExtent = 0;
    _controller.value = 1 - (_dragExtent / panelHeight).clamp(0, 1);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final shouldClose =
        _controller.value < 0.6 || details.velocity.pixelsPerSecond.dy > 600;
    _dragExtent = 0;
    if (shouldClose) {
      _breadcrumb.close();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _breadcrumb.isOpen.removeListener(_onOpenChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        return PopScope(
          canPop: _t.value == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _breadcrumb.close();
          },
          // Sits above the app's Navigator, so it needs its own
          // Overlay for the panel's tooltips (see [_entries]).
          child: Overlay(initialEntries: _entries),
        );
      },
    );
  }
}
