// lib/app/data/services/stories_service.dart
// Updated version with Firebase Storage support and story visibility features

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

  // Геттер, который возвращает только видимые истории
  List<Story> get visibleStories => stories.where((story) => story.isVisible).toList();

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

      // Fix for the locale getter error
      // Instead of directly accessing the locale property, we'll set up a manual event listener
      try {
        // Register a callback for when the app is resumed
        // This ensures stories are refreshed when the app comes back to foreground
        SystemChannels.lifecycle.setMessageHandler((msg) {
          if (msg == AppLifecycleState.resumed.toString()) {
            loadStories();
          }
          return Future.value(null);
        });

        // Additionally, we can periodically refresh stories
        // This is a simple workaround until we can properly listen to locale changes
        Timer.periodic(const Duration(minutes: 30), (_) {
          loadStories();
        });

        debugPrint('Set up alternative refresh mechanisms for stories');
      } catch (e) {
        debugPrint('Error setting up story refresh mechanisms: $e');
      }

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

      // Load stories from Firestore
      final storiesSnapshot = await _firestore.collection('stories')
          .orderBy('order') // if sorting field exists
          .get();

      List<Story> loadedStories = [];

      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();

        try {
          // Get image URLs
          List<String> imageUrls = [];

          // Check if there are migrated URLs
          if (data['migrated'] == true) {
            imageUrls = List<String>.from(data['imageUrls']);
          } else {
            // Use URLs from the database
            imageUrls = List<String>.from(data['imageUrls']);
          }

          // Get preview URL
          String previewImageUrl = data['previewImageUrl'] ?? '';

          loadedStories.add(Story(
            id: doc.id,
            title: data['title'] ?? '',
            imageUrls: imageUrls,
            captions: List<String>.from(data['captions'] ?? []),
            category: data['category'] ?? '',
            previewImageUrl: previewImageUrl,
            isViewed: viewedStories.contains(doc.id),
            // Добавляем поле видимости, по умолчанию true
            isVisible: data['isVisible'] ?? true,
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
      stories.value = []; // Return empty list in case of error
    }
  }

  @visibleForTesting
  bool isTestMode = false;

  void _startBackgroundPreloading() {
    // Don't perform actual preloading in test mode
    if (isTestMode) {
      return;
    }

    // Preload preview images
    for (var story in stories) {
      // Check for empty URL or invalid URL
      // Note: Removed the .tr calls since image URLs are not translation keys
      if (story.previewImageUrl.isNotEmpty && Uri.tryParse(story.previewImageUrl)?.hasAuthority == true) {
        preloadSingleImage(story.previewImageUrl, priority: true);
      }
    }

    // Preload slide images
    for (var story in stories) {
      for (var imageUrl in story.imageUrls) {
        // Check for empty URL or invalid URL
        // Note: Removed the .tr calls since image URLs are not translation keys
        if (imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAuthority == true) {
          preloadSingleImage(imageUrl, priority: false);
        }
      }
    }
  }

  Future<void> preloadSingleImage(String imageUrl, {bool priority = false}) async {
    // If in test environment, mark as loaded immediately
    if (isTestMode) {
      preloadedImages[imageUrl] = true;
      return;
    }

    // Check for empty URL or invalid URL
    if (imageUrl.isEmpty || !Uri.tryParse(imageUrl)!.hasAuthority) {
      // Mark as "loaded" to avoid repeated loading attempts
      preloadedImages[imageUrl] = true;
      debugPrint('Skipping preload for empty or invalid URL: $imageUrl');
      return;
    }

    // Rest of loading logic
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
    // Note: Removed the .tr calls since image URLs are not translation keys
    final previewLoaded = preloadedImages[story.previewImageUrl] ?? false;
    final firstImageLoaded = preloadedImages[story.imageUrls.first] ?? false;
    return previewLoaded && firstImageLoaded;
  }

  bool isImagePreloaded(String imageUrl) {
    // Note: Removed the .tr call since image URLs are not translation keys
    return preloadedImages[imageUrl] ?? false;
  }

  Future<void> preloadNextStoryImages(int currentStoryIndex) async {
    final visibleStoriesList = visibleStories;

    if (currentStoryIndex >= visibleStoriesList.length - 1) return;

    final nextStory = visibleStoriesList[currentStoryIndex + 1];
    await preloadSingleImage(nextStory.previewImageUrl, priority: true);
    for (var imageUrl in nextStory.imageUrls) {
      await preloadSingleImage(imageUrl, priority: true);
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
    // Clear list of viewed stories
    await _prefs.remove('viewed_stories');

    // Force reset status for all stories
    for (var i = 0; i < stories.length; i++) {
      stories[i] = stories[i].copyWith(isViewed: false);
    }
  }

  // Method for adding a new story via Firebase
  Future<bool> addNewStory({
    required String title,
    required List<String> imageUrls,
    required List<String> captions,
    required String category,
    required String previewImageUrl,
    bool isVisible = true, // Добавляем параметр видимости
  }) async {
    try {
      // Create entry in Firestore
      final docRef = await _firestore.collection('stories').add({
        'title': title,
        'imageUrls': imageUrls,
        'captions': captions,
        'category': category,
        'previewImageUrl': previewImageUrl,
        'isVisible': isVisible, // Сохраняем статус видимости
        'createdAt': FieldValue.serverTimestamp(),
        'order': stories.length, // for sorting
      });

      // Add new story to local list
      stories.add(Story(
        id: docRef.id,
        title: title,
        imageUrls: imageUrls,
        captions: captions,
        category: category,
        previewImageUrl: previewImageUrl,
        isViewed: false,
        isVisible: isVisible, // Устанавливаем статус видимости в модели
      ));

      return true;
    } catch (e) {
      debugPrint('Error adding new story: $e');
      return false;
    }
  }

  // Method for updating a story
  Future<bool> updateStory(Story updatedStory) async {
    try {
      await _firestore.collection('stories').doc(updatedStory.id).update({
        'title': updatedStory.title,
        'imageUrls': updatedStory.imageUrls,
        'captions': updatedStory.captions,
        'category': updatedStory.category,
        'previewImageUrl': updatedStory.previewImageUrl,
        'isVisible': updatedStory.isVisible, // Обновляем статус видимости
      });

      // Update local list
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

  // Method for deleting a story
  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();

      // Remove from local list
      stories.removeWhere((s) => s.id == storyId);

      return true;
    } catch (e) {
      debugPrint('Error deleting story: $e');
      return false;
    }
  }

  // Метод для переключения видимости истории
  Future<bool> toggleStoryVisibility(String storyId) async {
    try {
      // Находим историю по ID
      final index = stories.indexWhere((story) => story.id == storyId);
      if (index == -1) return false;

      // Получаем текущий статус видимости и инвертируем его
      final story = stories[index];
      final newVisibility = !story.isVisible;

      // Обновляем статус видимости в Firestore
      await _firestore.collection('stories').doc(storyId).update({
        'isVisible': newVisibility,
      });

      // Обновляем локальную модель
      final updatedStory = story.copyWith(isVisible: newVisibility);
      stories[index] = updatedStory;

      debugPrint('Story visibility updated: $storyId, isVisible: $newVisibility');
      return true;
    } catch (e) {
      debugPrint('Error toggling story visibility: $e');
      return false;
    }
  }
}