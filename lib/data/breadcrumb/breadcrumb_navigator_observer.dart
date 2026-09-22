import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Keeps [BreadcrumbController] in sync with the live [Navigator] stack by
/// watching every push/pop app-wide -- registered once on [MaterialApp].
/// Only routes tagged with a [BreadcrumbEntry] (via [pushWithBreadcrumb])
/// are ever recorded; everything else (top-level category screens,
/// dialogs, the library picker) passes through untouched.
///
/// [didPop] fires for every route actually removed regardless of cause --
/// an AppBar back button, a system back gesture, or [jumpTo]'s own
/// `popUntil` -- so no separate handling is needed for any of those.
class BreadcrumbNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final entry = route.settings.arguments;
    if (entry is BreadcrumbEntry) {
      getIt<BreadcrumbController>().recordPush(entry, route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final entry = route.settings.arguments;
    if (entry is BreadcrumbEntry) {
      getIt<BreadcrumbController>().recordPop(route);
    }
  }
}
