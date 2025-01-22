// beauty_hub_service.dart
import 'package:marinette/app/data/models/article.dart';

class BeautyHubService {
  static Future<List<Article>> getArticles() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockArticles;
  }

  static Future<List<Article>> getLifehacks() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockLifehacks;
  }

  static Future<List<Article>> getGuides() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockGuides;
  }
}

final _mockArticles = [
  Article(
    id: '1',
    titleKey: 'article_colortype_title',
    descriptionKey: 'article_colortype_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'colortype_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Article(
    id: '2',
    titleKey: 'article_face_shape_title',
    descriptionKey: 'article_face_shape_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'face_shape_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Article(
    id: '3',
    titleKey: 'article_makeup_trends_title',
    descriptionKey: 'article_makeup_trends_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'makeup_trends_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Article(
    id: '4',
    titleKey: 'article_skincare_seasons_title',
    descriptionKey: 'article_skincare_seasons_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'skincare_seasons_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 9)),
  ),
];

final _mockLifehacks = [
  Article(
    id: 'l1',
    titleKey: 'lifehack_eyebrows_title',
    descriptionKey: 'lifehack_eyebrows_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'eyebrows_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Article(
    id: 'l2',
    titleKey: 'lifehack_makeup_lasting_title',
    descriptionKey: 'lifehack_makeup_lasting_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'makeup_lasting_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Article(
    id: 'l3',
    titleKey: 'lifehack_dry_shampoo_title',
    descriptionKey: 'lifehack_dry_shampoo_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'dry_shampoo_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  Article(
    id: 'l4',
    titleKey: 'lifehack_nails_title',
    descriptionKey: 'lifehack_nails_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'nails_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
];

final _mockGuides = [
  Article(
    id: 'g1',
    titleKey: 'guide_face_shape_title',
    descriptionKey: 'guide_face_shape_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'face_shape_guide_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Article(
    id: 'g2',
    titleKey: 'guide_makeup_event_title',
    descriptionKey: 'guide_makeup_event_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'makeup_event_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Article(
    id: 'g3',
    titleKey: 'guide_skincare_basics_title',
    descriptionKey: 'guide_skincare_basics_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'skincare_basics_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  Article(
    id: 'g4',
    titleKey: 'guide_wardrobe_colortype_title',
    descriptionKey: 'guide_wardrobe_colortype_desc',
    imageUrl:
        'https://naturalskincare.com/wp-content/uploads/2020/11/clean-organic-customer-type-2-768x512.jpg',
    contentKey: 'wardrobe_colortype_preview',
    publishedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];
