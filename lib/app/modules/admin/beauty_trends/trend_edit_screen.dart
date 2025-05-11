// lib/app/modules/admin/beauty_trends/trend_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/beauty_trend.dart';
import 'package:marinette/app/data/services/beauty_trends_service.dart';

class TrendEditController extends GetxController {
  final BeautyTrendsService _trendsService = Get.find<BeautyTrendsService>();
  final BeautyTrend? trend;
  final Function? onSave;

  // Контроллеры для текстовых полей
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  // Реактивные переменные
  final RxBool isLoading = false.obs;
  final RxString selectedSeason = 'spring'.obs;
  final RxBool isVisible = true.obs; // Add visibility reactive variable

  TrendEditController({
    this.trend,
    this.onSave,
  });

  @override
  void onInit() {
    super.onInit();

    // Инициализация контроллеров
    titleController = TextEditingController(text: trend?.title ?? '');
    descriptionController = TextEditingController(text: trend?.description ?? '');

    if (trend != null) {
      selectedSeason.value = trend!.season;
      isVisible.value = trend!.isVisible; // Initialize visibility
    }
  }

  // Toggle visibility
  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // Сохранение тренда
  Future<void> saveTrend() async {
    // Валидация полей
    if (titleController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'title_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'description_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      bool success;

      if (trend == null) {
        // Создание нового тренда
        success = await _trendsService.addTrend(
          titleController.text,
          descriptionController.text,
          selectedSeason.value,
        );

        // Set visibility status for new trend
        if (success) {
          // Find the newly created trend
          final lastTrend = _trendsService.trends.lastWhere(
                (t) => t.title == titleController.text,
            orElse: () => BeautyTrend(id: '', title: '', description: '', season: ''),
          );

          if (lastTrend.id.isNotEmpty) {
            await _trendsService.getFirestore()
                .collection('beauty_trends')
                .doc(lastTrend.id)
                .update({'isVisible': isVisible.value});
          }
        }

        if (success) {
          Get.snackbar(
            'success'.tr,
            'trend_created'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        // Обновление существующего тренда
        final updatedTrend = trend!.copyWith(
          title: titleController.text,
          description: descriptionController.text,
          season: selectedSeason.value,
          isVisible: isVisible.value,
        );

        success = await _trendsService.updateTrend(updatedTrend);

        if (success) {
          Get.snackbar(
            'success'.tr,
            'trend_updated'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      if (success) {
        // Вызов колбэка при успешном сохранении
        if (onSave != null) {
          onSave!();
        }

        Get.back();
      } else {
        Get.snackbar(
          'error'.tr,
          'error_saving_trend'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error saving trend: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_trend'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Получить цвет для выбранного сезона
  Color getSeasonColor(String season) {
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

  // Получить эмодзи для выбранного сезона
  String getSeasonEmoji(String season) {
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

class TrendEditScreen extends StatelessWidget {
  final BeautyTrend? trend;
  final Function? onSave;

  TrendEditScreen({
    Key? key,
    this.trend,
    this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrendEditController(
      trend: trend,
      onSave: onSave,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(trend == null ? 'create_trend'.tr : 'edit_trend'.tr),
        actions: [
          // Visibility toggle button
          Obx(() => IconButton(
            icon: Icon(
              controller.isVisible.value ? Icons.visibility : Icons.visibility_off,
              color: controller.isVisible.value ? Colors.green : Colors.grey,
            ),
            onPressed: controller.toggleVisibility,
            tooltip: controller.isVisible.value ? 'hide_trend'.tr : 'show_trend'.tr,
          )),

          // Loading indicator or save button
          Obx(() => controller.isLoading.value
              ? Container(
            margin: const EdgeInsets.all(16),
            width: 24,
            height: 24,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveTrend,
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор сезона
            Text(
              'season'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => _buildSeasonSelector(controller)),
            const SizedBox(height: 24),

            // Поле заголовка
            Text(
              'title'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                hintText: 'trend_title_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Поле описания
            Text(
              'description'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                hintText: 'trend_description_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 24),
            // Предпросмотр
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'preview'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: controller.getSeasonColor(controller.selectedSeason.value).withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    controller.getSeasonEmoji(controller.selectedSeason.value),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              // Add visibility indicator in preview
                              if (!controller.isVisible.value)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.visibility_off,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.titleController.text.isEmpty
                                      ? 'trend_title_placeholder'.tr
                                      : controller.titleController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    // Gray out text if not visible
                                    color: controller.isVisible.value ? null : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.descriptionController.text.isEmpty
                                      ? 'trend_description_placeholder'.tr
                                      : controller.descriptionController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    // Gray out text if not visible
                                    color: controller.isVisible.value
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: controller.getSeasonColor(controller.selectedSeason.value).withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    controller.selectedSeason.value.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: controller.getSeasonColor(controller.selectedSeason.value),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector(TrendEditController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSeasonOption(controller, 'spring'),
        _buildSeasonOption(controller, 'summer'),
        _buildSeasonOption(controller, 'autumn'),
        _buildSeasonOption(controller, 'winter'),
      ],
    );
  }

  Widget _buildSeasonOption(TrendEditController controller, String season) {
    return Obx(() {
      final isSelected = controller.selectedSeason.value == season;
      return InkWell(
        onTap: () => controller.selectedSeason.value = season,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? controller.getSeasonColor(season).withAlpha(50)
                : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: controller.getSeasonColor(season), width: 2)
                : null,
          ),
          child: Column(
            children: [
              Text(
                controller.getSeasonEmoji(season),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                season.tr,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? controller.getSeasonColor(season)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}