import 'package:flutter/material.dart';

// IMPORTANT:
// Add this package to your pubspec.yaml:
//
// dependencies:
//   shared_preferences: ^2.5.3
//
// Then run:
// flutter pub get

import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // =========================================================
  // STORAGE KEY
  // =========================================================

  static const String _themeKey = 'is_dark_mode';

  // =========================================================
  // STATE
  // =========================================================

  bool _isDarkMode = false;
  bool _isLoaded = false;

  // =========================================================
  // GETTERS
  // =========================================================

  bool get isDarkMode => _isDarkMode;

  bool get isLightMode => !_isDarkMode;

  bool get isLoaded => _isLoaded;

  ThemeMode get themeMode {
    return _isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  ThemeProvider() {
    loadTheme();
  }

  // =========================================================
  // LOAD SAVED THEME
  // =========================================================

  Future<void> loadTheme() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      _isDarkMode =
          prefs.getBool(_themeKey) ?? false;
    } catch (e) {
      debugPrint(
        'Failed to load theme: $e',
      );

      _isDarkMode = false;
    }

    _isLoaded = true;
    notifyListeners();
  }

  // =========================================================
  // TOGGLE THEME
  // =========================================================

  Future<void> toggleTheme(
      bool value,
      ) async {
    _isDarkMode = value;
    notifyListeners();

    try {
      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setBool(
        _themeKey,
        value,
      );
    } catch (e) {
      debugPrint(
        'Failed to save theme: $e',
      );
    }
  }

  // =========================================================
  // ENABLE DARK MODE
  // =========================================================

  Future<void> enableDarkMode() async {
    await toggleTheme(true);
  }

  // =========================================================
  // ENABLE LIGHT MODE
  // =========================================================

  Future<void> enableLightMode() async {
    await toggleTheme(false);
  }

  // =========================================================
  // SWITCH THEME
  // =========================================================

  Future<void> switchTheme() async {
    await toggleTheme(!_isDarkMode);
  }
}