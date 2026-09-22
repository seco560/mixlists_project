import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's active [ThemeMode] and persists the user's choice.
///
/// Deliberately binary (light/dark, no "system" option) so the home screen
/// toggle always has one obvious next state to switch to.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._(this._prefs, super.initial);

  final SharedPreferences _prefs;

  static const _prefsKey = 'theme_mode';

  /// Light mode by default, unless the user previously chose dark.
  factory ThemeController.load(SharedPreferences prefs) {
    final initial = prefs.getString(_prefsKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    return ThemeController._(prefs, initial);
  }

  Future<void> toggle() async {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(
      _prefsKey,
      value == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
