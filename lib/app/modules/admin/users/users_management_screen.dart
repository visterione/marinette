// lib/app/modules/admin/users/users_management_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marinette/app/modules/admin/users/user_edit_screen.dart';

class UsersManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedRoleFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('users').get();

      final loadedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({
          'uid': doc.id,
          ...data,
        });
      }).toList();

      users.value = loadedUsers;
      debugPrint('Loaded ${users.length} users');
    } catch (e) {
      debugPrint('Error loading users: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_users'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // Note: Deleting a user from Firebase Authentication requires
      // either an Admin SDK or Cloud Functions. Here we just delete from Firestore.
      await _firestore.collection('users').doc(userId).delete();

      // Remove from the local list
      users.removeWhere((user) => user.uid == userId);

      Get.snackbar(
        'success'.tr,
        'user_deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      Get.snackbar(
        'error'.tr,
        'error_deleting_user'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  List<UserModel> getFilteredUsers() {
    var filteredUsers = users.toList();
    final query = searchQuery.value.toLowerCase();

    // Filter by role
    if (selectedRoleFilter.value == 'admin') {
      filteredUsers = filteredUsers.where((user) =>
      user.preferences?['isAdmin'] == true
      ).toList();
    } else if (selectedRoleFilter.value == 'regular') {
      filteredUsers = filteredUsers.where((user) =>
      user.preferences?['isAdmin'] != true
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) =>
      user.email.toLowerCase().contains(query) ||
          (user.displayName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return filteredUsers;
  }

  bool isUserAdmin(UserModel user) {
    return user.preferences?['isAdmin'] == true;
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class UsersManagementScreen extends StatelessWidget {
  final controller = Get.put(UsersManagementController());

  UsersManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_users'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'search_users'.tr,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => controller.searchQuery.value = value,
                ),

                const SizedBox(height: 12),

                // Role filter - adapt based on screen size
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 500) {
                      // Use dropdown for small screens
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Obx(() => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'filter_by_role'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          value: controller.selectedRoleFilter.value,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('all_users'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admins'.tr),
                            ),
                            DropdownMenuItem(
                              value: 'regular',
                              child: Text('regular_users'.tr),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedRoleFilter.value = value;
                            }
                          },
                        )),
                      );
                    } else {
                      // Use segmented button for larger screens
                      return Row(
                        children: [
                          Text('filter_by_role'.tr + ':'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Obx(() => SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'all',
                                  label: Text('all_users'.tr),
                                  icon: const Icon(Icons.people),
                                ),
                                ButtonSegment(
                                  value: 'admin',
                                  label: Text('admins'.tr),
                                  icon: const Icon(Icons.admin_panel_settings),
                                ),
                                ButtonSegment(
                                  value: 'regular',
                                  label: Text('regular_users'.tr),
                                  icon: const Icon(Icons.person),
                                ),
                              ],
                              selected: {controller.selectedRoleFilter.value},
                              onSelectionChanged: (Set<String> selection) {
                                controller.selectedRoleFilter.value = selection.first;
                              },
                            )),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = controller.getFilteredUsers();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty || controller.selectedRoleFilter.value != 'all'
                            ? 'no_users_found'.tr
                            : 'no_users'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) => _buildUserItem(context, users[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserModel user) {
    final bool isAdmin = controller.isUserAdmin(user);
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and avatar row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),

                // User basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName ?? 'No Name',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin && !isSmallScreen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.admin_panel_settings, size: 16, color: Colors.pink),
                                  const SizedBox(width: 4),
                                  Text(
                                    'admin'.tr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Show admin badge on a new line for small screens
                      if (isAdmin && isSmallScreen)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.admin_panel_settings, size: 16, color: Colors.pink),
                                const SizedBox(width: 4),
                                Text(
                                  'admin'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Email with ellipsis for overflow
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Dates in a smaller font with better formatting
                      Text(
                        '${'created'.tr}: ${controller.formatDateTime(user.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${'last_login'.tr}: ${controller.formatDateTime(user.lastLogin)}',
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

            const SizedBox(height: 16),
            const Divider(),

            // Action buttons - show in a column for small screens, row for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 450) {
                  // Column layout for small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => UserEditScreen(user: user));
                        },
                        icon: const Icon(Icons.visibility),
                        label: Text('view_details'.tr),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Confirmation dialog
                          Get.dialog(
                            AlertDialog(
                              title: Text('confirm_delete'.tr),
                              content: Text('confirm_delete_user'.tr),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('cancel'.tr),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.deleteUser(user.uid);
                                  },
                                  child: Text(
                                    'delete'.tr,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Row layout for larger screens
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // View user details
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => UserEditScreen(user: user));
                        },
                        icon: const Icon(Icons.visibility),
                        label: Text('view_details'.tr),
                      ),
                      const SizedBox(width: 8),

                      // Delete user
                      TextButton.icon(
                        onPressed: () {
                          // Confirmation dialog
                          Get.dialog(
                            AlertDialog(
                              title: Text('confirm_delete'.tr),
                              content: Text('confirm_delete_user'.tr),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('cancel'.tr),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.deleteUser(user.uid);
                                  },
                                  child: Text(
                                    'delete'.tr,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}