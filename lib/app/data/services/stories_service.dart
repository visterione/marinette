import 'package:marinette/app/data/models/story.dart';

class StoriesService {
  static Future<List<Story>> getStories() async {
    // TODO: Replace with actual data fetching logic
    // This could be from an API, local database, or mock data
    return [
      Story(
        id: '1',
        title: 'Літній макіяж',
        imageUrls: [
          'https://picsum.photos/500/800', // Використовуємо тимчасові фото
          'https://picsum.photos/500/801',
        ],
        captions: [
          'Трендовий літній мейк',
          'Яскраві та свіжі кольори',
        ],
        category: 'makeup',
        previewImageUrl: 'https://picsum.photos/200',
      ),
      Story(
        id: '2',
        title: 'Догляд за шкірою',
        imageUrls: [
          'https://picsum.photos/500/802',
          'https://picsum.photos/500/803',
          'https://picsum.photos/500/804',
        ],
        captions: [
          'Ранковий догляд',
          'Вечірні процедури',
          'Маски та пілінги',
        ],
        category: 'skincare',
        previewImageUrl: 'https://picsum.photos/201',
      ),
      Story(
        id: '3',
        title: 'Зачіски',
        imageUrls: [
          'https://picsum.photos/500/805',
          'https://picsum.photos/500/806',
        ],
        captions: [
          'Швидкі укладки',
          'Трендові зачіски',
        ],
        category: 'hair',
        previewImageUrl: 'https://picsum.photos/202',
      ),
      Story(
        id: '4',
        title: 'Манікюр',
        imageUrls: [
          'https://picsum.photos/500/807',
          'https://picsum.photos/500/808',
        ],
        captions: [
          'Літні дизайни',
          'Трендові кольори',
        ],
        category: 'nails',
        previewImageUrl: 'https://picsum.photos/203',
      ),
      Story(
        id: '5',
        title: 'Тренди сезону',
        imageUrls: [
          'https://picsum.photos/500/809',
          'https://picsum.photos/500/810',
        ],
        captions: [
          'Головні тренди',
          'Нові техніки',
        ],
        category: 'trends',
        previewImageUrl: 'https://picsum.photos/204',
      ),
      Story(
        id: '6',
        title: 'SPA вдома',
        imageUrls: [
          'https://picsum.photos/500/811',
          'https://picsum.photos/500/812',
        ],
        captions: [
          'Домашні процедури',
          'Розслаблюючі ритуали',
        ],
        category: 'spa',
        previewImageUrl: 'https://picsum.photos/205',
      ),
      Story(
        id: '7',
        title: 'Масаж обличчя',
        imageUrls: [
          'https://picsum.photos/500/813',
          'https://picsum.photos/500/814',
        ],
        captions: [
          'Техніки масажу',
          'Корисні поради',
        ],
        category: 'massage',
        previewImageUrl: 'https://picsum.photos/206',
      ),
      Story(
        id: '8',
        title: 'Брови та вії',
        imageUrls: [
          'https://picsum.photos/500/815',
          'https://picsum.photos/500/816',
        ],
        captions: [
          'Форми брів',
          'Догляд за віями',
        ],
        category: 'brows',
        previewImageUrl: 'https://picsum.photos/207',
      ),
    ];
  }
}
