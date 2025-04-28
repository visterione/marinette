// lib/app/modules/auth/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final RxBool isLogin = true.obs;
  final RxBool obscurePassword = true.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool get isLoading => _authService.isLoading;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_required'.tr;
    }
    if (!GetUtils.isEmail(value)) {
      return 'invalid_email'.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 6) {
      return 'password_too_short'.tr;
    }
    return null;
  }

  String? validateName(String? value) {
    if (!isLogin.value && (value == null || value.isEmpty)) {
      return 'name_required'.tr;
    }
    return null;
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    bool success = false;

    if (isLogin.value) {
      // Вхід в систему
      success = await _authService.loginWithEmailAndPassword(email, password);
      if (success) {
        Get.back(); // Повернення на попередній екран
      } else {
        Get.snackbar(
          'error'.tr,
          'login_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      // Реєстрація
      success = await _authService.registerWithEmailAndPassword(email, password);
      if (success) {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          await _authService.updateUserProfile(displayName: name);
        }
        Get.back(); // Повернення на попередній екран
      } else {
        Get.snackbar(
          'error'.tr,
          'registration_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> resetPassword() async {
    final String email = emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'error'.tr,
        'valid_email_reset'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _authService.resetPassword(email);

    if (success) {
      Get.snackbar(
        'success'.tr,
        'reset_email_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'reset_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}