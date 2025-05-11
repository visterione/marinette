// lib/app/modules/admin/beauty_trends/beauty_trends_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/beauty_trend.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';
import 'package:reorderables/reorderables.dart';
import 'package:marinette/app/modules/admin/beauty_trends/trend_edit_screen.dart';

class BeautyTrendsManagementController extends GetxController {
  final BeautyTrendsService _trendsService = Get.find<BeautyTrendsService>();

  // Reactive variables
  final RxList<BeautyTrend> trends = <BeautyTrend>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedSeason = 'spring'.obs;
  final RxBool showHidden = false.obs; // Показывать ли скрытые тренды

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  // Season options for filtering and selection
  final List<String> seasons = ['spring', 'summer', 'autumn', 'winter'];

  @override
  void onInit() {
    super.onInit();
    loadTrends();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // Load all beauty trends
  Future<void> loadTrends() async {
    isLoading.value = true;
    try {
      await _trendsService.loadTrends();
      trends.value = _trendsService.trends.toList();
      trends.sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      debugPrint('Error loading beauty trends: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_trends'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get filtered trends by season with visibility filter
  List<BeautyTrend> getFilteredTrends(String season) {
    // Фильтруем по сезону
    List<BeautyTrend> filteredTrends = trends.where((trend) => trend.season == season).toList();

    // Если не показываем скрытые, фильтруем их
    if (!showHidden.value) {
      filteredTrends = filteredTrends.where((trend) => !trend.isHidden).toList();
    }

    // Сортируем по порядку
    filteredTrends.sort((a, b) => a.order.compareTo(b.order));

    return filteredTrends;
  }

  // Переключение режима отображения скрытых трендов
  void toggleShowHidden() {
    showHidden.value = !showHidden.value;
  }

  // Переключение видимости тренда
  Future<bool> toggleTrendVisibility(BeautyTrend trend) async {
    try {
      isLoading.value = true;

      final success = await _trendsService.toggleTrendVisibility(trend);

      if (success) {
        Get.snackbar(
          'success'.tr,
          trend.isHidden ? 'trend_shown'.tr : 'trend_hidden'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_changing_visibility'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error toggling trend visibility: $e');
      Get.snackbar(
        'error'.tr,
        'error_changing_visibility'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new trend
  Future<bool> addTrend() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'all_fields_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final success = await _trendsService.addTrend(
        titleController.text.trim(),
        descriptionController.text.trim(),
        selectedSeason.value,
      );

      if (success) {
        // Clear form
        titleController.clear();
        descriptionController.clear();

        // Show success message
        Get.back(); // Close dialog
        Get.snackbar(
          'success'.tr,
          'trend_added_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_adding_trend'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error adding beauty trend: $e');
      Get.snackbar(
        'error'.tr,
        'error_adding_trend'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing trend
  Future<bool> updateTrend(BeautyTrend trend, String title, String description, String season) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'all_fields_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final updatedTrend = trend.copyWith(
        title: title.trim(),
        description: description.trim(),
        season: season,
      );

      final success = await _trendsService.updateTrend(updatedTrend);

      if (success) {
        Get.back(); // Close dialog
        Get.snackbar(
          'success'.tr,
          'trend_updated_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_updating_trend'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Error updating beauty trend: $e');
      Get.snackbar(
        'error'.tr,
        'error_updating_trend'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a trend
  Future<bool> deleteTrend(String trendId) async {
    isLoading.value = true;
    try {
      final success = await _trendsService.deleteTrend(trendId);

      if (success) {
        Get.snackbar(
          'success'.tr,
          'trend_deleted_successfully'.tr,
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
    } catch (e) {
      debugPrint('Error deleting beauty trend: $e');
      Get.snackbar(
        'error'.tr,
        'error_deleting_trend'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reorder trends within a season
  Future<bool> reorderTrends(int oldIndex, int newIndex, String season) async {
    try {
      isLoading.value = true;

      // Получаем отфильтрованные тренды для выбранного сезона
      final filteredTrends = getFilteredTrends(season);

      // Если старый индекс меньше нового, уменьшаем новый на 1
      // Это связано с тем, как ReorderableListView обрабатывает индексы
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Получаем перемещаемый тренд
      final trendToMove = filteredTrends[oldIndex];

      // Находим глобальные индексы (в полном списке трендов)
      final globalOldIndex = trends.indexWhere((t) => t.id == trendToMove.id);
      int globalNewIndex;

      if (newIndex >= filteredTrends.length) {
        // Защита от выхода за границы
        newIndex = filteredTrends.length - 1;
      }

      if (oldIndex < newIndex) {
        // Перемещение вниз
        final targetTrend = filteredTrends[newIndex];
        globalNewIndex = trends.indexWhere((t) => t.id == targetTrend.id) + 1;
        if (globalNewIndex > trends.length) globalNewIndex = trends.length;
      } else {
        // Перемещение вверх
        final targetTrend = filteredTrends[newIndex];
        globalNewIndex = trends.indexWhere((t) => t.id == targetTrend.id);
      }

      // Перемещаем элемент в локальном списке
      final item = trends.removeAt(globalOldIndex);
      trends.insert(globalNewIndex, item);

      // Обновляем порядок всех элементов локально
      for (int i = 0; i < trends.length; i++) {
        trends[i] = trends[i].copyWith(order: i);
      }

      // Обновляем в Firestore
      final trendIds = trends.map((t) => t.id).toList();
      for (int i = 0; i < trends.length; i++) {
        await _trendsService.updateTrend(trends[i]);
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

  // Show dialog to add a new trend
  void showAddTrendDialog() {
    // Clear form first
    titleController.clear();
    descriptionController.clear();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'add_new_trend'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Title field
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'title'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'description'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Season dropdown
                Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'season'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: selectedSeason.value,
                  items: seasons.map((season) {
                    return DropdownMenuItem(
                      value: season,
                      child: Text(season.tr),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedSeason.value = value;
                    }
                  },
                )),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => ElevatedButton(
                      onPressed: isLoading.value ? null : addTrend,
                      child: isLoading.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text('add'.tr),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show dialog to edit an existing trend
  void showEditTrendDialog(BeautyTrend trend) {
    // Set form values
    titleController.text = trend.title;
    descriptionController.text = trend.description;
    selectedSeason.value = trend.season;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit_trend'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Title field
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'title'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'description'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Season dropdown
                Obx(() => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'season'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: selectedSeason.value,
                  items: seasons.map((season) {
                    return DropdownMenuItem(
                      value: season,
                      child: Text(season.tr),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedSeason.value = value;
                    }
                  },
                )),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => ElevatedButton(
                      onPressed: isLoading.value
                          ? null
                          : () => updateTrend(
                        trend,
                        titleController.text,
                        descriptionController.text,
                        selectedSeason.value,
                      ),
                      child: isLoading.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text('save'.tr),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show confirmation dialog for deletion
  void showDeleteConfirmation(BeautyTrend trend) {
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
              deleteTrend(trend.id);
            },
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
          // Кнопка для переключения отображения скрытых трендов
          Obx(() => IconButton(
            icon: Icon(
              controller.showHidden.value
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: controller.showHidden.value
                  ? Colors.blue
                  : Colors.grey,
            ),
            tooltip: controller.showHidden.value
                ? 'hide_hidden_trends'.tr
                : 'show_hidden_trends'.tr,
            onPressed: controller.toggleShowHidden,
          )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTrends,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showAddTrendDialog,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFFDF2F8)
                  : const Color(0xFF1A1A1A),
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF5F3FF)
                  : const Color(0xFF262626),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value && controller.trends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.pink,
                  unselectedLabelColor: Colors.grey,
                  tabs: controller.seasons.map((season) => Tab(
                    text: season.tr,
                  )).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: controller.seasons.map((season) {
                      final filteredTrends = controller.getFilteredTrends(season);

                      return filteredTrends.isEmpty
                          ? Center(
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
                              controller.showHidden.value
                                  ? 'no_trends_for_season'.trParams({'season': season.tr})
                                  : 'no_visible_trends_for_season'.trParams({'season': season.tr}),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: controller.showAddTrendDialog,
                              icon: const Icon(Icons.add),
                              label: Text('add_new_trend'.tr),
                            ),
                          ],
                        ),
                      )
                          : ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTrends.length,
                        onReorder: (oldIndex, newIndex) {
                          controller.reorderTrends(oldIndex, newIndex, season);
                        },
                        itemBuilder: (context, index) {
                          final trend = filteredTrends[index];
                          return _buildTrendItem(context, trend, index);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, BeautyTrend trend, int index) {
    return Card(
      key: Key(trend.id),
      margin: const EdgeInsets.only(bottom: 8),
      // Добавляем цвет фона для скрытых трендов
      color: trend.isHidden
          ? Colors.grey.withOpacity(0.1)
          : Theme.of(context).cardColor,
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                trend.title.tr,
                style: TextStyle(
                  // Изменяем стиль для скрытых трендов
                  color: trend.isHidden
                      ? Colors.grey
                      : Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ),
            if (trend.isHidden)
              Icon(
                Icons.visibility_off,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
        subtitle: Text(
          trend.description.tr, // Translation key
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            // Изменяем стиль для скрытых трендов
            color: trend.isHidden
                ? Colors.grey
                : Colors.grey[600],
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: trend.isHidden
                ? Colors.grey.withAlpha(30)
                : Colors.pink.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
              Icons.trending_up,
              color: trend.isHidden ? Colors.grey : Colors.pink
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Кнопка для переключения видимости
            IconButton(
              icon: Icon(
                trend.isHidden ? Icons.visibility : Icons.visibility_off,
                color: trend.isHidden ? Colors.blue : Colors.grey,
              ),
              onPressed: () => controller.toggleTrendVisibility(trend),
              tooltip: trend.isHidden ? 'show_trend'.tr : 'hide_trend'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => controller.showEditTrendDialog(trend),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => controller.showDeleteConfirmation(trend),
            ),
            // Add ReorderableDragStartListener for drag functionality
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        onTap: () => controller.showEditTrendDialog(trend),
      ),
    );
  }
}