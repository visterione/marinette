import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/localization_service.dart';

class StoriesService extends GetxService {
  final RxList<Story> stories = <Story>[].obs;
  static const String _viewedStoriesKey = 'viewed_stories';
  late SharedPreferences _prefs;

  @override
  void onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    loadStories();
    ever(Get.find<LocalizationService>().locale, (_) => loadStories());
  }

  Future<void> loadStories() async {
    try {
      final viewedStories = _prefs.getStringList(_viewedStoriesKey) ?? [];
      debugPrint('Loading stories. Viewed stories: $viewedStories');

      stories.value = [
        Story(
          id: '1',
          title: 'stories_summer_makeup',
          imageUrls: [
            'stories_summer_makeup_img_1',
            'stories_summer_makeup_img_2',
          ],
          captions: [
            'stories_summer_makeup_caption_1',
            'stories_summer_makeup_caption_2',
          ],
          category: 'makeup',
          previewImageUrl: 'stories_summer_makeup_preview',
          isViewed: viewedStories.contains('1'),
        ),
        Story(
          id: '2',
          title: 'stories_skincare',
          imageUrls: [
            'stories_skincare_img_1',
            'stories_skincare_img_2',
            'stories_skincare_img_3',
          ],
          captions: [
            'stories_skincare_caption_1',
            'stories_skincare_caption_2',
            'stories_skincare_caption_3',
          ],
          category: 'skincare',
          previewImageUrl: 'stories_skincare_preview',
          isViewed: viewedStories.contains('2'),
        ),
        Story(
          id: '3',
          title: 'stories_hairstyles',
          imageUrls: [
            'stories_hairstyles_img_1',
            'stories_hairstyles_img_2',
          ],
          captions: [
            'stories_hairstyles_caption_1',
            'stories_hairstyles_caption_2',
          ],
          category: 'hair',
          previewImageUrl: 'stories_hairstyles_preview',
          isViewed: viewedStories.contains('3'),
        ),
        Story(
          id: '4',
          title: 'stories_nails',
          imageUrls: [
            'stories_nails_img_1',
            'stories_nails_img_2',
          ],
          captions: [
            'stories_nails_caption_1',
            'stories_nails_caption_2',
          ],
          category: 'nails',
          previewImageUrl: 'stories_nails_preview',
          isViewed: viewedStories.contains('4'),
        ),
        Story(
          id: '5',
          title: 'stories_trends',
          imageUrls: [
            'stories_trends_img_1',
            'stories_trends_img_2',
          ],
          captions: [
            'stories_trends_caption_1',
            'stories_trends_caption_2',
          ],
          category: 'trends',
          previewImageUrl: 'stories_trends_preview',
          isViewed: viewedStories.contains('5'),
        ),
        Story(
          id: '6',
          title: 'stories_spa',
          imageUrls: [
            'stories_spa_img_1',
            'stories_spa_img_2',
          ],
          captions: [
            'stories_spa_caption_1',
            'stories_spa_caption_2',
          ],
          category: 'spa',
          previewImageUrl: 'stories_spa_preview',
          isViewed: viewedStories.contains('6'),
        ),
      ];

      debugPrint('Stories loaded successfully: ${stories.length} stories');
    } catch (e) {
      debugPrint('Error loading stories: $e');
      stories.value = [];
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
    try {
      debugPrint('Resetting viewed stories');
      await _prefs.remove(_viewedStoriesKey);
      await loadStories();
      debugPrint('Viewed stories reset successfully');
    } catch (e) {
      debugPrint('Error resetting viewed stories: $e');
    }
  }
}