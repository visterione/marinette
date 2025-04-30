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
      // Загрузка только украинского языка
      final uk = await rootBundle.loadString('assets/i18n/uk.json');
      _translations['uk'] = Map<String, String>.from(json.decode(uk));

      // Загрузка файлов локализации для админ-панели
      try {
        final adminUk = await rootBundle.loadString('assets/i18n/admin_uk.json');
        // Добавление админ-переводов к основным переводам
        _translations['uk']?.addAll(Map<String, String>.from(json.decode(adminUk)));

        // Загрузка переводов для прямого редактирования
        final directUk = await rootBundle.loadString('assets/i18n/admin_direct_uk.json');
        _translations['uk']?.addAll(Map<String, String>.from(json.decode(directUk)));
      } catch (e) {
        print('Error loading admin translations: $e');
      }

      // Загрузка динамических переводов из Firestore
      await _loadTranslationsFromFirestore();
    } catch (e) {
      print('Error loading translations: $e');
    }
  }

  // Загрузка переводов из Firestore
  static Future<void> _loadTranslationsFromFirestore() async {
    try {
      final ukDoc = await FirebaseFirestore.instance.collection('translations').doc('uk').get();

      if (ukDoc.exists && ukDoc.data() != null) {
        final Map<String, dynamic> ukData = ukDoc.data()!;
        ukData.forEach((key, value) {
          if (value is String) {
            _translations['uk']?[key] = value;
          }
        });
      }

      // Обновляем переводы в GetX
      Get.clearTranslations();
      Get.addTranslations(_translations);

      print('Dynamic translations loaded successfully');
    } catch (e) {
      print('Error loading dynamic translations: $e');
    }
  }

  // Метод для обновления переводов в runtime
  static Future<void> refreshTranslations() async {
    try {
      await _loadTranslationsFromFirestore();

      // Обновляем текущую локализацию для применения изменений
      Get.updateLocale(const Locale('uk'));
    } catch (e) {
      print('Error refreshing translations: $e');
    }
  }
}