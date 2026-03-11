import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Call once before runApp to restore the saved dark mode preference.
  Future<void> loadFromHive() async {
    final box = await Hive.openBox('user');
    final isDark = box.get('theme_dark', defaultValue: false) as bool;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    // No notifyListeners — called before runApp, no widgets listening yet.
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
