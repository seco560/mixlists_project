import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';

/// Pushes a [QuickStylePageRoute] tagged with [entry] as a trail stop. Use
/// for detail screens (song/album/artist/mixlist/genre/label) only; other
/// pushes stay plain `Navigator.push` so the trail ignores them.
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
