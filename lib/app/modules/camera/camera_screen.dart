// camera_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_controller.dart';

class CameraScreen extends GetView<CustomCameraController> {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'take_photo',
                backgroundColor: Colors.white,
                onPressed: () async {
                  final imagePath = await controller.takePhoto();
                  if (imagePath != null) {
                    Get.back(result: imagePath);
                  }
                },
                child: const Icon(Icons.camera_alt, color: Colors.black),
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
    );
  }
}
