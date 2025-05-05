// lib/app/core/theme/theme_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const String _themeKey = 'is_dark_mode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
    return this;
  }

  void _loadThemeMode() {
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;

    // Apply theme
    Get.changeThemeMode(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _saveThemeMode(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _prefs.setBool(_themeKey, isDarkMode);
  }

  ThemeMode getThemeMode() {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    Get.changeThemeMode(_isDarkMode ? ThemeMode.light : ThemeMode.dark);
    _saveThemeMode(!_isDarkMode);
  }

  // Set specific theme mode
  void changeThemeMode(ThemeMode mode) {
    Get.changeThemeMode(mode);
    _saveThemeMode(mode == ThemeMode.dark);
  }
}