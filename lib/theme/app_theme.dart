import 'package:flutter/material.dart';

/// The app's light and dark themes. Widgets read colors from [Theme]
/// instead of hardcoding `Colors.*`; album art is never tinted.
abstract final class AppTheme {
  // Navy ("bleumarin") seed -- keeps dark mode reading as a traditional
  // night-blue theme instead of the warm/brownish cast a hue like orange
  // casts over Material 3's generated dark surfaces.
  static const _seedColor = Color(0xFF1B3A6B);

  // Explicit deep-navy dark surface ladder rather than the near-neutral
  // grey Material 3 would otherwise derive (cards, chips and empty chart
  // cells all sit on the surfaceContainer* tones).
  static const _darkSurfaceLowest = Color(0xFF09101E);
  static const _darkSurface = Color(0xFF0D1526);
  static const _darkSurfaceLow = Color(0xFF121C31);
  static const _darkSurfaceContainer = Color(0xFF142036);
  static const _darkSurfaceElevated = Color(0xFF18253F);
  static const _darkSurfaceHighest = Color(0xFF1F2E4C);

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
        surfaceDim: _darkSurface,
        surfaceContainerLowest: _darkSurfaceLowest,
        surfaceContainerLow: _darkSurfaceLow,
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerHigh: _darkSurfaceElevated,
        surfaceContainerHighest: _darkSurfaceHighest,
      );
    }

    final appBarBackground = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.primaryContainer;
    final appBarForeground = isDark
        ? colorScheme.onSurface
        : colorScheme.onPrimaryContainer;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: appBarForeground,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
      ),
    );
  }
}
