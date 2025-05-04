import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io' show File;

class CustomCameraController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final RxBool hasPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.camera.request();
      hasPermission.value = status.isGranted;
      debugPrint('Статус разрешения камеры: ${status.isGranted}');
    } catch (e) {
      debugPrint('Ошибка при запросе разрешений камеры: $e');
    }
  }

  Future<String?> takePhoto() async {
    XFile? photo;

    try {
      // Повторный запрос разрешения (для уверенности)
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        debugPrint('Разрешение на камеру не получено');
        Get.snackbar(
          'error'.tr,
          'Camera permission required'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      // Делаем фото
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo == null) {
        debugPrint('Пользователь отменил фотографирование');
        return null;
      }

      // Проверка существования файла
      final file = File(photo.path);
      if (!await file.exists()) {
        debugPrint('Файл фото не существует: ${photo.path}');
        throw Exception('Photo file does not exist');
      }

      debugPrint('Фото сделано успешно: ${photo.path}');
      return photo.path;
    } catch (e) {
      debugPrint('Ошибка при фотографировании: $e');
      Get.snackbar(
        'error'.tr,
        'error_camera'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    XFile? image;

    try {
      // Проверяем разрешение на хранилище
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          debugPrint('Нет разрешения на доступ к галерее');
          Get.snackbar(
            'error'.tr,
            'Storage permission required'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        }
      }

      // Выбираем изображение из галереи
      image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        debugPrint('Пользователь отменил выбор из галереи');
        return null;
      }

      // Проверка существования файла
      final file = File(image.path);
      if (!await file.exists()) {
        debugPrint('Файл изображения не существует: ${image.path}');
        throw Exception('Image file does not exist');
      }

      debugPrint('Изображение выбрано успешно: ${image.path}');
      return image.path;
    } catch (e) {
      debugPrint('Ошибка при выборе из галереи: $e');
      Get.snackbar(
        'error'.tr,
        'Could not pick image from gallery'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}