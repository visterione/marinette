import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends GetxService {
  static const String _localeKey = 'selected_locale';
  final _locale = const Locale('uk').obs;
  late SharedPreferences _prefs;

  static const List<Locale> supportedLocales = [
    Locale('uk'),
    Locale('en'),
    Locale('pl'),
    Locale('ka'),
  ];

  Future<LocalizationService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLocale = _prefs.getString(_localeKey);
    if (savedLocale != null) {
      _locale.value = Locale(savedLocale);
      Get.updateLocale(_locale.value);
    }
    return this;
  }

  Locale getCurrentLocale() => _locale.value;

  void toggleNextLocale() async {
    final currentIndex = supportedLocales.indexWhere(
      (locale) => locale.languageCode == _locale.value.languageCode,
    );
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    _locale.value = supportedLocales[nextIndex];

    await _prefs.setString(_localeKey, _locale.value.languageCode);
    Get.updateLocale(_locale.value);
  }
}
