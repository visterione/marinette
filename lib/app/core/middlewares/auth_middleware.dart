// lib/app/core/middlewares/auth_middleware.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Перевірка авторизації
    final authService = Get.find<AuthService>();

    // Якщо користувач не авторизований і намагається перейти до захищеного маршруту
    if (!authService.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.AUTH);
    }

    return null;
  }
}

class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Перевірка авторизації адміністратора
    final authService = Get.find<AuthService>();

    // Якщо користувач не авторизований, перенаправляємо на сторінку аутентифікації
    if (!authService.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.AUTH);
    }

    // Перевірка прав адміністратора
    // Можна реалізувати просту перевірку за емейлом або складнішу через Firestore
    bool isAdmin = false;

    // Перевірка за емейлом
    if (authService.currentUser?.email == 'admin@marinette.app') {
      isAdmin = true;
    }

    // Додаткова перевірка через атрибути користувача в моделі
    if (authService.userModel?.preferences?['isAdmin'] == true) {
      isAdmin = true;
    }

    // Якщо користувач не є адміністратором, перенаправляємо на головну сторінку
    if (!isAdmin) {
      // Показуємо повідомлення
      Get.snackbar(
        'error'.tr,
        'admin_access_denied'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Перенаправляємо на головну
      return const RouteSettings(name: AppRoutes.HOME);
    }

    return null;
  }
}