import 'package:marinette/app/data/models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BeautyHubService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Отримання усіх статей
  static Future<List<Article>> getArticles() async {
    try {
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'article')
          .orderBy('publishedAt', descending: true)
          .get();

      return _processArticles(articlesSnapshot);
    } catch (e) {
      debugPrint('Error getting articles: $e');
      return _getMockArticles();
    }
  }

  // Отримання лайфхаків
  static Future<List<Article>> getLifehacks() async {
    try {
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'lifehack')
          .orderBy('publishedAt', descending: true)
          .get();

      return _processArticles(articlesSnapshot);
    } catch (e) {
      debugPrint('Error getting lifehacks: $e');
      return _getMockLifehacks();
    }
  }

  // Отримання гайдів
  static Future<List<Article>> getGuides() async {
    try {
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'guide')
          .orderBy('publishedAt', descending: true)
          .get();

      return _processArticles(articlesSnapshot);
    } catch (e) {
      debugPrint('Error getting guides: $e');
      return _getMockGuides();
    }
  }

  // Обробка результатів запиту до Firestore
  static List<Article> _processArticles(QuerySnapshot snapshot) {
    List<Article> result = [];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        result.add(Article(
          id: doc.id,
          titleKey: data['titleKey'] ?? '',
          descriptionKey: data['descriptionKey'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          contentKey: data['contentKey'] ?? '',
          publishedAt: data['publishedAt'] != null
              ? (data['publishedAt'] is Timestamp
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['publishedAt']))
              : DateTime.now(),
          authorNameKey: data['authorNameKey'] ?? '',
          authorAvatarUrl: data['authorAvatarUrl'] ?? '',
        ));
      } catch (e) {
        debugPrint('Error processing article document: $e');
      }
    }

    return result;
  }

  // Додавання нової статті
  Future<bool> addArticle(Article article) async {
    try {
      await _firestore.collection('articles').add({
        'titleKey': article.titleKey,
        'descriptionKey': article.descriptionKey,
        'imageUrl': article.imageUrl,
        'contentKey': article.contentKey,
        'publishedAt': Timestamp.fromDate(article.publishedAt),
        'authorNameKey': article.authorNameKey,
        'authorAvatarUrl': article.authorAvatarUrl,
        'type': 'article', // Визначає тип контенту
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding article: $e');
      return false;
    }
  }

  // Отримання статті за ID
  static Future<Article?> getArticleById(String articleId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;

      return Article(
        id: docSnapshot.id,
        titleKey: data['titleKey'] ?? '',
        descriptionKey: data['descriptionKey'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        contentKey: data['contentKey'] ?? '',
        publishedAt: data['publishedAt'] != null
            ? (data['publishedAt'] is Timestamp
            ? (data['publishedAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(data['publishedAt']))
            : DateTime.now(),
        authorNameKey: data['authorNameKey'] ?? '',
        authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      );
    } catch (e) {
      debugPrint('Error getting article by ID: $e');
      return null;
    }
  }

  // Оновлення статті
  Future<bool> updateArticle(String articleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('articles').doc(articleId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating article: $e');
      return false;
    }
  }

  // Видалення статті
  Future<bool> deleteArticle(String articleId) async {
    try {
      await _firestore.collection('articles').doc(articleId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting article: $e');
      return false;
    }
  }

  // Пошук статей
  static Future<List<Article>> searchArticles(String query) async {
    try {
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .get();

      List<Article> allArticles = _processArticles(articlesSnapshot);

      // Локальний пошук
      return allArticles.where((article) =>
      article.titleKey.toLowerCase().contains(query.toLowerCase()) ||
          article.descriptionKey.toLowerCase().contains(query.toLowerCase()) ||
          article.contentKey.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      debugPrint('Error searching articles: $e');
      return [];
    }
  }

  // Мок-дані для статей
  static List<Article> _getMockArticles() {
    return [
      Article(
        id: '1',
        titleKey: 'article_1_title',
        descriptionKey: 'article_1_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1eraZBIrC9p6fbscWL7HucaUOmfbd7jgR',
        contentKey: 'article_1_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        authorNameKey: 'author1',
        authorAvatarUrl: 'author1_avatar_url',
      ),
      Article(
        id: '2',
        titleKey: 'article_2_title',
        descriptionKey: 'article_2_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1oc2dtGgPqhB3wAcUg3C-HTCGCosJDu0s',
        contentKey: 'article_2_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        authorNameKey: 'author2',
        authorAvatarUrl: 'author2_avatar_url',
      ),
      Article(
        id: '3',
        titleKey: 'article_3_title',
        descriptionKey: 'article_3_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1EowZ6D5yPVptj548Na6OQFPyvgK-Ax6a',
        contentKey: 'article_3_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        authorNameKey: 'author3',
        authorAvatarUrl: 'author3_avatar_url',
      ),
      Article(
        id: '4',
        titleKey: 'article_4_title',
        descriptionKey: 'article_4_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1wPY9ACSMinkSnWnyo2tL6yL3HZ4zG3Nr',
        contentKey: 'article_4_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 8)),
        authorNameKey: 'author4',
        authorAvatarUrl: 'author4_avatar_url',
      ),
      Article(
        id: '5',
        titleKey: 'article_5_title',
        descriptionKey: 'article_5_desc',
        imageUrl:
        'https://drive.google.com/uc?id=15UXfdCvW21krf7cY0sOpoW_hIwZ62PlO',
        contentKey: 'article_5_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 8)),
        authorNameKey: 'author5',
        authorAvatarUrl: 'author5_avatar_url',
      ),
      Article(
        id: '6',
        titleKey: 'article_6_title',
        descriptionKey: 'article_6_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1jt21ZsACrOs7mP0wLgr0kTuPNZ8NhXPK',
        contentKey: 'article_6_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 9)),
        authorNameKey: 'author6',
        authorAvatarUrl: 'author6_avatar_url',
      ),
    ];
  }

  // Мок-дані для лайфхаків
  static List<Article> _getMockLifehacks() {
    return [
      Article(
        id: 'l1',
        titleKey: 'lifehack_1_title',
        descriptionKey: 'lifehack_1_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1RtinhZ9l20_AbbtuYoyo0WFQy7gLI2jk',
        contentKey: 'lifehack_1_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        authorNameKey: 'author2',
        authorAvatarUrl: 'author2_avatar_url',
      ),
      Article(
        id: 'l2',
        titleKey: 'lifehack_2_title',
        descriptionKey: 'lifehack_2_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1tRY32Vtsa-h9TOX_qS8fkJNI2xjo3Qnk',
        contentKey: 'lifehack_2_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 4)),
        authorNameKey: 'author4',
        authorAvatarUrl: 'author4_avatar_url',
      ),
      Article(
        id: 'l3',
        titleKey: 'lifehack_3_title',
        descriptionKey: 'lifehack_3_desc',
        imageUrl:
        'https://drive.google.com/uc?id=15BXwGZygRSDWHjgC4A_tOz7mE5cFg5d4',
        contentKey: 'lifehack_3_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 6)),
        authorNameKey: 'author6',
        authorAvatarUrl: 'author6_avatar_url',
      ),
      Article(
        id: 'l4',
        titleKey: 'lifehack_4_title',
        descriptionKey: 'lifehack_4_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1geVJGcPfwYHULe71CdpcuVxUuucic-DW',
        contentKey: 'lifehack_4_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        authorNameKey: 'author1',
        authorAvatarUrl: 'author1_avatar_url',
      ),
      Article(
        id: 'l5',
        titleKey: 'lifehack_5_title',
        descriptionKey: 'lifehack_5_desc',
        imageUrl:
        'https://drive.google.com/uc?id=19UHYkoUfFXZ29rlkO-LOeJDjeE_qKa2P',
        contentKey: 'lifehack_5_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        authorNameKey: 'author3',
        authorAvatarUrl: 'author3_avatar_url',
      ),
      Article(
        id: 'l6',
        titleKey: 'lifehack_6_title',
        descriptionKey: 'lifehack_6_desc',
        imageUrl:
        'https://drive.google.com/uc?id=10r5E4eleRuI2sZof9HJc15OA8F3CAwBE',
        contentKey: 'lifehack_6_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 8)),
        authorNameKey: 'author5',
        authorAvatarUrl: 'author5_avatar_url',
      ),
    ];
  }

  // Мок-дані для гайдів
  static List<Article> _getMockGuides() {
    return [
      Article(
        id: 'g1',
        titleKey: 'guide_1_title',
        descriptionKey: 'guide_1_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1jITHgf4Zn9wT4A1pulQRL98mq4hE-Uec',
        contentKey: 'guide_1_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        authorNameKey: 'author6',
        authorAvatarUrl: 'author6_avatar_url',
      ),
      Article(
        id: 'g2',
        titleKey: 'guide_2_title',
        descriptionKey: 'guide_2_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1c0SG4iHLECtbse-moaRYP8paIJLegpwj',
        contentKey: 'guide_2_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 4)),
        authorNameKey: 'author5',
        authorAvatarUrl: 'author5_avatar_url',
      ),
      Article(
        id: 'g3',
        titleKey: 'guide_3_title',
        descriptionKey: 'guide_3_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1CK6iymUIUn5RIGQVmdd2R0GPuSpfZL04',
        contentKey: 'guide_3_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 6)),
        authorNameKey: 'author4',
        authorAvatarUrl: 'author4_avatar_url',
      ),
      Article(
        id: 'g4',
        titleKey: 'guide_4_title',
        descriptionKey: 'guide_4_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1ee1LFqw7Bx2p7_OVnKCGwpBeqn8rEfxM',
        contentKey: 'guide_4_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        authorNameKey: 'author3',
        authorAvatarUrl: 'author3_avatar_url',
      ),
      Article(
        id: 'g5',
        titleKey: 'guide_5_title',
        descriptionKey: 'guide_5_desc',
        imageUrl:
        'https://drive.google.com/uc?id=1RTwv0MrnSUf82Idk5VimRXZD8RopW2yQ',
        contentKey: 'guide_5_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 8)),
        authorNameKey: 'author2',
        authorAvatarUrl: 'author2_avatar_url',
      ),
      Article(
        id: 'g6',
        titleKey: 'guide_6_title',
        descriptionKey: 'guide_6_desc',
        imageUrl:
        'https://drive.google.com/uc?id=19KohUD2a_x3cbetrc40KXaVSd0kEIsDU',
        contentKey: 'guide_6_preview',
        publishedAt: DateTime.now().subtract(const Duration(days: 9)),
        authorNameKey: 'author1',
        authorAvatarUrl: 'author1_avatar_url',
      ),
    ];
  }
}