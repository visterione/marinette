// lib/app/modules/admin/daily_tips/tip_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/daily_tip.dart';
import 'package:marinette/app/data/services/daily_tips_service.dart';

class TipEditController extends GetxController {
  final DailyTipsService _tipsService = Get.find<DailyTipsService>();
  final DailyTip? tip;
  final Function? onSave;

  // Контроллеры для текстовых полей
  late TextEditingController tipController;
  late TextEditingController iconController;

  // Реактивные переменные
  final RxBool isLoading = false.obs;
  final RxBool isVisible = true.obs; // Add visibility reactive variable

  TipEditController({
    this.tip,
    this.onSave,
  });

  @override
  void onInit() {
    super.onInit();

    // Инициализация контроллеров
    tipController = TextEditingController(text: tip?.tip ?? '');
    iconController = TextEditingController(text: tip?.icon ?? '💡');

    // Load visibility status if editing an existing tip
    if (tip != null) {
      loadTipVisibility();
    }
  }

  // Load visibility status from Firestore
  Future<void> loadTipVisibility() async {
    if (tip == null) return;

    try {
      final firestore = _tipsService.getFirestore();
      final docSnapshot = await firestore.collection('daily_tips').doc(tip!.id).get();
      final data = docSnapshot.data();
      if (data != null) {
        isVisible.value = data['isVisible'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading tip visibility: $e');
    }
  }

  // Toggle visibility
  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  @override
  void onClose() {
    tipController.dispose();
    iconController.dispose();
    super.onClose();
  }

  // Сохранение совета
  Future<void> saveTip() async {
    // Валидация полей
    if (tipController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'tip_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      bool success;

      if (tip == null) {
        // Создание нового совета
        success = await _tipsService.addTip(
          tipController.text,
          iconController.text.isEmpty ? '💡' : iconController.text,
        );

        // Set visibility status in Firestore for new tip
        if (success) {
          // The tip was just created, so we need to find its ID
          final lastTip = _tipsService.tips.lastWhere(
                (t) => t.tip == tipController.text,
            orElse: () => DailyTip(id: '', tip: ''),
          );

          if (lastTip.id.isNotEmpty) {
            await _tipsService.getFirestore()
                .collection('daily_tips')
                .doc(lastTip.id)
                .update({'isVisible': isVisible.value});
          }
        }

        if (success) {
          Get.snackbar(
            'success'.tr,
            'tip_created'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        // Обновление существующего совета
        final updatedTip = tip!.copyWith(
          tip: tipController.text,
          icon: iconController.text.isEmpty ? '💡' : iconController.text,
        );

        success = await _tipsService.updateTip(updatedTip);

        // Update visibility separately
        if (success) {
          await _tipsService.getFirestore()
              .collection('daily_tips')
              .doc(tip!.id)
              .update({'isVisible': isVisible.value});
        }

        if (success) {
          Get.snackbar(
            'success'.tr,
            'tip_updated'.tr,
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
          'error_saving_tip'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error saving tip: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_tip'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class TipEditScreen extends StatelessWidget {
  final DailyTip? tip;
  final Function? onSave;

  TipEditScreen({
    Key? key,
    this.tip,
    this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TipEditController(
      tip: tip,
      onSave: onSave,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(tip == null ? 'create_tip'.tr : 'edit_tip'.tr),
        actions: [
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
            onPressed: controller.saveTip,
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visibility toggle
            Row(
              children: [
                Text(
                  'visibility'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => Switch(
                  value: controller.isVisible.value,
                  onChanged: (value) {
                    controller.isVisible.value = value;
                  },
                  activeColor: Colors.green,
                )),
                Text(
                  controller.isVisible.value ? 'visible'.tr : 'hidden'.tr,
                  style: TextStyle(
                    color: controller.isVisible.value ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Поле совета
            Text(
              'tip_text'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.tipController,
              decoration: InputDecoration(
                hintText: 'tip_text_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Поле иконки
            Text(
              'tip_icon'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.iconController,
              decoration: InputDecoration(
                hintText: 'tip_icon_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Подсказки для путей
            Text(
              'common_emojis'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEmojiPicker(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker(TipEditController controller) {
    // Набор распространенных emoji для выбора
    const emojis = [
      '💡', '✨', '🌟', '💧', '❄️', '☀️', '🔥', '🧴', '💄', '💅',
      '👁️', '👄', '🧖‍♀️', '🧖‍♂️', '💆‍♀️', '💆‍♂️', '💇‍♀️', '💇‍♂️',
      '🛀', '🧼', '🧽', '🪥', '🧹', '🧺', '🧻', '🧪', '🧫', '🧬',
      '🧵', '🧶', '👗', '👙', '👚', '👛', '👜', '👝', '🎀', '🎁',
      '💐', '🌸', '🌹', '🌺', '🌻', '🌼', '🍀', '🍃', '🍂', '🍁',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: emojis.map((emoji) => GestureDetector(
        onTap: () {
          controller.iconController.text = emoji;
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      )).toList(),
    );
  }
}