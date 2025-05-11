// lib/app/data/services/beauty_hub_service.dart

import 'package:marinette/app/data/models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BeautyHubService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Метод для доступа к экземпляру Firestore
  FirebaseFirestore getFirestore() {
    return _firestore;
  }

  // Получение всех статей
  static Future<List<Article>> getArticles() async {
    try {
      // Обновленный запрос для получения только видимых статей типа 'article'
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'article')
          .where('isVisible', isEqualTo: true) // Только видимые статьи
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

  // Метод для получения всех статей для админ-панели (включая скрытые)
  static Future<List<Article>> getAllArticlesForAdmin() async {
    try {
      // Запрос для получения всех статей типа 'article' (и видимых и скрытых)
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'article')
          .get();

      // Сортировка выполняется на стороне клиента
      final articles = _processArticles(articlesSnapshot);
      articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return articles;
    } catch (e) {
      debugPrint('Error getting all articles for admin: $e');
      return []; // Возвращаем пустой список
    }
  }

  // Получение лайфхаков
  static Future<List<Article>> getLifehacks() async {
    try {
      // Обновленный запрос для получения только видимых статей типа 'lifehack'
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'lifehack')
          .where('isVisible', isEqualTo: true) // Только видимые лайфхаки
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

  // Метод для получения всех лайфхаков для админ-панели (включая скрытые)
  static Future<List<Article>> getAllLifehacksForAdmin() async {
    try {
      // Запрос для получения всех статей типа 'lifehack' (и видимых и скрытых)
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'lifehack')
          .get();

      // Сортировка выполняется на стороне клиента
      final lifehacks = _processArticles(articlesSnapshot);
      lifehacks.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return lifehacks;
    } catch (e) {
      debugPrint('Error getting all lifehacks for admin: $e');
      return []; // Возвращаем пустой список
    }
  }

  // Получение гайдов
  static Future<List<Article>> getGuides() async {
    try {
      // Обновленный запрос для получения только видимых статей типа 'guide'
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'guide')
          .where('isVisible', isEqualTo: true) // Только видимые гайды
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

  // Метод для получения всех гайдов для админ-панели (включая скрытые)
  static Future<List<Article>> getAllGuidesForAdmin() async {
    try {
      // Запрос для получения всех статей типа 'guide' (и видимых и скрытых)
      final articlesSnapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('type', isEqualTo: 'guide')
          .get();

      // Сортировка выполняется на стороне клиента
      final guides = _processArticles(articlesSnapshot);
      guides.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return guides;
    } catch (e) {
      debugPrint('Error getting all guides for admin: $e');
      return []; // Возвращаем пустой список
    }
  }

  // Обработка результатов запроса к Firestore
  static List<Article> _processArticles(QuerySnapshot snapshot) {
    List<Article> result = [];

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        // Добавляем поле isVisible в модель статьи
        result.add(Article(
          id: doc.id,
          titleKey: data['title'] ?? data['titleKey'] ?? '',
          descriptionKey: data['description'] ?? data['descriptionKey'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          contentKey: data['content'] ?? data['contentKey'] ?? '',
          publishedAt: data['publishedAt'] != null
              ? (data['publishedAt'] is Timestamp
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['publishedAt']))
              : DateTime.now(),
          authorNameKey: data['authorName'] ?? data['authorNameKey'] ?? '',
          authorAvatarUrl: data['authorAvatarUrl'] ?? '',
          isVisible: data['isVisible'] ?? true, // Добавляем поле видимости
        ));
      } catch (e) {
        debugPrint('Error processing article document: $e');
      }
    }

    return result;
  }

  // Добавление новой статьи
  Future<bool> addArticle({
    required String title,
    required String description,
    required String imageUrl,
    required String content,
    required String authorName,
    required String authorAvatarUrl,
    required String type,
    bool isVisible = true, // Добавляем параметр видимости
  }) async {
    try {
      await _firestore.collection('articles').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'content': content,
        'publishedAt': FieldValue.serverTimestamp(),
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'type': type, // Обязательно указываем тип статьи
        'createdAt': FieldValue.serverTimestamp(),
        'isVisible': isVisible, // Сохраняем видимость
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
        titleKey: data['title'] ?? data['titleKey'] ?? '',
        descriptionKey: data['description'] ?? data['descriptionKey'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        contentKey: data['content'] ?? data['contentKey'] ?? '',
        publishedAt: data['publishedAt'] != null
            ? (data['publishedAt'] is Timestamp
            ? (data['publishedAt'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(data['publishedAt']))
            : DateTime.now(),
        authorNameKey: data['authorName'] ?? data['authorNameKey'] ?? '',
        authorAvatarUrl: data['authorAvatarUrl'] ?? '',
        isVisible: data['isVisible'] ?? true, // Добавляем поле видимости
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
          .where('isVisible', isEqualTo: true) // Только видимые статьи
          .get();

      List<Article> allArticles = _processArticles(articlesSnapshot);

      // Локальный поиск по прямым значениям, а не ключам
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

  // Изменение видимости статьи
  Future<bool> toggleArticleVisibility(String articleId, bool isVisible) async {
    try {
      await _firestore.collection('articles').doc(articleId).update({
        'isVisible': isVisible,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling article visibility: $e');
      return false;
    }
  }
}