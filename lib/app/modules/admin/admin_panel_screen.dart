// lib/app/modules/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/modules/admin/migration_screen.dart';
import 'package:marinette/app/data/services/auth_service.dart';

class AdminPanelScreen extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();

  AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
              const Text(
                'Admin Tools',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Storage Migration Tool
              _buildAdminTool(
                context: context,
                title: 'Firebase Storage Migration',
                description: 'Migrate images from Google Drive to Firebase Storage',
                icon: Icons.storage,
                onTap: () {
                  Get.to(() => const MigrationScreen());
                },
              ),

              // Можна додати інші інструменти для адміністрування
              _buildAdminTool(
                context: context,
                title: 'Manage Articles',
                description: 'Add, edit, or delete articles, lifehacks, and guides',
                icon: Icons.article,
                onTap: () {
                  // Навігація до екрану управління статтями
                  Get.snackbar(
                    'Info',
                    'Article management screen coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              _buildAdminTool(
                context: context,
                title: 'Manage Stories',
                description: 'Create, edit, or remove stories',
                icon: Icons.auto_stories,
                onTap: () {
                  // Навігація до екрану управління сторіз
                  Get.snackbar(
                    'Info',
                    'Stories management screen coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              _buildAdminTool(
                context: context,
                title: 'User Management',
                description: 'View and manage user accounts',
                icon: Icons.people,
                onTap: () {
                  // Навігація до екрану управління користувачами
                  Get.snackbar(
                    'Info',
                    'User management screen coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              _buildAdminTool(
                context: context,
                title: 'Analytics',
                description: 'View application usage statistics',
                icon: Icons.analytics,
                onTap: () {
                  // Навігація до екрану аналітики
                  Get.snackbar(
                    'Info',
                    'Analytics screen coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),

              const SizedBox(height: 32),
              const Text(
                'Note: These tools are only available to administrators.',
                style: TextStyle(
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