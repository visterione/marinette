import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends GetxService {
  static const String _localeKey = 'selected_locale';
  static const List<Locale> supportedLocales = [
    Locale('uk'),
  ];

  final locale = Rxn<Locale>();
  late SharedPreferences _prefs;

  Future<LocalizationService> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedLocale = _prefs.getString(_localeKey);
      if (savedLocale != null) {
        locale.value = Locale(savedLocale);
        Get.updateLocale(locale.value!);
      } else {
        locale.value = const Locale('uk');
      }
      debugPrint('LocalizationService initialized with locale: ${locale.value?.languageCode}');
      return this;
    } catch (e) {
      debugPrint('Error initializing LocalizationService: $e');
      return this;
    }
  }

  Locale getCurrentLocale() => locale.value ?? const Locale('uk');

  // Этот метод мы оставляем, но он будет всегда использовать 'uk'
  Future<void> changeLocale(String languageCode) async {
    try {
      if (languageCode == locale.value?.languageCode) return;

      locale.value = Locale('uk');
      await _prefs.setString(_localeKey, 'uk');
      Get.updateLocale(locale.value!);
      debugPrint('Locale set to: uk');
    } catch (e) {
      debugPrint('Error changing locale: $e');
    }
  }

  String getLanguageName(String languageCode) {
    return 'Українська';
  }
}