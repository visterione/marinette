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
        title: Text('login'.tr),
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
                    const SizedBox(height: 16),

                    Text(
                      'welcome_message'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64),

                    // Кнопка входу через Google
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.signInWithGoogle,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                      ),
                      label: Text(
                        'sign_in_with_google'.tr,
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}