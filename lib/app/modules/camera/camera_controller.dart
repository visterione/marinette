// camera_controller.dart
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class CustomCameraController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  RxBool hasPermission = false.obs;

  @override
  void onInit() async {
    super.onInit();
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final camera = await Permission.camera.status;
      if (camera.isGranted) {
        hasPermission.value = true;
      } else {
        final result = await Permission.camera.request();
        hasPermission.value = result.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      Get.snackbar('error'.tr, 'error_camera'.tr);
    }
  }

  Future<String?> takePhoto() async {
    try {
      if (!hasPermission.value) {
        await _checkPermissions();
        if (!hasPermission.value) {
          Get.snackbar('error'.tr, 'Camera permission required'.tr);
          return null;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 100,
      );

      if (photo != null) {
        debugPrint('Photo taken: ${photo.path}');
        return photo.path;
      } else {
        debugPrint('No photo taken');
        return null;
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      Get.snackbar('error'.tr, 'error_camera'.tr);
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        debugPrint('Image picked from gallery: ${image.path}');
        return image.path;
      } else {
        debugPrint('No image selected');
        return null;
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      Get.snackbar('error'.tr, 'Could not pick image from gallery'.tr);
      return null;
    }
  }
}
