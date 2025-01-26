import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _translations;

  static final Map<String, Map<String, String>> _translations = {};

  static Future<void> loadTranslations() async {
    try {
      final en = await rootBundle.loadString('assets/i18n/en.json');
      final uk = await rootBundle.loadString('assets/i18n/uk.json');
      final pl = await rootBundle.loadString('assets/i18n/pl.json');
      final ka = await rootBundle.loadString('assets/i18n/ka.json');

      _translations['en'] = Map<String, String>.from(json.decode(en));
      _translations['uk'] = Map<String, String>.from(json.decode(uk));
      _translations['pl'] = Map<String, String>.from(json.decode(pl));
      _translations['ka'] = Map<String, String>.from(json.decode(ka));
    } catch (e) {
      print('Error loading translations: $e');
    }
  }
}
