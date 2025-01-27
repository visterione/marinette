import 'package:get/get.dart';
import 'package:marinette/app/data/models/story.dart';
import 'package:marinette/app/data/services/localization_service.dart';

class StoriesService extends GetxController {
  final RxList<Story> stories = <Story>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStories();
    ever(Get.find<LocalizationService>().locale, (_) => loadStories());
  }

  void loadStories() {
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
      ),
    ];
  }
}