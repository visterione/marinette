import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class StoriesService extends GetxService {
  final RxList<Story> stories = <Story>[].obs;
  static const String _viewedStoriesKey = 'viewed_stories';
  late SharedPreferences _prefs;
  final RxMap<String, bool> preloadedImages = <String, bool>{}.obs;
  final RxInt _activePreloads = 0.obs;
  static const int maxConcurrentPreloads = 3;

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
    _prefs = await SharedPreferences.getInstance();
    await loadStories();
    ever(Get.find<LocalizationService>().locale, (_) => loadStories());
    return this;
  }

  Future<void> loadStories() async {
    try {
      final viewedStories = _prefs.getStringList(_viewedStoriesKey) ?? [];
      debugPrint('Loading stories. Viewed stories: $viewedStories');

      stories.value = [
        Story(
          id: '1',
          title: 'stories_A',
          imageUrls: [
            'https://drive.google.com/uc?id=1K4LWzw4H3MfkLYms2EhoYz1J7tyJapG6',
            'https://drive.google.com/uc?id=16ANCQ5oo63v-3wprTjuXoeTwUbn0KaOo',
            'https://drive.google.com/uc?id=1GVvir2S8XvUxJThJyPELZ56LKZ4-0Y36',
            'https://drive.google.com/uc?id=1NtNHKVf8jTXrfAsyiNF229m_ujDMNVXj',
            'https://drive.google.com/uc?id=1sarEtlwlNGhszq6OMgpHRfMI2-0RNoSk',
            'https://drive.google.com/uc?id=11v1nW9EH-SygUUsP4v5wFpjmBW96PM5h',
            'https://drive.google.com/uc?id=1zvfeWLU69oSpDrk_nVc4YhG1E-LsUfaf',
            'https://drive.google.com/uc?id=1p4XZ3x4wUnA9aX4OomiBz-4cq5i7Haff',
            'https://drive.google.com/uc?id=1aYhNLipXasq5Q83E8Q-l9iBFqxDa9b0F',
          ],
          captions: ['', '', '', '', '', '', '', '', ''],
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
            'https://drive.google.com/uc?id=113jeDmcQvvqXKI_GJoGW_0Bpy9FCEswm',
            'https://drive.google.com/uc?id=1Y5aUfK_BAg127Bi_iIHqVZqHdZgDcgGN',
            'https://drive.google.com/uc?id=1oQCXB0fEBHNrsvLNuv_GZzIFIHTvOLoG',
            'https://drive.google.com/uc?id=1bpyEuZgo3-_lV9UvsmejQmPpDvt4BLR3',
          ],
          captions: ['', '', '', '', '', '', ''],
          category: 'skincare',
          previewImageUrl: 'https://drive.google.com/uc?id=1XV2oRMsorxgjTsykz1CxJZmcX6-QYPhd',
          isViewed: viewedStories.contains('2'),
        ),
        Story(
          id: '3',
          title: 'stories_C',
          imageUrls: [
            'https://drive.google.com/uc?id=15eZGl9T7TMdrKr35FUNrl35v90n8Chsk',
            'https://drive.google.com/uc?id=1tcwr87ci6joAl4hR0XgJGQPcTg6tF6oI',
            'https://drive.google.com/uc?id=14tDqz8TQLDRiLcU8xbca4sjwlB67r7nR',
            'https://drive.google.com/uc?id=1E_lGSDjo4OxXGHyR_U6ij3wURVm1lOK8',
            'https://drive.google.com/uc?id=1MEYN981lNLbbbGxgHthdOj055VxYeNnn',
          ],
          captions: ['', '', '', '', ''],
          category: 'hair',
          previewImageUrl: 'https://drive.google.com/uc?id=1jGbzmbRuOxBIJSN2PjzJNJIFnwA-C-o6',
          isViewed: viewedStories.contains('3'),
        ),
        Story(
          id: '4',
          title: 'stories_D',
          imageUrls: [
            'https://drive.google.com/uc?id=1rYQQ6ZCON7d9HDnKGYypK4Xb5D3BRDZ-',
            'https://drive.google.com/uc?id=1r63d690Ita1lA3VGKatRx7K7c8oKGFod',
            'https://drive.google.com/uc?id=1AbR7HlefY4oBxeQRJOnXZmUuTGZT8NEH',
            'https://drive.google.com/uc?id=1WidBY1lxIW7tlhTsNdyrgTk6t8crAT8Y',
            'https://drive.google.com/uc?id=14wtcNDHvQSUz7I7nZ2G3oGBMlofL9gnA',
            'https://drive.google.com/uc?id=1cJrYoO8ReCjIoncNM2XDEGlvb5ML3jU9',
          ],
          captions: ['', '', '', '', '', ''],
          category: 'nails',
          previewImageUrl: 'https://drive.google.com/uc?id=1iYkaYGjWIE4zZHLAOXkrPtxmurfYa7nW',
          isViewed: viewedStories.contains('4'),
        ),
        Story(
          id: '5',
          title: 'stories_E',
          imageUrls: [
            'https://drive.google.com/uc?id=1S7mK2YqVp4Q7BsyoiUv4dX0dbos5bxgn',
            'https://drive.google.com/uc?id=1YZoZGwAEfHnLMSlFSCGWW-b4-KFZPou2',
            'https://drive.google.com/uc?id=1e45DqTUIrq3axzF61-43wHIyhof5rffz',
            'https://drive.google.com/uc?id=1zWnex1Vd4BeIVqGIzkSTnPy70gh6SJWO',
            'https://drive.google.com/uc?id=1mbPap6fIpn_txF_dxi665Kyt6_EsnGGm',
            'https://drive.google.com/uc?id=1A4VUxGD9Kq8r33W5SgL_6pF74995FZ4O',
            'https://drive.google.com/uc?id=1i3m_meTSDPDeCO68fQfPo0DJ0Rrt8hUU',
            'https://drive.google.com/uc?id=1DZQ34sL8ic0bo6_riElSU8P-o5QRxlvZ',
            'https://drive.google.com/uc?id=11IeEhdQIHUch2ArpGYMLvdFa5IC3c8xN',
          ],
          captions: ['', '', '', '', '', '', '', '', ''],
          category: 'nails',
          previewImageUrl: 'https://drive.google.com/uc?id=13mXrn4EvKncG006I4CuzvvGpD5CmXrPV',
          isViewed: viewedStories.contains('5'),
        ),
      ];

      _startBackgroundPreloading();
      debugPrint('Stories loaded successfully: ${stories.length} stories');
    } catch (e) {
      debugPrint('Error loading stories: $e');
      stories.value = [];
    }
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
    await _prefs?.remove('viewed_stories');

    // Примусове скидання статусу для всіх історій
    for (var story in stories) {
      story.isViewed = false;
    }
  }
}