import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {};
}

class LocalizationService extends GetxService {
  final RxString currentLocale = 'en'.obs;
  final Map<String, Map<String, String>> translations = {};

  Future<LocalizationService> init() async {
    await loadTranslations();
    return this;
  }

  Future<void> loadTranslations() async {
    final en = await rootBundle.loadString('assets/i18n/en.json');
    final uk = await rootBundle.loadString('assets/i18n/uk.json');

    translations['en'] = Map<String, String>.from(json.decode(en));
    translations['uk'] = Map<String, String>.from(json.decode(uk));

    Get.addTranslations(translations);
  }

  void changeLocale(String locale) {
    currentLocale.value = locale;
    Get.updateLocale(Locale(locale));
  }

  String getCurrentLocale() => currentLocale.value;
}
