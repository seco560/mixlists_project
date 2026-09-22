import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/get_it_init.dart';

/// The breadcrumb trail, mirroring the tagged detail routes on the Navigator.
/// Only [BreadcrumbNavigatorObserver] mutates it; it never pushes/pops itself.
class BreadcrumbController extends ChangeNotifier {
  BreadcrumbController() {
    // Every id in the trail is scoped to whichever library's database it
    // was recorded against -- meaningless (or worse, collides with an
    // unrelated entity) once the active library changes underneath it.
    getIt<ActiveLibraryController>().addListener(clear);
  }

  final List<(BreadcrumbEntry, Route<Object?>)> _frames = [];

  /// Panel open state, separate from [notifyListeners] so the overlay and the
  /// trail button each rebuild only on the change they care about.
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

  /// Pops back to the frame at [index], matched by route identity so loops
  /// resolve to the tapped frame. Uses the route's own navigator (the panel
  /// sits above the app's Navigator); no-op once closing, so no double pops.
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
