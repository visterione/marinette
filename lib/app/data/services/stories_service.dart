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

      // Завантажуємо сторіз з Firestore замість хардкоду
      final storiesSnapshot = await _firestore.collection('stories')
          .orderBy('order') // якщо є поле для сортування
          .get();

      List<Story> loadedStories = [];

      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();

        try {
          // Отримуємо URL-адреси зображень
          List<String> imageUrls = [];

          // Перевіряємо, чи вже є мігровані URL-адреси
          if (data['migrated'] == true) {
            imageUrls = List<String>.from(data['imageUrls']);
          } else {
            // Використовуємо URL-адреси з бази даних
            imageUrls = List<String>.from(data['imageUrls']);
          }

          // Отримуємо URL превью
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

      // Якщо немає даних у Firestore, використовуємо демо-дані
      if (loadedStories.isEmpty) {
        loadedStories = _getDemoStories(viewedStories);
      }

      stories.value = loadedStories;

      _startBackgroundPreloading();
      debugPrint('Stories loaded successfully: ${stories.length} stories');
    } catch (e) {
      debugPrint('Error loading stories: $e');
      // Використовуємо демо-дані у випадку помилки
      final viewedStories = _prefs.getStringList(_viewedStoriesKey) ?? [];
      stories.value = _getDemoStories(viewedStories);
    }
  }

  // Допоміжний метод для отримання демо-даних
  List<Story> _getDemoStories(List<String> viewedStories) {
    return [
      Story(
        id: '1',
        title: 'stories_A',
        imageUrls: [
          'https://drive.google.com/uc?id=1K4LWzw4H3MfkLYms2EhoYz1J7tyJapG6',
          'https://drive.google.com/uc?id=16ANCQ5oo63v-3wprTjuXoeTwUbn0KaOo',
          'https://drive.google.com/uc?id=1GVvir2S8XvUxJThJyPELZ56LKZ4-0Y36',
          'https://drive.google.com/uc?id=1NtNHKVf8jTXrfAsyiNF229m_ujDMNVXj',
          'https://drive.google.com/uc?id=1sarEtlwlNGhszq6OMgpHRfMI2-0RNoSk',
        ],
        captions: ['', '', '', '', ''],
        category: 'makeup',
        previewImageUrl: 'https://drive.google.com/uc?id=1Cr4i_NMu_nB94LPTA5tdq_w8xou63FOj',
        isViewed: viewedStories.contains('1'),
      ),
      Story(
        id: '2',
        title: 'stories_B',
        imageUrls: [
          'https://drive.google.com/uc?id=1eOr1whjLVUDoTPOU80Ur0p34MjLuUsdr',
          'https://drive.google.com/uc?id=1fg53Y7g1KCy74LfwjxOCTLAIeDQwn9xj',
          'https://drive.google.com/uc?id=1ItJ2nO872YBPH75r2wvqup6puwcCcu90',
        ],
        captions: ['', '', ''],
        category: 'skincare',
        previewImageUrl: 'https://drive.google.com/uc?id=1XV2oRMsorxgjTsykz1CxJZmcX6-QYPhd',
        isViewed: viewedStories.contains('2'),
      ),
    ];
  }

  @visibleForTesting
  bool isTestMode = false;

  void _startBackgroundPreloading() {
    // В тестовому режимі не виконуємо реальне передзавантаження
    if (isTestMode) {
      return;
    }

    for (var story in stories) {
      preloadSingleImage(story.previewImageUrl.tr, priority: true);
    }

    for (var story in stories) {
      for (var imageUrl in story.imageUrls) {
        preloadSingleImage(imageUrl.tr, priority: false);
      }
    }
  }

  Future<void> preloadSingleImage(String imageUrl, {bool priority = false}) async {
    // Якщо це тестове середовище, одразу позначаємо як завантажене
    if (isTestMode) {
      preloadedImages[imageUrl] = true;
      return;
    }

    // Решта існуючої логіки
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
    // Очищення списку переглянутих історій
    await _prefs.remove('viewed_stories');

    // Примусове скидання статусу для всіх історій
    for (var i = 0; i < stories.length; i++) {
      stories[i] = stories[i].copyWith(isViewed: false);
    }
  }

  // Метод для додавання нової сторіз через Firebase
  Future<bool> addNewStory({
    required String title,
    required List<String> imageUrls,
    required List<String> captions,
    required String category,
    required String previewImageUrl,
  }) async {
    try {
      // Створюємо запис в Firestore
      final docRef = await _firestore.collection('stories').add({
        'title': title,
        'imageUrls': imageUrls,
        'captions': captions,
        'category': category,
        'previewImageUrl': previewImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'order': stories.length, // для сортування
      });

      // Додаємо нову сторіз в локальний список
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

  // Метод для оновлення історії
  Future<bool> updateStory(Story updatedStory) async {
    try {
      await _firestore.collection('stories').doc(updatedStory.id).update({
        'title': updatedStory.title,
        'imageUrls': updatedStory.imageUrls,
        'captions': updatedStory.captions,
        'category': updatedStory.category,
        'previewImageUrl': updatedStory.previewImageUrl,
      });

      // Оновлюємо локальний список
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

  // Метод для видалення сторіз
  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();

      // Видаляємо з локального списку
      stories.removeWhere((s) => s.id == storyId);

      return true;
    } catch (e) {
      debugPrint('Error deleting story: $e');
      return false;
    }
  }
}