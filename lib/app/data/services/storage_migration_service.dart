// lib/app/data/services/storage_migration_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/article.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class StorageMigrationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Статус міграції
  final RxBool isMigrationInProgress = false.obs;
  final RxInt totalItems = 0.obs;
  final RxInt processedItems = 0.obs;
  final RxString currentOperation = ''.obs;

  // Міграція зображень статей
  Future<void> migrateArticleImages() async {
    try {
      isMigrationInProgress.value = true;
      currentOperation.value = 'Migrating article images';

      // Отримуємо список усіх статей
      final articlesSnapshot = await _firestore.collection('articles').get();

      totalItems.value = articlesSnapshot.docs.length;
      processedItems.value = 0;

      for (var doc in articlesSnapshot.docs) {
        try {
          final data = doc.data();
          final String originalImageUrl = data['imageUrl'];

          // Проверяем, содержит ли URL Google Drive
          if (originalImageUrl.contains('drive.google.com') ||
              originalImageUrl.contains('googleusercontent.com')) {

            // Формируем путь в Firebase Storage
            final destinationPath = '${StorageService.ARTICLES_PATH}/${doc.id}.jpg';

            // Загружаем в Firebase Storage и получаем новый URL
            final newImageUrl = await _storageService.getOrUploadImage(
                originalImageUrl,
                destinationPath
            );

            if (newImageUrl != null) {
              // Обновляем документ в Firestore
              await _firestore.collection('articles').doc(doc.id).update({
                'imageUrl': newImageUrl,
                'migrated': true
              });

              debugPrint('Migrated article image: ${doc.id}');
            }
          }
        } catch (e) {
          debugPrint('Error migrating article image: ${doc.id}, error: $e');
        }

        processedItems.value++;
      }
    } catch (e) {
      debugPrint('Error in migrateArticleImages: $e');
    } finally {
      isMigrationInProgress.value = false;
    }
  }

  // Міграція зображень сторіз
  Future<void> migrateStoryImages() async {
    try {
      isMigrationInProgress.value = true;
      currentOperation.value = 'Migrating story images';

      // Отримуємо список усіх сторіз
      final storiesSnapshot = await _firestore.collection('stories').get();

      totalItems.value = 0;

      // Рахуємо загальну кількість зображень
      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> imageUrls = data['imageUrls'] ?? [];
        totalItems.value += imageUrls.length;

        // Додаємо превью
        if (data['previewImageUrl'] != null) {
          totalItems.value++;
        }
      }

      processedItems.value = 0;

      for (var doc in storiesSnapshot.docs) {
        try {
          final data = doc.data();
          final String storyId = doc.id;

          // Міграція зображення превью
          if (data['previewImageUrl'] != null) {
            final String originalPreviewUrl = data['previewImageUrl'];

            if (originalPreviewUrl.contains('drive.google.com') ||
                originalPreviewUrl.contains('googleusercontent.com')) {

              final previewPath = '${StorageService.STORIES_PATH}/$storyId/preview.jpg';
              final newPreviewUrl = await _storageService.getOrUploadImage(
                  originalPreviewUrl,
                  previewPath
              );

              if (newPreviewUrl != null) {
                await _firestore.collection('stories').doc(storyId).update({
                  'previewImageUrl': newPreviewUrl
                });

                debugPrint('Migrated story preview: $storyId');
              }
            }

            processedItems.value++;
          }

          // Міграція зображень сторіз
          final List<dynamic> imageUrls = data['imageUrls'] ?? [];
          List<String> newImageUrls = [];

          for (int i = 0; i < imageUrls.length; i++) {
            final String originalImageUrl = imageUrls[i];

            if (originalImageUrl.contains('drive.google.com') ||
                originalImageUrl.contains('googleusercontent.com')) {

              // Формуємо шлях у Firebase Storage з порядковим номером
              final imagePath = '${StorageService.STORIES_PATH}/$storyId/${i.toString().padLeft(2, '0')}.jpg';

              final newImageUrl = await _storageService.getOrUploadImage(
                  originalImageUrl,
                  imagePath
              );

              if (newImageUrl != null) {
                newImageUrls.add(newImageUrl);
              } else {
                // Якщо не вдалося мігрувати, використовуємо оригінальний URL
                newImageUrls.add(originalImageUrl);
              }
            } else {
              // Якщо URL вже не з Google Drive, додаємо його як є
              newImageUrls.add(originalImageUrl);
            }

            processedItems.value++;
          }

          if (newImageUrls.isNotEmpty) {
            await _firestore.collection('stories').doc(storyId).update({
              'imageUrls': newImageUrls,
              'migrated': true
            });

            debugPrint('Migrated story images: $storyId');
          }
        } catch (e) {
          debugPrint('Error migrating story: ${doc.id}, error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in migrateStoryImages: $e');
    } finally {
      isMigrationInProgress.value = false;
    }
  }

  // Повна міграція всіх зображень
  Future<void> migrateAllImages() async {
    isMigrationInProgress.value = true;

    try {
      await migrateArticleImages();
      await migrateStoryImages();
    } catch (e) {
      debugPrint('Error in migrateAllImages: $e');
    } finally {
      isMigrationInProgress.value = false;
    }
  }

  // Верифікація міграції
  Future<Map<String, dynamic>> verifyMigration() async {
    final result = {
      'articlesTotal': 0,
      'articlesMigrated': 0,
      'storiesTotal': 0,
      'storiesMigrated': 0,
      'googleDriveUrls': <String>[],
    };

    try {
      // Перевірка статей
      final articlesSnapshot = await _firestore.collection('articles').get();
      result['articlesTotal'] = articlesSnapshot.docs.length;

      for (var doc in articlesSnapshot.docs) {
        final data = doc.data();
        final String imageUrl = data['imageUrl'] ?? '';

        if (data['migrated'] == true) {
          result['articlesMigrated'] = (result['articlesMigrated'] as int) + 1;
        }

        if (imageUrl.contains('drive.google.com') ||
            imageUrl.contains('googleusercontent.com')) {
          (result['googleDriveUrls'] as List<String>).add('Article ${doc.id}: $imageUrl');
        }
      }

      // Перевірка сторіз
      final storiesSnapshot = await _firestore.collection('stories').get();
      result['storiesTotal'] = storiesSnapshot.docs.length;

      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();

        if (data['migrated'] == true) {
          result['storiesMigrated'] = (result['storiesMigrated'] as int) + 1;
        }

        final String previewUrl = data['previewImageUrl'] ?? '';
        if (previewUrl.contains('drive.google.com') ||
            previewUrl.contains('googleusercontent.com')) {
          (result['googleDriveUrls'] as List<String>).add('Story ${doc.id} preview: $previewUrl');
        }

        final List<dynamic> imageUrls = data['imageUrls'] ?? [];
        for (int i = 0; i < imageUrls.length; i++) {
          final String imageUrl = imageUrls[i];
          if (imageUrl.contains('drive.google.com') ||
              imageUrl.contains('googleusercontent.com')) {
            (result['googleDriveUrls'] as List<String>).add('Story ${doc.id} image $i: $imageUrl');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in verifyMigration: $e');
    }

    return result;
  }
}