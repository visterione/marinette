// lib/app/modules/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/modules/profile/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: Text('confirm_logout'.tr),
                  content: Text('logout_confirmation'.tr),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        controller.signOut();
                      },
                      child: Text(
                        'logout'.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() => Container(
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
        child: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Фото профілю
                  GestureDetector(
                    onTap: controller.pickAndUploadImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: controller.userPhotoUrl != null
                                ? CachedNetworkImage(
                              imageUrl: controller.userPhotoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            )
                                : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ім'я користувача
                  Obx(() {
                    if (controller.isEditingName.value) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.nameController,
                              decoration: InputDecoration(
                                labelText: 'name'.tr,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              autofocus: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: controller.saveName,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: controller.cancelEditingName,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.userName,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: controller.startEditingName,
                          ),
                        ],
                      );
                    }
                  }),

                  const SizedBox(height: 8),
                  Text(
                    controller.userEmail,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Інформація про обліковий запис
                  _buildInfoCard(
                    context: context,
                    title: 'account_info'.tr,
                    children: [
                      _buildInfoRow(
                        context: context,
                        label: 'account_created'.tr,
                        value: controller.formatDate(controller.userCreatedAt),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context: context,
                        label: 'last_login'.tr,
                        value: controller.formatDate(controller.userLastLogin),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Збережені результати аналізу
                  _buildInfoCard(
                    context: context,
                    title: 'analysis_history'.tr,
                    children: [
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'view_history'.tr,
                        onTap: () => Get.toNamed('/history'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Налаштування
                  _buildInfoCard(
                    context: context,
                    title: 'settings'.tr,
                    children: [
                      _buildActionButton(
                        icon: Icons.language,
                        label: 'change_language'.tr,
                        onTap: () {
                          // Логіка зміни мови
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.brightness_6,
                        label: 'change_theme'.tr,
                        onTap: () {
                          // Логіка зміни теми
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Кнопка виходу з системи
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: Text('confirm_logout'.tr),
                          content: Text('logout_confirmation'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                controller.signOut();
                              },
                              child: Text(
                                'logout'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: Text('logout'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }

  // Допоміжний метод для створення інформаційної картки
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // Допоміжний метод для створення рядка інформації
  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Допоміжний метод для створення кнопки дії
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.pink),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}