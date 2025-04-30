// lib/app/modules/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/modules/admin/articles/articles_management_screen.dart';
import 'package:marinette/app/modules/admin/stories/stories_management_screen.dart';
import 'package:marinette/app/modules/admin/migration_screen.dart';
import 'package:marinette/app/data/services/auth_service.dart';

class AdminPanelScreen extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();

  AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_panel'.tr),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              Text(
                'admin_tools'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Управление статьями
              _buildAdminTool(
                context: context,
                title: 'manage_articles'.tr,
                description: 'manage_articles_description'.tr,
                icon: Icons.article,
                onTap: () {
                  Get.to(() => ArticlesManagementScreen());
                },
              ),

              // Управление историями
              _buildAdminTool(
                context: context,
                title: 'manage_stories'.tr,
                description: 'manage_stories_description'.tr,
                icon: Icons.auto_stories,
                onTap: () {
                  Get.to(() => StoriesManagementScreen());
                },
              ),

              // Миграция хранилища
              _buildAdminTool(
                context: context,
                title: 'storage_migration'.tr,
                description: 'storage_migration_description'.tr,
                icon: Icons.storage,
                onTap: () {
                  Get.to(() => const MigrationScreen());
                },
              ),

              // Управление пользователями (будущая функциональность)
              _buildAdminTool(
                context: context,
                title: 'manage_users'.tr,
                description: 'manage_users_description'.tr,
                icon: Icons.people,
                onTap: () {
                  // Заглушка для будущей функциональности
                  Get.snackbar(
                    'info'.tr,
                    'feature_coming_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              // Аналитика (будущая функциональность)
              _buildAdminTool(
                context: context,
                title: 'analytics'.tr,
                description: 'analytics_description'.tr,
                icon: Icons.analytics,
                onTap: () {
                  // Заглушка для будущей функциональности
                  Get.snackbar(
                    'info'.tr,
                    'feature_coming_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              const SizedBox(height: 32),
              Text(
                'admin_tools_note'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTool({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[600]
                            : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}