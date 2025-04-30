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
            const SizedBox(height: 16),

            // Предпросмотр иконки
            Center(
              child: Column(
                children: [
                  Text('icon_preview'.tr),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.pink.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Obx(() {
                        final iconText = controller.iconController.text.isEmpty
                            ? '💡'
                            : controller.iconController.text;
                        return Text(
                          iconText,
                          style: const TextStyle(fontSize: 40),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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