import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'camera_controller.dart';

class CameraScreen extends GetView<CustomCameraController> {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('take_photo'.tr),
      ),
      body: Obx(() {
        if (!controller.hasPermission.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography, size: 64),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.onInit(),
                  child: const Text('Request Camera Permission'),
                ),
              ],
            ),
          );
        }

        if (!controller.isCameraInitialized.value ||
            controller.cameraController.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Camera Preview
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller
                          .cameraController.value!.value.previewSize?.width ??
                      0,
                  height: controller
                          .cameraController.value!.value.previewSize?.height ??
                      0,
                  child: CameraPreview(controller.cameraController.value!),
                ),
              ),
            ),
            // Camera Controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'cancel',
                    onPressed: () => Get.back(),
                    child: const Icon(Icons.close),
                  ),
                  FloatingActionButton(
                    heroTag: 'capture',
                    onPressed: () async {
                      final imagePath = await controller.takePhoto();
                      if (imagePath != null) {
                        Get.back(result: imagePath);
                      }
                    },
                    child: const Icon(Icons.camera),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
