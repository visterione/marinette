// lib/app/core/theme/theme_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends GetxService {
  static const String _themeBoxName = 'theme_box';
  static const String _isDarkModeKey = 'is_dark_mode';

  late Box _box;
  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;

  Future<ThemeService> init() async {
    try {
      _box = await Hive.openBox(_themeBoxName);
      _isDarkMode.value = _box.get(_isDarkModeKey, defaultValue: false);
      return this;
    } catch (e) {
      debugPrint('Error initializing ThemeService: $e');
      rethrow;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    await _box.put(_isDarkModeKey, _isDarkMode.value);
  }

  ThemeMode getThemeMode() {
    return _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }
}
