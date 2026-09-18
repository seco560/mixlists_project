import 'package:flutter/material.dart';

/// A push transition that slides in with a fade -- from the right by
/// default (a normal forward push), or from the left when [isReverse]
/// is true, reading as "going back" -- e.g. for a "previous" nav button
/// that pushes a new route but should still feel like stepping back.
class QuickStylePageRoute<T> extends PageRouteBuilder<T> {
  QuickStylePageRoute({required WidgetBuilder builder, bool? isReverse})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isReverse == true ? -1 : 1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
