// lib/app/data/services/beauty_hub_service.dart

import 'package:marinette/app/data/models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/services/storage_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BeautyHubService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = Get.find<StorageService>();

  // Получение всех видимых статей
  static Future<List<Article>> getArticles({bool includeHidden = false}) async {
    try {
      // Создаем базовый запрос для коллекции articles
      var articlesRef = FirebaseFirestore.instance.collection('articles');

      // Создаем запрос для получения статей типа 'article'
      Query<Map<String, dynamic>> query = articlesRef.where('type', isEqualTo: 'article');

      // Если не нужно включать скрытые статьи, добавляем фильтр
      if (!includeHidden) {
        query = query.where('isHidden', isEqualTo: false);
      }

      final articlesSnapshot = await query.get();

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
  static Future<List<Article>> getLifehacks({bool includeHidden = false}) async {
    try {
      // Создаем базовый запрос для коллекции articles
      var articlesRef = FirebaseFirestore.instance.collection('articles');

      // Создаем запрос для получения статей типа 'lifehack'
      Query<Map<String, dynamic>> query = articlesRef.where('type', isEqualTo: 'lifehack');

      // Если не нужно включать скрытые статьи, добавляем фильтр
      if (!includeHidden) {
        query = query.where('isHidden', isEqualTo: false);
      }

      final articlesSnapshot = await query.get();

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
  static Future<List<Article>> getGuides({bool includeHidden = false}) async {
    try {
      // Создаем базовый запрос для коллекции articles
      var articlesRef = FirebaseFirestore.instance.collection('articles');

      // Создаем запрос для получения статей типа 'guide'
      Query<Map<String, dynamic>> query = articlesRef.where('type', isEqualTo: 'guide');

      // Если не нужно включать скрытые статьи, добавляем фильтр
      if (!includeHidden) {
        query = query.where('isHidden', isEqualTo: false);
      }

      final articlesSnapshot = await query.get();

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

        // Используем прямые значения полей, а не ключи перевода
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
          isHidden: data['isHidden'] ?? false, // Добавляем поле видимости
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
    bool isHidden = false, // Добавляем параметр видимости
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
        'isHidden': isHidden, // Добавляем поле видимости
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
        isHidden: data['isHidden'] ?? false, // Добавляем поле видимости
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

  // Переключение видимости статьи
  static Future<bool> toggleArticleVisibility(String articleId, bool currentVisibility) async {
    try {
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .update({'isHidden': !currentVisibility});
      return true;
    } catch (e) {
      debugPrint('Error toggling article visibility: $e');
      return false;
    }
  }

  // Поиск статей
  static Future<List<Article>> searchArticles(String query, {bool includeHidden = false}) async {
    try {
      // Получаем ссылку на коллекцию
      CollectionReference<Map<String, dynamic>> articlesRef =
      FirebaseFirestore.instance.collection('articles');

      // Выполняем запрос к Firestore
      QuerySnapshot<Map<String, dynamic>> articlesSnapshot;

      if (includeHidden) {
        // Если нужно включать скрытые - запрашиваем все документы
        articlesSnapshot = await articlesRef.get();
      } else {
        // Иначе только те, которые не скрыты
        articlesSnapshot = await articlesRef.where('isHidden', isEqualTo: false).get();
      }

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
}