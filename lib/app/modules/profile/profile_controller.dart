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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ThemeService _themeService = Get.find<ThemeService>();
  final LocalizationService _localizationService = Get.find<LocalizationService>();
  final ImagePicker _picker = ImagePicker();
  final BackgroundMusicHandler _musicHandler = BackgroundMusicHandler.instance;

  final nameController = TextEditingController();
  final RxBool isEditingName = false.obs;
  final RxBool isLoading = false.obs;

  // Нові додаткові змінні користувача
  final RxnInt userAge = RxnInt();
  final Rxn<String> userSkinType = Rxn<String>();

  // Змінні для реактивного інтерфейсу
  final RxBool isDarkMode = false.obs;
  final RxBool isMusicMuted = false.obs;

  // Збережені статті
  final RxList<Article> favoriteArticles = <Article>[].obs;

  // Геттери для доступу до даних користувача
  String get userEmail => _authService.userModel?.email ?? '';
  String get userName => _authService.userModel?.displayName ?? 'user'.tr;
  String? get userPhotoUrl => _authService.userModel?.photoUrl;
  DateTime? get userCreatedAt => _authService.userModel?.createdAt;
  DateTime? get userLastLogin => _authService.userModel?.lastLogin;

  @override
  void onInit() {
    super.onInit();
    nameController.text = userName;
    // Відстеження стану теми та музики
    isDarkMode.value = _themeService.isDarkMode;
    isMusicMuted.value = _musicHandler.isMuted;

    // Завантаження даних
    _loadUserPreferences();
    _loadFavoritesFromFirestore();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // Завантаження збережених налаштувань користувача
  void _loadUserPreferences() {
    if (_authService.userModel?.preferences != null) {
      final prefs = _authService.userModel!.preferences!;

      // Завантаження віку
      if (prefs.containsKey('age')) {
        userAge.value = prefs['age'] as int?;
      }

      // Завантаження типу шкіри
      if (prefs.containsKey('skinType')) {
        userSkinType.value = prefs['skinType'] as String?;
      }
    }
  }

  // Завантаження збережених статей (локальні тестові дані)
  void _loadFavoriteArticles() {
    // Ініціалізація пустого масиву (реальні дані будуть завантажені з Firebase)
    favoriteArticles.value = [];
  }

  // Завантаження збережених статей з Firebase
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

  // Вихід з облікового запису
  Future<void> signOut() async {
    await _authService.signOut();
    Get.back(); // Повертаємося на попередній екран
  }

  // Початок редагування імені
  void startEditingName() {
    nameController.text = userName;
    isEditingName.value = true;
  }

  // Збереження зміненого імені
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

  // Скасування редагування імені
  void cancelEditingName() {
    isEditingName.value = false;
  }

  // Оновлення віку користувача
  Future<void> updateUserAge(int? age) async {
    isLoading.value = true;
    try {
      // Оновлюємо локальне значення
      userAge.value = age;

      // Оновлюємо в базі даних
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

  // Оновлення типу шкіри
  Future<void> updateUserSkinType(String? skinType) async {
    isLoading.value = true;
    try {
      // Оновлюємо локальне значення
      userSkinType.value = skinType;

      // Оновлюємо в базі даних
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

  // Вибір і завантаження фото профілю
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

      // Завантаження у Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_authService.currentUser!.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Оновлення URL фото у профілі
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

  // Форматування дати для відображення
  String formatDate(DateTime? date) {
    if (date == null) return 'unknown'.tr;
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }

  // Зміна мови
  void changeLanguage() {
    final currentLanguage = _localizationService.getCurrentLocale();
    final languages = LocalizationService.supportedLocales;

    Get.dialog(
      AlertDialog(
        title: Text('select_language'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((locale) {
              final langCode = locale.languageCode;
              final langName = _localizationService.getLanguageName(langCode);
              return ListTile(
                title: Text(langName),
                trailing: currentLanguage.languageCode == langCode
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _localizationService.changeLocale(langCode);
                  Get.back();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Зміна теми
  void toggleTheme() {
    _themeService.toggleTheme();
    isDarkMode.value = _themeService.isDarkMode;
    Get.snackbar(
      'info'.tr,
      'theme_changed'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Увімкнення/вимкнення музики
  void toggleMusic() {
    _musicHandler.toggleMute();
    isMusicMuted.value = _musicHandler.isMuted;
    Get.snackbar(
      'info'.tr,
      _musicHandler.isMuted ? 'music_off'.tr : 'music_on'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Відкрити статтю
  void openArticle(Article article) {
    Get.to(() => ArticleDetailsScreen(article: article));
  }

  // Видалити статтю з обраного
  Future<void> removeFromFavorites(String articleId) async {
    // Локальне видалення
    favoriteArticles.removeWhere((article) => article.id == articleId);

    try {
      // Видалення з бази даних
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

  // Переглянути всі збережені статті
  void viewAllFavoriteArticles() {
    // Реалізація перегляду всіх збережених статей
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

  // Перейти до Beauty Hub
  void navigateToBeautyHub() {
    Get.to(() => const BeautyHubScreen());
  }

  // Переглянути всі FAQ
  void viewAllFaq() {
    // Реалізація перегляду всіх FAQ
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