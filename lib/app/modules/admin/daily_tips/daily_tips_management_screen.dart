// lib/app/modules/admin/daily_tips/daily_tips_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/daily_tip.dart';
import 'package:marinette/app/data/services/daily_tips_service.dart';
import 'package:marinette/app/modules/admin/daily_tips/tip_edit_screen.dart';

class DailyTipsManagementController extends GetxController {
  final DailyTipsService _tipsService = Get.find<DailyTipsService>();

  final RxList<DailyTip> tips = <DailyTip>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTips();
  }

  Future<void> loadTips() async {
    isLoading.value = true;
    try {
      await _tipsService.loadTips();
      tips.value = _tipsService.tips;
    } catch (e) {
      debugPrint('Error loading tips: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_tips'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTip(String tipId) async {
    final success = await _tipsService.deleteTip(tipId);

    if (success) {
      Get.snackbar(
        'success'.tr,
        'tip_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'error_deleting_tip'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    return success;
  }

  // Метод для переключения видимости совета
  Future<bool> toggleTipVisibility(DailyTip tip) async {
    try {
      isLoading.value = true;

      // Создаем копию совета с обновленным свойством видимости
      final updatedTip = tip.copyWith(isVisible: !tip.isVisible);

      // Обновляем в Firestore
      await _tipsService.getFirestore()
          .collection('daily_tips')
          .doc(tip.id)
          .update({'isVisible': updatedTip.isVisible});

      // Обновляем локальный список советов
      final index = tips.indexWhere((t) => t.id == tip.id);
      if (index != -1) {
        tips[index] = updatedTip;
      }

      Get.snackbar(
        'success'.tr,
        updatedTip.isVisible ? 'tip_visible'.tr : 'tip_hidden'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Error toggling tip visibility: $e');
      Get.snackbar(
        'error'.tr,
        'error_toggling_visibility'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reorderTips(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    try {
      // Создаем временную копию списка для обработки изменений
      final List<DailyTip> newTips = List.from(tips);

      // Перемещаем элемент в новом списке
      final item = newTips.removeAt(oldIndex);
      newTips.insert(newIndex, item);

      // Обновляем локальный список немедленно для UI
      tips.value = newTips;

      // Вызываем сервисный метод для обновления в Firestore
      final success = await _tipsService.reorderTips(oldIndex, newIndex);

      if (!success) {
        Get.snackbar(
          'error'.tr,
          'error_reordering_tips'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );

        // В случае неудачи перезагружаем советы
        await loadTips();
      }
    } catch (e) {
      debugPrint('Error reordering tips: $e');
      Get.snackbar(
        'error'.tr,
        'error_reordering_tips'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      // В случае ошибки перезагружаем советы
      await loadTips();
    }
  }

  List<DailyTip> getFilteredTips() {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      return tips;
    }

    return tips.where((tip) =>
    tip.tip.toLowerCase().contains(query) ||
        tip.icon.toLowerCase().contains(query)
    ).toList();
  }

  // Синхронизация локальных данных с Firestore
  Future<void> synchronizeWithFirestore() async {
    isLoading.value = true;

    try {
      final success = await _tipsService.synchronizeLocalTips();

      if (success) {
        Get.snackbar(
          'success'.tr,
          'tips_synchronized'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'error_synchronizing_tips'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error synchronizing tips: $e');
      Get.snackbar(
        'error'.tr,
        'error_synchronizing_tips'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class DailyTipsManagementScreen extends StatelessWidget {
  DailyTipsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DailyTipsManagementController());

    return Scaffold(
      appBar: AppBar(
        title: Text('manage_daily_tips'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'synchronize_with_firestore'.tr,
            onPressed: controller.synchronizeWithFirestore,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTips,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Создание нового совета
          Get.to(() => TipEditScreen(
            onSave: () => controller.loadTips(),
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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
          ),

          // Список советов
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final tips = controller.getFilteredTips();

              if (tips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'no_search_results'.tr
                            : 'no_tips'.tr,
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
                itemCount: tips.length,
                onReorder: controller.reorderTips,
                itemBuilder: (context, index) => _buildTipItem(context, tips[index], index, controller),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, DailyTip tip, int index, DailyTipsManagementController controller) {
    return Card(
      key: Key(tip.id),
      margin: const EdgeInsets.only(bottom: 16),
      // Добавляем прозрачность для скрытых советов
      color: tip.isVisible ? null : Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка совета
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.pink.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      tip.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Содержимое совета
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.tip.tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          // Меняем цвет текста для скрытых советов
                          color: tip.isVisible ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'position'.tr}: ${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: tip.isVisible ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'id'.tr}: ${tip.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tip.isVisible ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    // Кнопка переключения видимости
                    IconButton(
                      icon: Icon(
                        tip.isVisible ? Icons.visibility : Icons.visibility_off,
                        color: tip.isVisible ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => controller.toggleTipVisibility(tip),
                      tooltip: tip.isVisible ? 'hide_tip'.tr : 'show_tip'.tr,
                    ),

                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Get.to(() => TipEditScreen(
                          tip: tip,
                          onSave: () => controller.loadTips(),
                        ));
                      },
                    ),

                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Диалог подтверждения удаления
                        Get.dialog(
                          AlertDialog(
                            title: Text('confirm_delete'.tr),
                            content: Text('confirm_delete_tip'.tr),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text('cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  controller.deleteTip(tip.id);
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

                    // Drag handle icon - now aligned with other action buttons
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Метка для скрытых советов
          if (!tip.isVisible)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'hidden'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}