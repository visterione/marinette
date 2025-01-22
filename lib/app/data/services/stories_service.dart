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
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg', // Використовуємо тимчасові фото
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Трендовий літній мейк',
          'Яскраві та свіжі кольори',
        ],
        category: 'makeup',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
      Story(
        id: '2',
        title: 'Догляд за шкірою',
        imageUrls: [
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Ранковий догляд',
          'Вечірні процедури',
          'Маски та пілінги',
        ],
        category: 'skincare',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
      Story(
        id: '3',
        title: 'Зачіски',
        imageUrls: [
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Швидкі укладки',
          'Трендові зачіски',
        ],
        category: 'hair',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
      Story(
        id: '4',
        title: 'Манікюр',
        imageUrls: [
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Літні дизайни',
          'Трендові кольори',
        ],
        category: 'nails',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
      Story(
        id: '5',
        title: 'Тренди сезону',
        imageUrls: [
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Головні тренди',
          'Нові техніки',
        ],
        category: 'trends',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
      Story(
        id: '6',
        title: 'SPA вдома',
        imageUrls: [
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
          'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
        ],
        captions: [
          'Домашні процедури',
          'Розслаблюючі ритуали',
        ],
        category: 'spa',
        previewImageUrl:
            'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
      ),
    ];
  }
}
