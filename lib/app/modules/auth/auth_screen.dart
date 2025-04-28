// lib/app/modules/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/modules/auth/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  final AuthController controller = Get.put(AuthController());

  AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isLogin.value ? 'login'.tr : 'register'.tr)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFFDF2F8)
                  : const Color(0xFF1A1A1A),
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF5F3FF)
                  : const Color(0xFF262626),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Лого чи ілюстрація
                      Icon(
                        Icons.face_retouching_natural,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 32),

                      // Назва
                      Text(
                        'Marinette',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Поле для імені (тільки для реєстрації)
                      Obx(() {
                        if (!controller.isLogin.value) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: controller.nameController,
                                decoration: InputDecoration(
                                  labelText: 'name'.tr,
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: controller.validateName,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Поле для email
                      TextFormField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email'.tr,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: controller.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Поле для пароля
                      Obx(() => TextFormField(
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        decoration: InputDecoration(
                          labelText: 'password'.tr,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: controller.validatePassword,
                      )),
                      const SizedBox(height: 24),

                      // Кнопка для входу чи реєстрації
                      Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : Text(
                          controller.isLogin.value ? 'login'.tr : 'register'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      )),
                      const SizedBox(height: 16),

                      // Перемикач між входом та реєстрацією
                      Obx(() => TextButton(
                        onPressed: controller.toggleAuthMode,
                        child: Text(
                          controller.isLogin.value
                              ? 'no_account'.tr
                              : 'have_account'.tr,
                        ),
                      )),

                      // Кнопка для скидання пароля (тільки для входу)
                      Obx(() {
                        if (controller.isLogin.value) {
                          return TextButton(
                            onPressed: controller.resetPassword,
                            child: Text('forgot_password'.tr),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
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