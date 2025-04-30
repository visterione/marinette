// lib/app/modules/admin/beauty_trends/beauty_trends_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/beauty_trend.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';
import 'package:marinette/app/modules/admin/beauty_trends/trend_edit_screen.dart';

class BeautyTrendsManagementController extends GetxController {
  final BeautyTrendsService _trendsService = Get.put(BeautyTrendsService());

  final RxList<BeautyTrend> trends = <BeautyTrend>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedSeason = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTrends();
  }

  Future<void> loadTrends() async {
    isLoading.value = true;
    try {
      await _trendsService.loadTrends();
      trends.value = _trendsService.trends;
    } catch (e) {
      debugPrint('Error loading trends: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_trends'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTrend(String trendId) async {
    final success = await _trendsService.deleteTrend(trendId);

    if (success) {
      Get.snackbar(
        'success'.tr,
        'trend_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'error_deleting_trend'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return success;
  }

  Future<void> reorderTrends(int oldIndex, int newIndex) async {
    final filteredTrends = getFilteredTrends();

    // Получаем реальные индексы в полном списке
    final realOldIndex = trends.indexWhere((t) => t.id == filteredTrends[oldIndex].id);
    final realNewIndex = trends.indexWhere((t) => t.id == filteredTrends[newIndex < filteredTrends.length ? newIndex : filteredTrends.length - 1].id);

    final success = await _trendsService.reorderTrends(realOldIndex, realNewIndex);

    if (!success) {
      Get.snackbar(
        'error'.tr,
        'error_reordering_trends'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  List<BeautyTrend> getFilteredTrends() {
    List<BeautyTrend> filteredTrends = trends;

    // Фильтрация по сезону
    if (selectedSeason.value != 'all') {
      filteredTrends = filteredTrends.where((trend) =>
      trend.season == selectedSeason.value
      ).toList();
    }

    // Фильтрация по поисковому запросу
    final query = searchQuery.value.toLowerCase();
    if (query.isNotEmpty) {
      filteredTrends = filteredTrends.where((trend) =>
      trend.title.toLowerCase().contains(query) ||
          trend.description.toLowerCase().contains(query)
      ).toList();
    }

    return filteredTrends;
  }

  // Синхронизация локальных данных с Firestore
  Future<void> synchronizeWithFirestore() async {
    isLoading.value = true;

    try {
      final success = await _trendsService.synchronizeLocalTrends();

      if (success) {
        Get.snackbar(
          'success'.tr,
          'trends_synchronized'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_synchronizing_trends'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error synchronizing trends: $e');
      Get.snackbar(
        'error'.tr,
        'error_synchronizing_trends'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class BeautyTrendsManagementScreen extends StatelessWidget {
  final controller = Get.put(BeautyTrendsManagementController());

  BeautyTrendsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_beauty_trends'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'synchronize_with_firestore'.tr,
            onPressed: controller.synchronizeWithFirestore,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTrends,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Создание нового тренда
          Get.to(() => TrendEditScreen(
            onSave: () => controller.loadTrends(),
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Фильтры и поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Поисковая строка
                TextField(
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => controller.searchQuery.value = value,
                ),

                const SizedBox(height: 12),

                // Фильтр по сезону
                Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'filter_by_season'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  value: controller.selectedSeason.value,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('all_seasons'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'spring',
                      child: Text('spring'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'summer',
                      child: Text('summer'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'autumn',
                      child: Text('autumn'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'winter',
                      child: Text('winter'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedSeason.value = value;
                    }
                  },
                )),
              ],
            ),
          ),

          // Список трендов
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final trends = controller.getFilteredTrends();

              if (trends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty || controller.selectedSeason.value != 'all'
                            ? 'no_search_results'.tr
                            : 'no_trends'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Используем ReorderableListView для возможности перетаскивания
              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trends.length,
                onReorder: controller.reorderTrends,
                itemBuilder: (context, index) => _buildTrendItem(context, trends[index], index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, BeautyTrend trend, int index) {
    return Card(
      key: Key(trend.id),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Редактирование тренда
          Get.to(() => TrendEditScreen(
            trend: trend,
            onSave: () => controller.loadTrends(),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка сезона
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSeasonColor(trend.season).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSeasonEmoji(trend.season),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Содержимое тренда
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.title.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trend.description.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeasonColor(trend.season).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            trend.season.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSeasonColor(trend.season),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${'position'.tr}: ${trend.order + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Кнопки действий
              Column(
                children: [
                  // Кнопка редактирования
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Get.to(() => TrendEditScreen(
                        trend: trend,
                        onSave: () => controller.loadTrends(),
                      ));
                    },
                  ),

                  // Кнопка удаления
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Диалог подтверждения удаления
                      Get.dialog(
                        AlertDialog(
                          title: Text('confirm_delete'.tr),
                          content: Text('confirm_delete_trend'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                controller.deleteTrend(trend.id);
                              },
                              child: Text(
                                'delete'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Иконка для перетаскивания
              Icon(
                Icons.drag_handle,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'spring':
        return Colors.green;
      case 'summer':
        return Colors.orange;
      case 'autumn':
        return Colors.brown;
      case 'winter':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getSeasonEmoji(String season) {
    switch (season) {
      case 'spring':
        return '🌸';
      case 'summer':
        return '☀️';
      case 'autumn':
        return '🍂';
      case 'winter':
        return '❄️';
      default:
        return '🌟';
    }
  }
}