// lib/app/data/services/beauty_trends_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:marinette/app/data/models/beauty_trend.dart';

class BeautyTrendsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<BeautyTrend> trends = <BeautyTrend>[].obs;
  final RxBool isLoading = false.obs;

  static const String collectionName = 'beauty_trends';

  // Add method to expose the Firestore instance
  FirebaseFirestore getFirestore() {
    return _firestore;
  }

  Future<BeautyTrendsService> init() async {
    await loadTrends();
    return this;
  }

  // Загрузка трендов из Firestore
  Future<void> loadTrends() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('order')
          .get();

      List<BeautyTrend> loadedTrends = snapshot.docs.map((doc) {
        final data = doc.data();
        return BeautyTrend.fromFirestore(doc.id, data);
      }).toList();

      trends.value = loadedTrends;
      debugPrint('Loaded ${trends.length} beauty trends');
    } catch (e) {
      debugPrint('Error loading beauty trends: $e');
      // Если не получилось загрузить из Firestore, используем локальные данные
      _initializeLocalTrends();
    } finally {
      isLoading.value = false;
    }
  }

  // Инициализация локальных данных, если не удалось загрузить из Firestore
  void _initializeLocalTrends() {
    trends.value = [
      BeautyTrend(
        id: '1',
        title: 'glass_skin',
        description: 'glass_skin_description',
        season: 'spring',
        order: 0,
        isVisible: true,
      ),
      BeautyTrend(
        id: '2',
        title: 'pastel_eyeshadows',
        description: 'pastel_eyeshadows_description',
        season: 'spring',
        order: 1,
        isVisible: true,
      ),
      BeautyTrend(
        id: '3',
        title: 'natural_blush',
        description: 'natural_blush_description',
        season: 'spring',
        order: 2,
        isVisible: true,
      ),
      BeautyTrend(
        id: '4',
        title: 'sunburnt_blush',
        description: 'sunburnt_blush_description',
        season: 'summer',
        order: 3,
        isVisible: true,
      ),
      BeautyTrend(
        id: '5',
        title: 'glazed_skin',
        description: 'glazed_skin_description',
        season: 'summer',
        order: 4,
        isVisible: true,
      ),
      BeautyTrend(
        id: '6',
        title: 'waterproof_makeup',
        description: 'waterproof_makeup_description',
        season: 'summer',
        order: 5,
        isVisible: true,
      ),
      BeautyTrend(
        id: '7',
        title: 'soft_matte_skin',
        description: 'soft_matte_skin_description',
        season: 'autumn',
        order: 6,
        isVisible: true,
      ),
      BeautyTrend(
        id: '8',
        title: 'berry_lips',
        description: 'berry_lips_description',
        season: 'autumn',
        order: 7,
        isVisible: true,
      ),
      BeautyTrend(
        id: '9',
        title: 'copper_eyes',
        description: 'copper_eyes_description',
        season: 'autumn',
        order: 8,
        isVisible: true,
      ),
      BeautyTrend(
        id: '10',
        title: 'glossy_lips',
        description: 'glossy_lips_description',
        season: 'winter',
        order: 9,
        isVisible: true,
      ),
      BeautyTrend(
        id: '11',
        title: 'frosted_looks',
        description: 'frosted_looks_description',
        season: 'winter',
        order: 10,
        isVisible: true,
      ),
      BeautyTrend(
        id: '12',
        title: 'rich_hydration',
        description: 'rich_hydration_description',
        season: 'winter',
        order: 11,
        isVisible: true,
      ),
    ];
  }

  // Добавление нового тренда
  Future<bool> addTrend(String title, String description, String season) async {
    try {
      isLoading.value = true;

      int nextOrder = 0;
      if (trends.isNotEmpty) {
        // Find max order for the specific season to place it at the end of its season group
        final seasonTrends = trends.where((t) => t.season == season).toList();
        if (seasonTrends.isNotEmpty) {
          nextOrder = seasonTrends.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1;
        } else {
          // If no trends in this season, use base order for this season
          nextOrder = _getBaseOrderForSeason(season);
        }
      }

      final newTrend = BeautyTrend(
        id: '', // Firestore создаст ID
        title: title,
        description: description,
        season: season,
        order: nextOrder,
        isVisible: true, // По умолчанию тренды видимые
      );

      final docRef = await _firestore
          .collection(collectionName)
          .add(newTrend.toFirestore());

      // Добавляем в локальный список
      trends.add(BeautyTrend(
        id: docRef.id,
        title: title,
        description: description,
        season: season,
        order: nextOrder,
        isVisible: true, // По умолчанию тренды видимые
      ));

      // Сортируем по порядку
      trends.sort((a, b) => a.order.compareTo(b.order));

      return true;
    } catch (e) {
      debugPrint('Error adding beauty trend: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Обновление тренда
  Future<bool> updateTrend(BeautyTrend trend) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection(collectionName)
          .doc(trend.id)
          .update(trend.toFirestore());

      // Обновляем в локальном списке
      final index = trends.indexWhere((t) => t.id == trend.id);
      if (index != -1) {
        trends[index] = trend;
      }

      // Сортируем по порядку
      trends.sort((a, b) => a.order.compareTo(b.order));

      return true;
    } catch (e) {
      debugPrint('Error updating beauty trend: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Удаление тренда
  Future<bool> deleteTrend(String trendId) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection(collectionName)
          .doc(trendId)
          .delete();

      // Удаляем из локального списка
      trends.removeWhere((t) => t.id == trendId);

      return true;
    } catch (e) {
      debugPrint('Error deleting beauty trend: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Изменение порядка трендов - реализация через отдельное обновление каждого тренда
  Future<bool> reorderTrends(int oldIndex, int newIndex) async {
    try {
      isLoading.value = true;

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = trends.removeAt(oldIndex);
      trends.insert(newIndex, item);

      // Обновляем порядок всех элементов
      for (int i = 0; i < trends.length; i++) {
        final trend = trends[i].copyWith(order: i);
        trends[i] = trend;

        await _firestore
            .collection(collectionName)
            .doc(trend.id)
            .update({'order': i});
      }

      return true;
    } catch (e) {
      debugPrint('Error reordering beauty trends: $e');
      // В случае ошибки перезагружаем данные
      await loadTrends();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get base order for a season
  int _getBaseOrderForSeason(String season) {
    // Use a base order offset for each season to ensure they don't interfere with each other
    switch (season) {
      case 'spring': return 0;
      case 'summer': return 100;
      case 'autumn': return 200;
      case 'winter': return 300;
      default: return 0;
    }
  }

  // Получение актуальных трендов текущего сезона (только видимые)
  List<BeautyTrend> getCurrentSeasonTrends() {
    final currentMonth = DateTime.now().month;
    String season;

    if (currentMonth >= 3 && currentMonth <= 5) {
      season = 'spring';
    } else if (currentMonth >= 6 && currentMonth <= 8) {
      season = 'summer';
    } else if (currentMonth >= 9 && currentMonth <= 11) {
      season = 'autumn';
    } else {
      season = 'winter';
    }

    // Только видимые тренды текущего сезона
    return trends.where((trend) =>
    trend.season == season && trend.isVisible).toList();
  }

  // Синхронизация локальных данных с Firestore
  Future<bool> synchronizeLocalTrends() async {
    try {
      isLoading.value = true;

      // Удаляем все существующие тренды
      final snapshot = await _firestore.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Добавляем тренды из локального списка
      for (int i = 0; i < trends.length; i++) {
        final trend = trends[i].copyWith(order: i);
        final docRef = await _firestore
            .collection(collectionName)
            .add(trend.toFirestore());

        // Обновляем ID в локальном списке
        trends[i] = BeautyTrend(
            id: docRef.id,
            title: trend.title,
            description: trend.description,
            season: trend.season,
            order: i,
            isVisible: trend.isVisible // Сохраняем статус видимости
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error synchronizing beauty trends: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}