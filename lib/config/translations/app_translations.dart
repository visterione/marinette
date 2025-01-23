import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {};
}

class LocalizationService extends GetxService {
  final RxString currentLocale = 'uk'.obs;
  final Map<String, Map<String, String>> translations = {};

  Future<LocalizationService> init() async {
    try {
      await loadTranslations();
      return this;
    } catch (e) {
      print('Error initializing LocalizationService: $e');
      return this;
    }
  }

  Future<void> loadTranslations() async {
    try {
      final en = await rootBundle.loadString('assets/i18n/en.json');
      final uk = await rootBundle.loadString('assets/i18n/uk.json');
      final pl = await rootBundle.loadString('assets/i18n/pl.json');
      final ka = await rootBundle.loadString('assets/i18n/ka.json');

      translations['en'] = Map<String, String>.from(json.decode(en));
      translations['uk'] = Map<String, String>.from(json.decode(uk));
      translations['pl'] = Map<String, String>.from(json.decode(pl));
      translations['ka'] = Map<String, String>.from(json.decode(ka));

      Get.addTranslations(translations);
    } catch (e) {
      print('Error loading translations: $e');
    }
  }

  void changeLocale(String locale) {
    if (locale == currentLocale.value) return;

    currentLocale.value = locale;
    Get.updateLocale(Locale(locale));
  }

  String getCurrentLocale() => currentLocale.value;
}
