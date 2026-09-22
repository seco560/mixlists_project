import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/get_it_init.dart';

/// The breadcrumb trail: derived state that mirrors whatever tagged
/// detail-screen routes are currently on the [Navigator] stack.
/// [BreadcrumbNavigatorObserver] is the only thing that should call
/// [recordPush]/[recordPop] -- this controller never pushes/pops itself,
/// [jumpTo] included, so trail state and the real navigation stack can
/// never drift apart.
class BreadcrumbController extends ChangeNotifier {
  BreadcrumbController() {
    // Every id in the trail is scoped to whichever library's database it
    // was recorded against -- meaningless (or worse, collides with an
    // unrelated entity) once the active library changes underneath it.
    getIt<ActiveLibraryController>().addListener(clear);
  }

  final List<(BreadcrumbEntry, Route<Object?>)> _frames = [];

  /// Whether the trail panel is open -- kept separate from this
  /// controller's own [notifyListeners] so [BreadcrumbOverlay] can react
  /// to open/close alone, without rebuilding on every trail change, and
  /// [BreadcrumbTrailButton] can react to trail contents alone.
  final ValueNotifier<bool> isOpen = ValueNotifier(false);

  List<BreadcrumbEntry> get trail => [for (final frame in _frames) frame.$1];

  void recordPush(BreadcrumbEntry entry, Route<Object?> route) {
    _frames.add((entry, route));
    notifyListeners();
  }

  void recordPop(Route<Object?> route) {
    final removed = _frames.length;
    _frames.removeWhere((frame) => frame.$2 == route);
    if (_frames.length != removed) notifyListeners();
  }

  void open() => isOpen.value = true;

  void close() => isOpen.value = false;

  /// Pops the navigator stack back to the frame at [index], closing the
  /// trail panel in the same motion. Matched by route identity (not
  /// kind/id) so a genuine loop through the same entity twice -- e.g.
  /// Artist A -> Album -> Artist A -- still resolves to the exact physical
  /// stack frame that was tapped, not whichever occurrence matches first.
  ///
  /// Pops via the target route's own navigator rather than a
  /// `BuildContext` lookup: the trail panel lives in [BreadcrumbOverlay],
  /// above the app's Navigator, so no context it has can find one. A
  /// no-op once the panel is already closing, so a double tap during the
  /// close animation can't pop twice.
  void jumpTo(int index) {
    if (!isOpen.value) return;
    final targetRoute = _frames[index].$2;
    close();
    targetRoute.navigator?.popUntil((route) => route == targetRoute);
  }

  void clear() {
    if (_frames.isEmpty) return;
    _frames.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    getIt<ActiveLibraryController>().removeListener(clear);
    isOpen.dispose();
    super.dispose();
  }
}
