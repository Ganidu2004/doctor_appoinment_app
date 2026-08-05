import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  static final ThemeController instance = ThemeController._();

  bool get isDarkMode => value == ThemeMode.dark;

  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      value = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
  }
}
