// lib/app/data/services/daily_tips_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:marinette/app/data/models/daily_tip.dart';

class DailyTipsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<DailyTip> tips = <DailyTip>[].obs;
  final RxBool isLoading = false.obs;

  static const String collectionName = 'daily_tips';

  // Add a method to expose the FirebaseFirestore instance
  FirebaseFirestore getFirestore() {
    return _firestore;
  }

  Future<DailyTipsService> init() async {
    await loadTips();
    return this;
  }

  // Загрузка советов из Firestore
  Future<void> loadTips() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('order')
          .get();

      List<DailyTip> loadedTips = snapshot.docs.map((doc) {
        return DailyTip.fromFirestore(doc.id, doc.data());
      }).toList();

      tips.value = loadedTips;
      debugPrint('Loaded ${tips.length} daily tips');
    } catch (e) {
      debugPrint('Error loading daily tips: $e');
      // Если не получилось загрузить из Firestore, используем локальные данные
      _initializeLocalTips();
    } finally {
      isLoading.value = false;
    }
  }

  // Инициализация локальных данных, если не удалось загрузить из Firestore
  void _initializeLocalTips() {
    tips.value = [
      DailyTip(id: '1', tip: 'ice_cube_therapy', icon: '❄️', order: 0),
      DailyTip(id: '2', tip: 'apply_thinnest_to_thickest', icon: '🧴', order: 1),
      DailyTip(id: '3', tip: 'spf_on_cloudy_days', icon: '☀️', order: 2),
      DailyTip(id: '4', tip: 'stay_hydrated', icon: '💧', order: 3),
      DailyTip(id: '5', tip: 'clean_makeup_brushes', icon: '🖌️', order: 4),
      DailyTip(id: '6', tip: 'beauty_sleep', icon: '😴', order: 5),
      DailyTip(id: '7', tip: 'pat_dont_rub', icon: '👁️', order: 6),
      DailyTip(id: '8', tip: 'silk_pillowcase', icon: '🛏️', order: 7),
      DailyTip(id: '9', tip: 'face_masks_on_clean_skin', icon: '🎭', order: 8),
      DailyTip(id: '10', tip: 'dont_forget_neck', icon: '✨', order: 9),
    ];
  }

  // Добавление нового совета
  Future<bool> addTip(String tip, String icon) async {
    try {
      isLoading.value = true;

      int nextOrder = 0;
      if (tips.isNotEmpty) {
        nextOrder = tips.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1;
      }

      final newTip = DailyTip(
        id: '', // Firestore создаст ID
        tip: tip,
        icon: icon,
        order: nextOrder,
      );

      final docRef = await _firestore
          .collection(collectionName)
          .add(newTip.toFirestore());

      // Добавляем в локальный список
      tips.add(DailyTip(
        id: docRef.id,
        tip: tip,
        icon: icon,
        order: nextOrder,
      ));

      // Сортируем по порядку
      tips.sort((a, b) => a.order.compareTo(b.order));

      return true;
    } catch (e) {
      debugPrint('Error adding daily tip: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Обновление совета
  Future<bool> updateTip(DailyTip tip) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection(collectionName)
          .doc(tip.id)
          .update(tip.toFirestore());

      // Обновляем в локальном списке
      final index = tips.indexWhere((t) => t.id == tip.id);
      if (index != -1) {
        tips[index] = tip;
      }

      // Сортируем по порядку
      tips.sort((a, b) => a.order.compareTo(b.order));

      return true;
    } catch (e) {
      debugPrint('Error updating daily tip: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Удаление совета
  Future<bool> deleteTip(String tipId) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection(collectionName)
          .doc(tipId)
          .delete();

      // Удаляем из локального списка
      tips.removeWhere((t) => t.id == tipId);

      return true;
    } catch (e) {
      debugPrint('Error deleting daily tip: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Изменение порядка советов
  Future<bool> reorderTips(int oldIndex, int newIndex) async {
    try {
      isLoading.value = true;

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = tips.removeAt(oldIndex);
      tips.insert(newIndex, item);

      // Обновляем порядок всех элементов
      for (int i = 0; i < tips.length; i++) {
        final tip = tips[i].copyWith(order: i);
        tips[i] = tip;

        await _firestore
            .collection(collectionName)
            .doc(tip.id)
            .update({'order': i});
      }

      return true;
    } catch (e) {
      debugPrint('Error reordering daily tips: $e');
      // В случае ошибки перезагружаем данные
      await loadTips();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Синхронизация локальных данных с Firestore
  Future<bool> synchronizeLocalTips() async {
    try {
      isLoading.value = true;

      // Удаляем все существующие советы
      final snapshot = await _firestore.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Добавляем советы из локального списка
      for (int i = 0; i < tips.length; i++) {
        final tip = tips[i].copyWith(order: i);
        final docRef = await _firestore
            .collection(collectionName)
            .add(tip.toFirestore());

        // Обновляем ID в локальном списке
        tips[i] = DailyTip(
            id: docRef.id,
            tip: tip.tip,
            icon: tip.icon,
            order: i
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error synchronizing daily tips: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Получить совет дня
  DailyTip getCurrentDailyTip() {
    if (tips.isEmpty) {
      return DailyTip(id: 'default', tip: 'stay_hydrated', icon: '💧');
    }

    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final tipIndex = dayOfYear % tips.length;
    return tips[tipIndex];
  }
}