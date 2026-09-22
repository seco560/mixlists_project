import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_controller.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Syncs [BreadcrumbController] with the Navigator stack; registered once on
/// [MaterialApp]. Records only routes tagged via [pushWithBreadcrumb];
/// [didPop] covers every removal cause (back button, gesture, `popUntil`).
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
