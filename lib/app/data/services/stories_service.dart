import 'package:marinette/app/data/models/story.dart';

class StoriesService {
  static Future<List<Story>> getStories() async {
    return [
      Story(
        id: '1',
        title: 'Літній макіяж',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg', // Використовуємо тимчасові фото
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
        ],
        category: 'makeup',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
      Story(
        id: '2',
        title: 'Догляд за шкірою',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
          '',
        ],
        category: 'skincare',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
      Story(
        id: '3',
        title: 'Зачіски',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
        ],
        category: 'hair',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
      Story(
        id: '4',
        title: 'Манікюр',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
        ],
        category: 'nails',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
      Story(
        id: '5',
        title: 'Тренди сезону',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
        ],
        category: 'trends',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
      Story(
        id: '6',
        title: 'SPA вдома',
        imageUrls: [
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
          'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
        ],
        captions: [
          '',
          '',
        ],
        category: 'spa',
        previewImageUrl:
            'https://marketplace.canva.com/EAGQjy-E-_c/1/0/900w/canva-gold-and-beige-elegant-new-year-instagram-story-7GZkoAvBtsw.jpg',
      ),
    ];
  }
}
