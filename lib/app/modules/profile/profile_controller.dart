// lib/app/modules/profile/profile_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:marinette/app/core/theme/theme_service.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:marinette/app/modules/beauty_hub/beauty_hub_screen.dart';
import 'package:marinette/app/modules/article/article_details_screen.dart';
import 'package:marinette/app/data/services/background_music_handler.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/data/services/firestore_analysis_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../data/services/firebase_analysis_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ThemeService _themeService = Get.find<ThemeService>();
  final LocalizationService _localizationService = Get.find<LocalizationService>();
  final ImagePicker _picker = ImagePicker();
  final BackgroundMusicHandler _musicHandler = BackgroundMusicHandler.instance;

  final nameController = TextEditingController();
  final RxBool isEditingName = false.obs;
  final RxBool isLoading = false.obs;

  // User additional variables
  final RxnInt userAge = RxnInt();
  final Rxn<String> userSkinType = Rxn<String>();

  // Variables for reactive UI
  final RxBool isDarkMode = false.obs;
  final RxBool isMusicMuted = false.obs;

  // Saved articles
  final RxList<Article> favoriteArticles = <Article>[].obs;

  // Getters for user data access
  String get userEmail => _authService.userModel?.email ?? '';
  String get userName => _authService.userModel?.displayName ?? 'user'.tr;
  String? get userPhotoUrl => _authService.userModel?.photoUrl;
  DateTime? get userCreatedAt => _authService.userModel?.createdAt;
  DateTime? get userLastLogin => _authService.userModel?.lastLogin;

  // Method to check if the user has admin rights
  bool get isAdmin {
    // In a real app, check role in the database
    // For example, just check a specific email
    // or user ID
    if (_authService.currentUser?.email == 'stecenko.work@gmail.com') {
      return true;
    }

    // Additional check via Firestore
    return _authService.userModel?.preferences?['isAdmin'] == true;
  }

  // Method to open admin panel
  void openAdminPanel() {
    if (isAdmin) {
      Get.toNamed('/admin');
    } else {
      Get.snackbar(
        'error'.tr,
        'admin_access_denied'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    nameController.text = userName;

    // Initialize with locally stored values first
    isDarkMode.value = _themeService.isDarkMode;
    isMusicMuted.value = _musicHandler.isMuted;

    // Load data
    _loadUserPreferences();
    _loadFavoritesFromFirestore();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // Load saved user preferences
  void _loadUserPreferences() {
    if (_authService.userModel?.preferences != null) {
      final prefs = _authService.userModel!.preferences!;

      // Load age
      if (prefs.containsKey('age')) {
        userAge.value = prefs['age'] as int?;
      }

      // Load skin type
      if (prefs.containsKey('skinType')) {
        userSkinType.value = prefs['skinType'] as String?;
      }

      // Load theme preference
      if (prefs.containsKey('isDarkMode')) {
        bool savedIsDarkMode = prefs['isDarkMode'] as bool? ?? false;

        // Only update if different from current setting
        if (savedIsDarkMode != isDarkMode.value) {
          // Update local theme service
          _themeService.changeThemeMode(savedIsDarkMode ? ThemeMode.dark : ThemeMode.light);
          isDarkMode.value = savedIsDarkMode;
        }
      }
    }
  }

  // Load saved articles from Firebase
  Future<void> _loadFavoritesFromFirestore() async {
    if (_authService.currentUser == null) return;

    try {
      isLoading.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      final articles = snapshot.docs.map((doc) {
        final data = doc.data();
        return Article(
          id: doc.id,
          titleKey: data['titleKey'],
          descriptionKey: data['descriptionKey'],
          imageUrl: data['imageUrl'],
          contentKey: data['contentKey'],
          publishedAt: DateTime.fromMillisecondsSinceEpoch(data['publishedAt']),
          authorNameKey: data['authorNameKey'],
          authorAvatarUrl: data['authorAvatarUrl'],
        );
      }).toList();

      favoriteArticles.value = articles;
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out from account
  Future<void> signOut() async {
    await _authService.signOut();
    Get.back(); // Return to previous screen
  }

  // Start editing name
  void startEditingName() {
    nameController.text = userName;
    isEditingName.value = true;
  }

  // Save changed name
  Future<void> saveName() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success = await _authService.updateUserProfile(
        displayName: nameController.text.trim(),
      );

      if (success) {
        isEditingName.value = false;
        Get.snackbar(
          'success'.tr,
          'profile_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'update_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
      Get.snackbar(
        'error'.tr,
        'update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel name editing
  void cancelEditingName() {
    isEditingName.value = false;
  }

  // Update user age
  Future<void> updateUserAge(int? age) async {
    isLoading.value = true;
    try {
      // Update local value
      userAge.value = age;

      // Update in database
      final Map<String, dynamic> preferences =
          _authService.userModel?.preferences?.cast<String, dynamic>() ?? {};

      if (age == null) {
        preferences.remove('age');
      } else {
        preferences['age'] = age;
      }

      final success = await _authService.updateUserProfile(
        preferences: preferences,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'age_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error updating age: $e');
      Get.snackbar(
        'error'.tr,
        'update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update skin type
  Future<void> updateUserSkinType(String? skinType) async {
    isLoading.value = true;
    try {
      // Update local value
      userSkinType.value = skinType;

      // Update in database
      final Map<String, dynamic> preferences =
          _authService.userModel?.preferences?.cast<String, dynamic>() ?? {};

      if (skinType == null) {
        preferences.remove('skinType');
      } else {
        preferences['skinType'] = skinType;
      }

      final success = await _authService.updateUserProfile(
        preferences: preferences,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'skin_type_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error updating skin type: $e');
      Get.snackbar(
        'error'.tr,
        'update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Pick and upload profile photo
  Future<void> pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      isLoading.value = true;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_authService.currentUser!.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Update photo URL in profile
      final success = await _authService.updateUserProfile(
        photoUrl: downloadUrl,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'photo_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'photo_update_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      Get.snackbar(
        'error'.tr,
        'photo_upload_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Format date for display
  String formatDate(DateTime? date) {
    if (date == null) return 'unknown'.tr;
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }

  // Toggle theme and save to Firebase
  Future<void> toggleTheme() async {
    _themeService.toggleTheme();
    isDarkMode.value = _themeService.isDarkMode;

    // Save to Firebase
    try {
      // Update in database
      final Map<String, dynamic> preferences =
          _authService.userModel?.preferences?.cast<String, dynamic>() ?? {};

      preferences['isDarkMode'] = isDarkMode.value;

      final success = await _authService.updateUserProfile(
        preferences: preferences,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'theme_changed'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      // Still show success message for local theme change
      Get.snackbar(
        'info'.tr,
        'theme_changed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Toggle music
  void toggleMusic() {
    _musicHandler.toggleMute();
    isMusicMuted.value = _musicHandler.isMuted;
    Get.snackbar(
      'info'.tr,
      _musicHandler.isMuted ? 'music_off'.tr : 'music_on'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Open article
  void openArticle(Article article) {
    Get.to(() => ArticleDetailsScreen(article: article));
  }

  // Remove article from favorites
  Future<void> removeFromFavorites(String articleId) async {
    // Local removal
    favoriteArticles.removeWhere((article) => article.id == articleId);

    try {
      // Database removal
      if (_authService.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('favorites')
            .doc(articleId)
            .delete();

        Get.snackbar(
          'success'.tr,
          'article_removed_from_favorites'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error removing article from favorites: $e');
      Get.snackbar(
        'error'.tr,
        'error_removing_article'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // View all saved articles
  void viewAllFavoriteArticles() {
    // Implementation of viewing all saved articles
    Get.dialog(
      AlertDialog(
        title: Text('saved_articles'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (favoriteArticles.isEmpty) {
              return Center(
                child: Text('no_saved_articles'.tr),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: favoriteArticles.length,
              itemBuilder: (context, index) {
                final article = favoriteArticles[index];
                return ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ),
                    ),
                  ),
                  title: Text(
                    article.titleKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      Get.back();
                      removeFromFavorites(article.id);
                    },
                  ),
                  onTap: () {
                    Get.back();
                    openArticle(article);
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  // Go to Beauty Hub
  void navigateToBeautyHub() {
    Get.to(() => const BeautyHubScreen());
  }

  // View all FAQ
  void viewAllFaq() {
    // Implementation of viewing all FAQ
    Get.dialog(
      AlertDialog(
        title: Text('faq'.tr),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              ExpansionTile(
                title: Text('faq_question_1'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('faq_answer_1'.tr),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('faq_question_2'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('faq_answer_2'.tr),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('faq_question_3'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('faq_answer_3'.tr),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('faq_question_4'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('faq_answer_4'.tr),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('faq_question_5'.tr),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('faq_answer_5'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }
}