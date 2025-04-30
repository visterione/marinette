// lib/app/modules/admin/users/user_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserEditController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserModel user;

  // For editing user data
  late TextEditingController displayNameController;

  // For editing user preferences
  final RxnInt userAge = RxnInt();
  final Rxn<String> userSkinType = Rxn<String>();
  final RxBool isAdmin = false.obs;

  // Activity tracking
  final RxList<Map<String, dynamic>> userActivity = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> favoriteArticles = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> analysisResults = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  UserEditController({required this.user});

  @override
  void onInit() {
    super.onInit();
    displayNameController = TextEditingController(text: user.displayName ?? '');

    // Initialize preferences
    if (user.preferences != null) {
      userAge.value = user.preferences!['age'] as int?;
      userSkinType.value = user.preferences!['skinType'] as String?;
      isAdmin.value = user.preferences!['isAdmin'] == true;
    }

    loadUserData();
  }

  @override
  void onClose() {
    displayNameController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    isLoading.value = true;
    try {
      // Load user's favorite articles
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      favoriteArticles.value = favoritesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Load user's analysis results (just count for now)
      final analysisSnapshot = await _firestore
          .collection('user_analysis')
          .where('userId', isEqualTo: user.uid)
          .get();

      analysisResults.value = analysisSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Load user activity log
      final activitySnapshot = await _firestore
          .collection('user_activity')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      userActivity.value = activitySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveUser() async {
    isSaving.value = true;
    try {
      // Update user preferences
      final Map<String, dynamic> preferences = user.preferences?.cast<String, dynamic>() ?? {};

      preferences['age'] = userAge.value;
      preferences['skinType'] = userSkinType.value;
      preferences['isAdmin'] = isAdmin.value;

      // Update user in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayNameController.text.trim(),
        'preferences': preferences,
      });

      Get.snackbar(
        'success'.tr,
        'user_updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      Get.snackbar(
        'error'.tr,
        'error_updating_user'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return 'Invalid date';
    }

    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class UserEditScreen extends StatelessWidget {
  final UserModel user;

  const UserEditScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserEditController(user: user));

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_user'.tr),
        actions: [
          Obx(() => controller.isSaving.value
              ? Container(
            margin: const EdgeInsets.all(16),
            width: 24,
            height: 24,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveUser,
          ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile card
              Card(
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
                        'profile_information'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile picture and basic info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user.photoUrl != null
                                ? CachedNetworkImageProvider(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display name field
                                TextField(
                                  controller: controller.displayNameController,
                                  decoration: InputDecoration(
                                    labelText: 'display_name'.tr,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Email (read-only)
                                Text(
                                  'Email: ${user.email}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // User ID (for reference)
                                Text(
                                  'User ID: ${user.uid}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Dates
                                Text(
                                  '${'created'.tr}: ${controller.formatDateTime(user.createdAt.millisecondsSinceEpoch)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${'last_login'.tr}: ${controller.formatDateTime(user.lastLogin.millisecondsSinceEpoch)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User preferences
              Card(
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
                        'user_preferences'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Age preference
                      Row(
                        children: [
                          Text(
                            'age'.tr + ': ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => DropdownButtonFormField<int?>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              value: controller.userAge.value,
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('not_specified'.tr),
                                ),
                                ...List.generate(70, (index) => index + 15).map((age) =>
                                    DropdownMenuItem<int?>(
                                      value: age,
                                      child: Text('$age'),
                                    )
                                ),
                              ],
                              onChanged: (value) {
                                controller.userAge.value = value;
                              },
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Skin type preference
                      Row(
                        children: [
                          Text(
                            'skin_type'.tr + ': ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => DropdownButtonFormField<String?>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              value: controller.userSkinType.value,
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('not_specified'.tr),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'normal',
                                  child: Text('skin_type_normal'.tr),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'dry',
                                  child: Text('skin_type_dry'.tr),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'oily',
                                  child: Text('skin_type_oily'.tr),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'combination',
                                  child: Text('skin_type_combination'.tr),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'sensitive',
                                  child: Text('skin_type_sensitive'.tr),
                                ),
                              ],
                              onChanged: (value) {
                                controller.userSkinType.value = value;
                              },
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Admin role toggle
                      Row(
                        children: [
                          Text(
                            'admin_rights'.tr + ': ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => Switch(
                            value: controller.isAdmin.value,
                            onChanged: (value) {
                              controller.isAdmin.value = value;
                            },
                            activeColor: Colors.pink,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User activity
              Card(
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
                        'user_activity'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User statistics
                      _buildStatisticItem(
                        icon: Icons.article,
                        label: 'saved_articles'.tr,
                        value: controller.favoriteArticles.length.toString(),
                      ),
                      const SizedBox(height: 8),
                      _buildStatisticItem(
                        icon: Icons.face,
                        label: 'analysis_results'.tr,
                        value: controller.analysisResults.length.toString(),
                      ),

                      if (controller.userActivity.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        Text(
                          'recent_activity'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Activity log list
                        ...controller.userActivity.take(5).map((activity) =>
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                _getActivityIcon(activity['type'] ?? ''),
                                color: Colors.pink,
                              ),
                              title: Text(activity['description'] ?? 'Unknown activity'),
                              subtitle: Text(controller.formatDateTime(activity['timestamp'])),
                              dense: true,
                            ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.pink),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'login':
        return Icons.login;
      case 'analysis':
        return Icons.face;
      case 'article_save':
        return Icons.bookmark;
      case 'article_view':
        return Icons.article;
      default:
        return Icons.history;
    }
  }
}