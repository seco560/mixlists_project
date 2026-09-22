import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';

/// [Navigator.push] a [QuickStylePageRoute], tagged with [entry] so
/// [BreadcrumbNavigatorObserver] records it as a trail stop. Use this
/// instead of a plain `Navigator.push(context, QuickStylePageRoute(...))`
/// for any push that lands on a genuine detail screen (song/album/artist/
/// mixlist/genre/label) -- top-level category screens and other
/// non-detail pushes should stay on the plain, untagged form so they
/// remain invisible to the trail.
Future<T?> pushWithBreadcrumb<T>(
  BuildContext context, {
  required BreadcrumbEntry entry,
  required WidgetBuilder builder,
  bool? isReverse,
}) {
  return Navigator.push<T>(
    context,
    QuickStylePageRoute<T>(
      builder: builder,
      isReverse: isReverse,
      settings: RouteSettings(arguments: entry),
    ),
  );
}
