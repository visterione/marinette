import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_controller.dart';

class CameraScreen extends GetView<CustomCameraController> {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: null);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(result: null),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Нажмите на кнопку камеры',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                Material(
                  elevation: 8.0,
                  shape: const CircleBorder(),
                  color: Colors.white,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      try {
                        debugPrint('Нажатие на кнопку камеры');
                        final imagePath = await controller.takePhoto();
                        debugPrint('Результат takePhoto: $imagePath');
                        if (imagePath != null) {
                          Get.back(result: imagePath);
                        }
                      } catch (e) {
                        debugPrint('Ошибка в onTap кнопки камеры: $e');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.pink[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'take_photo'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}