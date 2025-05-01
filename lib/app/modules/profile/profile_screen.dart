// lib/app/modules/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/modules/profile/profile_controller.dart';
import 'package:marinette/app/modules/history/history_screen.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());
  final BackgroundMusicHandler _musicHandler = BackgroundMusicHandler.instance;
  final AuthService _authService = Get.find<AuthService>();

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
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Фото профілю
                  _buildProfileHeader(context),
                  const SizedBox(height: 24),

                  // Додаткова інформація про користувача
                  _buildAdditionalInfoCard(context),
                  const SizedBox(height: 24),

                  // Історія аналізу
                  _buildHistoryCard(context),
                  const SizedBox(height: 24),

                  // Збережені статті
                  _buildFavoritesCard(context),
                  const SizedBox(height: 24),

                  // Налаштування
                  _buildSettingsCard(context),
                  const SizedBox(height: 24),

                  // FAQ
                  _buildFaqCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }

  // Заголовок профілю з фото та іменем
  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        const SizedBox(height: 16),
        // Ім'я користувача
        Obx(() {
          if (controller.isEditingName.value) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    textAlign: TextAlign.center,
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
                const Spacer(),
                Expanded(
                  flex: 8,
                  child: Text(
                    controller.userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: controller.startEditingName,
                  ),
                ),
              ],
            );
          }
        }),
        Text(
          controller.userEmail,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Додаткова інформація про користувача
  Widget _buildAdditionalInfoCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'personal_info'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Вік
            Obx(() => _buildInfoItem(
              context: context,
              label: 'age'.tr,
              value: controller.userAge.value?.toString() ?? 'not_specified'.tr,
              onTap: () => _showAgeSelectionDialog(context),
            )),

            const Divider(height: 24),

            // Тип шкіри
            Obx(() => _buildInfoItem(
              context: context,
              label: 'skin_type'.tr,
              value: controller.userSkinType.value != null
                  ? 'skin_type_${controller.userSkinType.value}'.tr
                  : 'not_specified'.tr,
              onTap: () => _showSkinTypeSelectionDialog(context),
            )),
          ],
        ),
      ),
    );
  }

  // Історія аналізу
  Widget _buildHistoryCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'analysis_history'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.timeline,
              label: 'view_history'.tr,
              color: Colors.pink,
              onTap: () => Get.to(() => HistoryScreen()),
            ),
          ],
        ),
      ),
    );
  }

  // Збережені статті
  Widget _buildFavoritesCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'saved_articles'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (controller.favoriteArticles.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Показати всі збережені статті
                      controller.viewAllFavoriteArticles();
                    },
                    child: Text('view_all'.tr),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.favoriteArticles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'no_saved_articles'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: controller.favoriteArticles
                    .take(3) // Показуємо тільки 3 останніх статті
                    .map((article) => _buildFavoriteArticleItem(
                  context: context,
                  title: article.titleKey.tr,
                  imageUrl: article.imageUrl,
                  onTap: () => controller.openArticle(article),
                  onDelete: () => controller.removeFromFavorites(article.id),
                ))
                    .toList(),
              );
            }),
            if (controller.favoriteArticles.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Перейти до Beauty Hub
                    controller.navigateToBeautyHub();
                  },
                  icon: const Icon(Icons.add),
                  label: Text('browse_articles'.tr),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Налаштування
  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'settings'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => _buildToggleButton(
              icon: Icons.brightness_6,
              label: 'change_theme'.tr,
              color: Colors.pink,
              value: controller.isDarkMode.value,
              onChanged: (value) {
                // Логіка зміни теми
                controller.toggleTheme();
              },
            )),
            const SizedBox(height: 12),
            Obx(() => _buildToggleButton(
              icon: Icons.music_note,
              label: 'background_music'.tr,
              color: Colors.pink,
              value: !controller.isMusicMuted.value,
              onChanged: (value) {
                // Увімкнення/вимкнення фонової музики
                controller.toggleMusic();
              },
            )),
            // Admin access
            if (controller.isAdmin) ...[
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.admin_panel_settings,
                label: 'admin_panel'.tr,
                color: Colors.pink,
                onTap: () {
                  // Відкрити адмін-панель
                  Get.toNamed(AppRoutes.ADMIN);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FAQ
  Widget _buildFaqCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.pink.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'faq'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context: context,
              question: 'faq_question_1'.tr,
              answer: 'faq_answer_1'.tr,
            ),
            const SizedBox(height: 8),
            _buildFaqItem(
              context: context,
              question: 'faq_question_2'.tr,
              answer: 'faq_answer_2'.tr,
            ),
            const SizedBox(height: 8),
            _buildFaqItem(
              context: context,
              question: 'faq_question_3'.tr,
              answer: 'faq_answer_3'.tr,
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  // Показати всі FAQ
                  controller.viewAllFaq();
                },
                child: Text('view_all_faq'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Елемент FAQ з розгортанням
  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 14),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Елемент інформації з можливістю редагування
  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Кнопка дії
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.pink,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color),
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

  // Перемикач (toggle)
  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
    Color color = Colors.pink,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  // Елемент збереженої статті
  Widget _buildFavoriteArticleItem({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Діалог вибору віку
  void _showAgeSelectionDialog(BuildContext context) {
    final ageController = TextEditingController(
      text: controller.userAge.value?.toString() ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text('enter_age'.tr),
        content: TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'age'.tr,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              final ageText = ageController.text.trim();
              if (ageText.isEmpty) {
                controller.updateUserAge(null);
              } else {
                final age = int.tryParse(ageText);
                if (age != null && age > 0 && age < 120) {
                  controller.updateUserAge(age);
                }
              }
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  // Діалог вибору типу шкіри
  void _showSkinTypeSelectionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('select_skin_type'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSkinTypeOption(
                label: 'skin_type_normal'.tr,
                value: 'normal',
                groupValue: controller.userSkinType.value,
                onChanged: (value) {
                  controller.updateUserSkinType(value);
                  Get.back();
                },
              ),
              _buildSkinTypeOption(
                label: 'skin_type_dry'.tr,
                value: 'dry',
                groupValue: controller.userSkinType.value,
                onChanged: (value) {
                  controller.updateUserSkinType(value);
                  Get.back();
                },
              ),
              _buildSkinTypeOption(
                label: 'skin_type_oily'.tr,
                value: 'oily',
                groupValue: controller.userSkinType.value,
                onChanged: (value) {
                  controller.updateUserSkinType(value);
                  Get.back();
                },
              ),
              _buildSkinTypeOption(
                label: 'skin_type_combination'.tr,
                value: 'combination',
                groupValue: controller.userSkinType.value,
                onChanged: (value) {
                  controller.updateUserSkinType(value);
                  Get.back();
                },
              ),
              _buildSkinTypeOption(
                label: 'skin_type_sensitive'.tr,
                value: 'sensitive',
                groupValue: controller.userSkinType.value,
                onChanged: (value) {
                  controller.updateUserSkinType(value);
                  Get.back();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  // Опція типу шкіри
  Widget _buildSkinTypeOption({
    required String label,
    required String value,
    required String? groupValue,
    required Function(String) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      contentPadding: EdgeInsets.zero,
    );
  }
}