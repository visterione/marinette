import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/face_analysis_service.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:marinette/app/modules/camera/camera_controller.dart';
import 'package:marinette/app/modules/camera/camera_screen.dart';
import 'package:marinette/app/modules/history/history_screen.dart';
import 'package:marinette/config/translations/app_translations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _changeLanguage() {
    final service = Get.find<LocalizationService>();
    final newLocale = service.getCurrentLocale() == 'en' ? 'uk' : 'en';
    service.changeLocale(newLocale);
  }

  Future<void> _processImage(String? imagePath) async {
    if (imagePath != null) {
      try {
        debugPrint('Starting image processing for path: $imagePath');

        // Показуємо індикатор завантаження
        Get.dialog(
          WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          barrierDismissible: false,
        );

        debugPrint('Creating FaceAnalysisService');
        final analysisService = Get.put(FaceAnalysisService());

        debugPrint('Starting face analysis');
        final result = await analysisService.analyzeFace(imagePath);
        debugPrint('Face analysis completed: $result');

        // Закриваємо індикатор завантаження
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Показуємо результати
        if (result != null) {
          debugPrint('Navigating to results screen');
          await Get.to(() => AnalysisResultScreen(
                imagePath: imagePath,
                result: result,
              ));
        } else {
          debugPrint('Analysis returned null result');
          Get.snackbar(
            'error'.tr,
            'analysis_failed'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        debugPrint('Error during image processing: $e');
        // Закриваємо індикатор завантаження у випадку помилки
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar(
          'error'.tr,
          'analysis_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      debugPrint('No image path provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => HistoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _changeLanguage,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.face,
                        size: 80,
                        color: Colors.pink,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'welcome_message'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text('take_photo'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () async {
                          debugPrint('Camera button pressed');
                          Get.lazyPut(() => CustomCameraController());
                          final imagePath =
                              await Get.to<String>(() => const CameraScreen());
                          debugPrint(
                              'Returned from camera with path: $imagePath');
                          await _processImage(imagePath);
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: Text('choose_from_gallery'.tr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () async {
                          debugPrint('Gallery button pressed');
                          final controller = Get.put(CustomCameraController());
                          final imagePath = await controller.pickFromGallery();
                          debugPrint(
                              'Returned from gallery with path: $imagePath');
                          await _processImage(imagePath);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
