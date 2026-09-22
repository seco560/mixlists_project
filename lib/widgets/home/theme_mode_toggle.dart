import 'package:flutter/material.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/theme/theme_controller.dart';

/// Sun/moon icon button on the home screen that flips [ThemeController]
/// between light and dark mode.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: controller.toggle,
        );
      },
    );
  }
}
