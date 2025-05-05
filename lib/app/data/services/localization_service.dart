// lib/app/data/services/localization_service.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/config/translations/app_translations.dart';

class LocalizationService extends GetxService {
  static const String _languageKey = 'selected_language';
  late SharedPreferences _prefs;
  String? _currentLanguage;

  // Define supported locales
  static const List<Locale> supportedLocales = [
    Locale('uk'),
    Locale('en'),
  ];

  // Map for language names
  static const Map<String, String> languageNames = {
    'uk': 'Українська',
    'en': 'English',
  };

  Future<LocalizationService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLanguage();
    return this;
  }

  void _loadLanguage() {
    _currentLanguage = _prefs.getString(_languageKey) ?? 'uk';

    // Apply language
    if (_currentLanguage != null) {
      Get.updateLocale(Locale(_currentLanguage!));
    }
  }

  Future<void> _saveLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _prefs.setString(_languageKey, languageCode);
  }

  String? getCurrentLanguage() {
    return _currentLanguage;
  }

  // Change language
  Future<bool> changeLanguage(String languageCode) async {
    try {
      // Check if language is supported
      if (!supportedLocales.map((e) => e.languageCode).contains(languageCode)) {
        return false;
      }

      // Update locale
      Get.updateLocale(Locale(languageCode));

      // Save language
      await _saveLanguage(languageCode);

      // Refresh translations (optional if using dynamic translations)
      await Messages.refreshTranslations();

      return true;
    } catch (e) {
      debugPrint('Error changing language: $e');
      return false;
    }
  }

  // Get localized name of current language
  String getCurrentLanguageName() {
    final code = _currentLanguage ?? 'uk';
    return languageNames[code] ?? 'Unknown';
  }
}