import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppNavigation {
  static Future<T?> navigateTo<T>({
    required BuildContext context,
    required Widget page,
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName ?? page.runtimeType.toString()),
      ),
    );
  }

  static Future<T?> navigateWithSlide<T>({
    required Widget page,
    bool fullscreenDialog = false,
  }) {
    return Get.to<T>(
          () => page,
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
          fullscreenDialog: fullscreenDialog,
        ) ??
        Future.value(null);
  }

  static void back<T>([T? result]) {
    Get.back<T>(result: result);
  }

  static Future<bool?> showConfirmationDialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmText ?? 'confirm'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
