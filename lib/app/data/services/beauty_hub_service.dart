// lib/app/data/services/beauty_hub_service.dart

import 'package:marinette/app/data/models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BeautyHubService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Получение всех статей
  static Future<List<Article>> getArticles() async {
    try {
      // Обновленный запрос без составного индекса
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'article')
          .get();

      // Сортировка выполняется на стороне клиента
      final articles = _processArticles(articlesSnapshot);
      articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return articles;
    } catch (e) {
      debugPrint('Error getting articles: $e');
      return []; // Возвращаем пустой список вместо мок-данных
    }
  }

  // Получение лайфхаков
  static Future<List<Article>> getLifehacks() async {
    try {
      // Обновленный запрос без составного индекса
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'lifehack')
          .get();

      // Сортировка выполняется на стороне клиента
      final lifehacks = _processArticles(articlesSnapshot);
      lifehacks.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return lifehacks;
    } catch (e) {
      debugPrint('Error getting lifehacks: $e');
      return []; // Возвращаем пустой список
    }
  }

  // Получение гайдов
  static Future<List<Article>> getGuides() async {
    try {
      // Обновленный запрос без составного индекса
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'guide')
          .get();

      // Сортировка выполняется на стороне клиента
      final guides = _processArticles(articlesSnapshot);
      guides.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return guides;
    } catch (e) {
      debugPrint('Error getting guides: $e');
      return []; // Возвращаем пустой список
    }
  }

  // Обработка результатов запроса к Firestore
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

  // Добавление новой статьи
  Future<bool> addArticle({
    required String titleKey,
    required String descriptionKey,
    required String imageUrl,
    required String contentKey,
    required String authorNameKey,
    required String authorAvatarUrl,
    required String type,
  }) async {
    try {
      await _firestore.collection('articles').add({
        'titleKey': titleKey,
        'descriptionKey': descriptionKey,
        'imageUrl': imageUrl,
        'contentKey': contentKey,
        'publishedAt': FieldValue.serverTimestamp(),
        'authorNameKey': authorNameKey,
        'authorAvatarUrl': authorAvatarUrl,
        'type': type, // 'article', 'lifehack', или 'guide'
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding article: $e');
      return false;
    }
  }

  // Получение статьи по ID
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

  // Обновление статьи
  Future<bool> updateArticle(String articleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('articles').doc(articleId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating article: $e');
      return false;
    }
  }

  // Удаление статьи
  Future<bool> deleteArticle(String articleId) async {
    try {
      await _firestore.collection('articles').doc(articleId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting article: $e');
      return false;
    }
  }

  // Поиск статей
  static Future<List<Article>> searchArticles(String query) async {
    try {
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .get();

      List<Article> allArticles = _processArticles(articlesSnapshot);

      // Локальный поиск
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
}