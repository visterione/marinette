// lib/app/modules/profile/profile_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ImagePicker _picker = ImagePicker();

  final nameController = TextEditingController();
  final RxBool isEditingName = false.obs;
  final RxBool isLoading = false.obs;

  // Геттери для доступу до даних користувача
  String get userEmail => _authService.userModel?.email ?? '';
  String get userName => _authService.userModel?.displayName ?? 'user'.tr;
  String? get userPhotoUrl => _authService.userModel?.photoUrl;
  DateTime? get userCreatedAt => _authService.userModel?.createdAt;
  DateTime? get userLastLogin => _authService.userModel?.lastLogin;

  @override
  void onInit() {
    super.onInit();
    nameController.text = userName;
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // Вихід з облікового запису
  Future<void> signOut() async {
    await _authService.signOut();
    Get.back(); // Повертаємося на попередній екран
  }

  // Початок редагування імені
  void startEditingName() {
    nameController.text = userName;
    isEditingName.value = true;
  }

  // Збереження зміненого імені
  Future<void> saveName() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success = await _authService.updateUserProfile(
        displayName: nameController.text.trim(),
      );

      if (success) {
        isEditingName.value = false;
        Get.snackbar(
          'success'.tr,
          'profile_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'update_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
      Get.snackbar(
        'error'.tr,
        'update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Скасування редагування імені
  void cancelEditingName() {
    isEditingName.value = false;
  }

  // Вибір і завантаження фото профілю
  Future<void> pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      isLoading.value = true;

      // Завантаження у Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_authService.currentUser!.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Оновлення URL фото у профілі
      final success = await _authService.updateUserProfile(
        photoUrl: downloadUrl,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'photo_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'photo_update_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      Get.snackbar(
        'error'.tr,
        'photo_upload_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Форматування дати для відображення
  String formatDate(DateTime? date) {
    if (date == null) return 'unknown'.tr;
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}