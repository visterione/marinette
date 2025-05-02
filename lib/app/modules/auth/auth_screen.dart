// lib/app/modules/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/modules/auth/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  final AuthController controller = Get.put(AuthController());

  AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for proper positioning
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFDF2F8),  // Light pink
              const Color(0xFFFFE4E1),  // Lighter pink
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section with logo and text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                height: screenHeight * 0.6, // Use 60% of the screen height to make room for extra button
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    // Logo with shadow
                    Container(
                      height: 130,
                      width: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                        ],
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(20),
                      // Replace with your logo image (the makeup bag icon)
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo image not found
                          return Icon(
                            Icons.spa,
                            size: 80,
                            color: Colors.pink[600],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // App name with Playfair Display font
                    Text(
                      'Beautymarine',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                        fontFamily: 'PlayfairDisplay',
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Subtitle text
                    Text(
                      'welcome_message'.tr,
                      style: TextStyle(
                        color: Colors.pink[700],
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0.5,
                        fontFamily: 'PlayfairDisplay',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Bottom section with buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Google sign-in button
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          colors: [
                            Colors.pink.shade300,
                            Colors.pink.shade400,
                            Colors.pink.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pink[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        child: controller.isLoading.value
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.pink[300],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'signing_in'.tr,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'sign_in_with_google'.tr,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),

                    // GitHub sign-in button
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                            Colors.grey.shade900,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ElevatedButton(
                        onPressed: controller.isGithubLoading.value
                            ? null
                            : controller.signInWithGitHub,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        child: controller.isGithubLoading.value
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'signing_in'.tr,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/github_logo.png',
                              height: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'sign_in_with_github'.tr,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),

                    // Continue without signing in
                    TextButton(
                      onPressed: () => Get.offAllNamed('/'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.pink[400],
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      child: Text('continue_without_account'.tr),
                    ),

                    const SizedBox(height: 16),

                    // Copyright text
                    Text(
                      '© 2025 Beautymarine',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}