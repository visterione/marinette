// lib/app/data/services/localization_service.dart
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinette/config/translations/app_translations.dart';

class LocalizationService extends GetxService {
  static const String _languageKey = 'selected_language';
  static const List<Locale> supportedLocales = [
    Locale('uk'), // Ukrainian
    Locale('en'), // English
  ];

  // Initialize the service
  Future<LocalizationService> init() async {
    // Load the current language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    // If there's a saved language, update the app locale
    if (savedLanguage != null) {
      await updateLocale(Locale(savedLanguage));
    }

    return this;
  }

  // Get the current language
  String? getCurrentLanguage() {
    return Get.locale?.languageCode;
  }

  // Change the language and update the UI
  Future<bool> changeLanguage(String languageCode) async {
    try {
      // Check if the language is supported
      final isSupported = supportedLocales.any((locale) => locale.languageCode == languageCode);
      if (!isSupported) {
        return false;
      }

      // Save the selected language
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Update the app locale
      await updateLocale(Locale(languageCode));

      // Refresh translations
      await Messages.refreshTranslations();

      return true;
    } catch (e) {
      print('Error changing language: $e');
      return false;
    }
  }

  // Update the locale
  Future<void> updateLocale(Locale locale) async {
    Get.updateLocale(locale);
  }
}