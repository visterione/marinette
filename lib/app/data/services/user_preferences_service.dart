import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class UserPreferencesService extends GetxService {
  static const String _userBoxName = 'user_preferences';
  static const String _userIdKey = 'user_id';

  late Box _box;
  final RxString userId = ''.obs;

  Future<UserPreferencesService> init() async {
    try {
      _box = await Hive.openBox(_userBoxName);
      String? savedUserId = _box.get(_userIdKey);

      if (savedUserId == null) {
        savedUserId = _generateUserId();
        await _box.put(_userIdKey, savedUserId);
      }

      userId.value = savedUserId;
      return this;
    } catch (e) {
      debugPrint('Error initializing UserPreferencesService: $e');
      rethrow;
    }
  }

  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String getCurrentUserId() {
    return userId.value;
  }

  Future<void> setBool(String key, bool value) async {
    try {
      await _box.put(key, value);
    } catch (e) {
      debugPrint('Error setting bool preference: $e');
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      return _box.get(key) as bool?;
    } catch (e) {
      debugPrint('Error getting bool preference: $e');
      return null;
    }
  }

  @override
  void onClose() {
    _box.close();
    super.onClose();
  }
}
