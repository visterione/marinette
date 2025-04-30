// lib/app/data/services/stories_service.dart
// Оновлена версія з підтримкою Firebase Storage

import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marinette/app/data/services/storage_service.dart';

class StoriesService extends GetxService {
  final RxList<Story> stories = <Story>[].obs;
  static const String _viewedStoriesKey = 'viewed_stories';
  late SharedPreferences _prefs;
  final RxMap<String, bool> preloadedImages = <String, bool>{}.obs;
  final RxInt _activePreloads = 0.obs;
  static const int maxConcurrentPreloads = 3;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StorageService _storageService;

  @visibleForTesting
  set prefs(SharedPreferences value) {
    _prefs = value;
  }

  @override
  void onInit() async {
    super.onInit();
    await init();
  }

  Future<StoriesService> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _storageService = Get.find<StorageService>();

      await loadStories();
      ever(Get.find<LocalizationService>().locale, (_) => loadStories());
      return this;
    } catch (e) {
      debugPrint('Error initializing StoriesService: $e');
      return this;
    }
  }

  Future<void> loadStories() async {
    try {
      final viewedStories = _prefs.getStringList(_viewedStoriesKey) ?? [];
      debugPrint('Loading stories. Viewed stories: $viewedStories');

      // Загружаем сторис из Firestore
      final storiesSnapshot = await _firestore.collection('stories')
          .orderBy('order') // если есть поле для сортировки
          .get();

      List<Story> loadedStories = [];

      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();

        try {
          // Получаем URL-адреса изображений
          List<String> imageUrls = [];

          // Проверяем, есть ли мигрированные URL-адреса
          if (data['migrated'] == true) {
            imageUrls = List<String>.from(data['imageUrls']);
          } else {
            // Используем URL-адреса из базы данных
            imageUrls = List<String>.from(data['imageUrls']);
          }

          // Получаем URL превью
          String previewImageUrl = data['previewImageUrl'] ?? '';

          loadedStories.add(Story(
            id: doc.id,
            title: data['title'] ?? '',
            imageUrls: imageUrls,
            captions: List<String>.from(data['captions'] ?? []),
            category: data['category'] ?? '',
            previewImageUrl: previewImageUrl,
            isViewed: viewedStories.contains(doc.id),
          ));
        } catch (e) {
          debugPrint('Error creating Story object for ${doc.id}: $e');
        }
      }

      stories.value = loadedStories;

      _startBackgroundPreloading();
      debugPrint('Stories loaded successfully: ${stories.length} stories');
    } catch (e) {
      debugPrint('Error loading stories: $e');
      stories.value = []; // В случае ошибки возвращаем пустой список
    }
  }

  @visibleForTesting
  bool isTestMode = false;

  void _startBackgroundPreloading() {
    // В тестовом режиме не выполняем реальное предзагрузку
    if (isTestMode) {
      return;
    }

    // Предзагрузка превью изображений
    for (var story in stories) {
      // Проверка на пустой URL или некорректный URL
      if (story.previewImageUrl.isNotEmpty && Uri.tryParse(story.previewImageUrl.tr)?.hasAuthority == true) {
        preloadSingleImage(story.previewImageUrl.tr, priority: true);
      }
    }

    // Предзагрузка изображений слайдов
    for (var story in stories) {
      for (var imageUrl in story.imageUrls) {
        // Проверка на пустой URL или некорректный URL
        if (imageUrl.isNotEmpty && Uri.tryParse(imageUrl.tr)?.hasAuthority == true) {
          preloadSingleImage(imageUrl.tr, priority: false);
        }
      }
    }
  }

  Future<void> preloadSingleImage(String imageUrl, {bool priority = false}) async {
    // Если это тестовое окружение, сразу помечаем как загруженное
    if (isTestMode) {
      preloadedImages[imageUrl] = true;
      return;
    }

    // Проверка на пустой URL или некорректный URL
    if (imageUrl.isEmpty || !Uri.tryParse(imageUrl)!.hasAuthority) {
      // Отмечаем как "загруженное", чтобы избежать повторных попыток загрузки
      preloadedImages[imageUrl] = true;
      debugPrint('Skipping preload for empty or invalid URL: $imageUrl');
      return;
    }

    // Остальная логика загрузки
    if (preloadedImages.containsKey(imageUrl)) return;

    while (_activePreloads.value >= maxConcurrentPreloads && !priority) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _activePreloads.value++;
    preloadedImages[imageUrl] = false;

    try {
      final completer = Completer<void>();

      final ImageProvider provider = CachedNetworkImageProvider(imageUrl);
      final ImageStream stream = provider.resolve(const ImageConfiguration());

      final listener = ImageStreamListener(
            (ImageInfo info, bool sync) {
          preloadedImages[imageUrl] = true;
          _activePreloads.value--;
          if (!completer.isCompleted) completer.complete();
          debugPrint('Successfully preloaded: $imageUrl');
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          debugPrint('Error preloading image $imageUrl: $exception');
          preloadedImages[imageUrl] = false;
          _activePreloads.value--;
          if (!completer.isCompleted) completer.complete();
        },
      );

      stream.addListener(listener);
      await completer.future;
      stream.removeListener(listener);
    } catch (e) {
      debugPrint('Error initiating preload for $imageUrl: $e');
      preloadedImages[imageUrl] = false;
      _activePreloads.value--;
    }
  }

  bool isStoryReady(Story story) {
    final previewLoaded = preloadedImages[story.previewImageUrl.tr] ?? false;
    final firstImageLoaded = preloadedImages[story.imageUrls.first.tr] ?? false;
    return previewLoaded && firstImageLoaded;
  }

  bool isImagePreloaded(String imageUrl) {
    return preloadedImages[imageUrl.tr] ?? false;
  }

  Future<void> preloadNextStoryImages(int currentStoryIndex) async {
    if (currentStoryIndex >= stories.length - 1) return;

    final nextStory = stories[currentStoryIndex + 1];
    await preloadSingleImage(nextStory.previewImageUrl.tr, priority: true);
    for (var imageUrl in nextStory.imageUrls) {
      await preloadSingleImage(imageUrl.tr, priority: true);
    }
  }

  Future<void> markStoryAsViewed(String storyId) async {
    try {
      debugPrint('Marking story as viewed: $storyId');
      final viewedStories = _prefs.getStringList(_viewedStoriesKey) ?? [];

      if (!viewedStories.contains(storyId)) {
        viewedStories.add(storyId);
        await _prefs.setStringList(_viewedStoriesKey, viewedStories);

        final index = stories.indexWhere((story) => story.id == storyId);
        if (index != -1) {
          final updatedStory = stories[index].copyWith(isViewed: true);
          stories[index] = updatedStory;
          debugPrint('Story marked as viewed successfully');
        }
      }
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }

  Future<void> resetViewedStories() async {
    // Очищение списка просмотренных историй
    await _prefs.remove('viewed_stories');

    // Принудительный сброс статуса для всех историй
    for (var i = 0; i < stories.length; i++) {
      stories[i] = stories[i].copyWith(isViewed: false);
    }
  }

  // Метод для добавления новой истории через Firebase
  Future<bool> addNewStory({
    required String title,
    required List<String> imageUrls,
    required List<String> captions,
    required String category,
    required String previewImageUrl,
  }) async {
    try {
      // Создаём запись в Firestore
      final docRef = await _firestore.collection('stories').add({
        'title': title,
        'imageUrls': imageUrls,
        'captions': captions,
        'category': category,
        'previewImageUrl': previewImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'order': stories.length, // для сортировки
      });

      // Добавляем новую историю в локальный список
      stories.add(Story(
        id: docRef.id,
        title: title,
        imageUrls: imageUrls,
        captions: captions,
        category: category,
        previewImageUrl: previewImageUrl,
        isViewed: false,
      ));

      return true;
    } catch (e) {
      debugPrint('Error adding new story: $e');
      return false;
    }
  }

  // Метод для обновления истории
  Future<bool> updateStory(Story updatedStory) async {
    try {
      await _firestore.collection('stories').doc(updatedStory.id).update({
        'title': updatedStory.title,
        'imageUrls': updatedStory.imageUrls,
        'captions': updatedStory.captions,
        'category': updatedStory.category,
        'previewImageUrl': updatedStory.previewImageUrl,
      });

      // Обновляем локальный список
      final index = stories.indexWhere((s) => s.id == updatedStory.id);
      if (index != -1) {
        stories[index] = updatedStory;
      }

      return true;
    } catch (e) {
      debugPrint('Error updating story: $e');
      return false;
    }
  }

  // Метод для удаления истории
  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();

      // Удаляем из локального списка
      stories.removeWhere((s) => s.id == storyId);

      return true;
    } catch (e) {
      debugPrint('Error deleting story: $e');
      return false;
    }
  }
}