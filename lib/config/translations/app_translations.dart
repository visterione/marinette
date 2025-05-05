// lib/config/translations/app_translations.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _translations;

  static final Map<String, Map<String, String>> _translations = {};

  static Future<void> loadTranslations() async {
    try {
      // Load Ukrainian language
      final uk = await rootBundle.loadString('assets/i18n/uk.json');
      _translations['uk'] = Map<String, String>.from(json.decode(uk));

      // Load English language
      try {
        final en = await rootBundle.loadString('assets/i18n/en.json');
        _translations['en'] = Map<String, String>.from(json.decode(en));
      } catch (e) {
        print('Error loading English translations: $e');
        // Create empty map if English file doesn't exist yet
        _translations['en'] = {};
      }

      // Load admin translations for both languages
      try {
        // Ukrainian admin
        final adminUk = await rootBundle.loadString('assets/i18n/admin_uk.json');
        _translations['uk']?.addAll(Map<String, String>.from(json.decode(adminUk)));

        final directUk = await rootBundle.loadString('assets/i18n/admin_direct_uk.json');
        _translations['uk']?.addAll(Map<String, String>.from(json.decode(directUk)));

        // English admin
        try {
          final adminEn = await rootBundle.loadString('assets/i18n/admin_en.json');
          _translations['en']?.addAll(Map<String, String>.from(json.decode(adminEn)));

          final directEn = await rootBundle.loadString('assets/i18n/admin_direct_en.json');
          _translations['en']?.addAll(Map<String, String>.from(json.decode(directEn)));
        } catch (e) {
          print('Error loading English admin translations: $e');
        }
      } catch (e) {
        print('Error loading admin translations: $e');
      }

      // Load dynamic translations from Firestore
      await _loadTranslationsFromFirestore();
    } catch (e) {
      print('Error loading translations: $e');
    }
  }

  // Load translations from Firestore
  static Future<void> _loadTranslationsFromFirestore() async {
    try {
      // Load Ukrainian translations
      final ukDoc = await FirebaseFirestore.instance.collection('translations').doc('uk').get();
      if (ukDoc.exists && ukDoc.data() != null) {
        final Map<String, dynamic> ukData = ukDoc.data()!;
        ukData.forEach((key, value) {
          if (value is String) {
            _translations['uk']?[key] = value;
          }
        });
      }

      // Load English translations
      final enDoc = await FirebaseFirestore.instance.collection('translations').doc('en').get();
      if (enDoc.exists && enDoc.data() != null) {
        final Map<String, dynamic> enData = enDoc.data()!;
        enData.forEach((key, value) {
          if (value is String) {
            _translations['en']?[key] = value;
          }
        });
      }

      // Update GetX translations
      Get.clearTranslations();
      Get.addTranslations(_translations);

      print('Dynamic translations loaded successfully');
    } catch (e) {
      print('Error loading dynamic translations: $e');
    }
  }

  // Method to refresh translations at runtime
  static Future<void> refreshTranslations() async {
    try {
      await _loadTranslationsFromFirestore();

      // Update current localization to apply changes
      final currentLocale = Get.locale ?? const Locale('uk');
      Get.updateLocale(currentLocale);
    } catch (e) {
      print('Error refreshing translations: $e');
    }
  }
}