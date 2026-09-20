import 'package:flutter/material.dart';

/// Central definitions for the app's light and dark themes.
///
/// Widgets should pull colors from `Theme.of(context).colorScheme`,
/// `Theme.of(context).dividerColor`, etc. rather than hardcoding `Colors.*`
/// values, so they follow whichever of these two themes is active. Album
/// art is a deliberate exception: it's never tinted by theme colors so
/// covers stay legible against a dark background.
abstract final class AppTheme {
  // Navy ("bleumarin") seed -- keeps dark mode reading as a traditional
  // night-blue theme instead of the warm/brownish cast a hue like orange
  // casts over Material 3's generated dark surfaces.
  static const _seedColor = Color(0xFF1B3A6B);

  // Explicit deep-navy dark surfaces rather than the near-neutral grey
  // Material 3 would otherwise derive, so dark mode reads as night-blue
  // rather than generic grey.
  static const _darkSurface = Color(0xFF0D1526);
  static const _darkSurfaceElevated = Color(0xFF16223A);

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    var colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    if (isDark) {
      colorScheme = colorScheme.copyWith(
        surface: _darkSurface,
        surfaceContainerHigh: _darkSurfaceElevated,
      );
    }

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : Colors.lightBlueAccent,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey,
      ),
    );
  }
}
