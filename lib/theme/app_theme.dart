import 'package:flutter/material.dart';

/// The app's light and dark themes. Widgets read colors from [Theme]
/// instead of hardcoding `Colors.*`; album art is never tinted.
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
