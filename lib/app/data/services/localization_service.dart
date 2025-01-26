import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends GetxService {
  static const List<Locale> supportedLocales = [
    Locale('uk'),
    Locale('en'),
    Locale('pl'),
    Locale('ka'),
  ];

  final _locale = const Locale('uk').obs;

  Future<LocalizationService> init() async {
    return this;
  }

  Locale getCurrentLocale() => _locale.value;

  void changeLocale(String locale) {
    _locale.value = Locale(locale);
    Get.updateLocale(_locale.value);
  }
}
