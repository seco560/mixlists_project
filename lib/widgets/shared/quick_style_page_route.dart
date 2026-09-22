import 'package:flutter/material.dart';

/// Slide + fade push transition, from the right, or from the left when
/// [isReverse] (e.g. a "previous" button that should feel like going back).
class QuickStylePageRoute<T> extends PageRouteBuilder<T> {
  QuickStylePageRoute({
    required WidgetBuilder builder,
    bool? isReverse,
    super.settings,
  }) : super(
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
