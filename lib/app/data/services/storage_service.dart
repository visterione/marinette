// lib/app/data/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class StorageService extends GetxService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String ARTICLES_PATH = 'articles';
  static const String STORIES_PATH = 'stories';
  static const String PROFILE_PATH = 'profile_images';

  // Кешування URL-адрес для запобігання зайвих запитів
  final Map<String, String> _urlCache = {};

  Future<StorageService> init() async {
    debugPrint('StorageService initialized');
    return this;
  }

  // Метод для перевірки, чи існує файл у Firebase Storage
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Отримання URL для зображення статті
  Future<String> getArticleImageUrl(String articleId) async {
    final String cacheKey = '$ARTICLES_PATH/$articleId';

    // Перевіряємо кеш спочатку
    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey]!;
    }

    try {
      final ref = _storage.ref().child(cacheKey);
      final url = await ref.getDownloadURL();

      // Зберігаємо URL в кеші
      _urlCache[cacheKey] = url;

      return url;
    } catch (e) {
      debugPrint('Error getting article image: $e');
      rethrow;
    }
  }

  // Отримання списку URL для сторіз
  Future<List<String>> getStoryImages(String storyId) async {
    try {
      final result = await _storage.ref().child('$STORIES_PATH/$storyId').listAll();

      List<String> urls = [];
      for (var item in result.items) {
        final String cacheKey = item.fullPath;
        String url;

        if (_urlCache.containsKey(cacheKey)) {
          url = _urlCache[cacheKey]!;
        } else {
          url = await item.getDownloadURL();
          _urlCache[cacheKey] = url;
        }

        urls.add(url);
      }

      // Сортуємо URL-адреси за іменем файлу (наприклад, 01.jpg, 02.jpg, ...)
      urls.sort();

      return urls;
    } catch (e) {
      debugPrint('Error getting story images: $e');
      return [];
    }
  }

  // Отримання URL зображення профілю користувача
  Future<String?> getProfileImageUrl(String userId) async {
    final String cacheKey = '$PROFILE_PATH/$userId';

    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey];
    }

    try {
      final ref = _storage.ref().child(cacheKey);
      final url = await ref.getDownloadURL();

      _urlCache[cacheKey] = url;
      return url;
    } catch (e) {
      debugPrint('Profile image not found: $e');
      return null;
    }
  }

  // Завантаження файлу з URL у Firebase Storage
  Future<String?> uploadFromUrl(String sourceUrl, String destinationPath) async {
    try {
      // Завантажуємо файл
      final response = await http.get(Uri.parse(sourceUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // Створюємо тимчасовий файл
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Завантажуємо у Firebase Storage
      final ref = _storage.ref().child(destinationPath);
      await ref.putFile(tempFile);

      // Отримуємо URL
      final downloadUrl = await ref.getDownloadURL();

      // Кешуємо URL
      _urlCache[destinationPath] = downloadUrl;

      // Видаляємо тимчасовий файл
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading from URL: $e');
      return null;
    }
  }

  // Завантаження локального файлу в Firebase Storage
  Future<String?> uploadFile(File file, String destinationPath) async {
    try {
      final ref = _storage.ref().child(destinationPath);
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();
      _urlCache[destinationPath] = downloadUrl;

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Видалення файлу з Firebase Storage
  Future<bool> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();

      // Видаляємо з кешу
      _urlCache.remove(path);

      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Очищення кешу URL
  void clearCache() {
    _urlCache.clear();
  }

  // Отримує або створює URL зображення (для міграції)
  Future<String?> getOrUploadImage(String sourceUrl, String destinationPath) async {
    try {
      // Спочатку перевіряємо, чи файл вже існує
      final ref = _storage.ref().child(destinationPath);
      try {
        final url = await ref.getDownloadURL();
        _urlCache[destinationPath] = url;
        return url;
      } catch (e) {
        // Файл не існує, тому завантажуємо його
        return await uploadFromUrl(sourceUrl, destinationPath);
      }
    } catch (e) {
      debugPrint('Error in getOrUploadImage: $e');
      return null;
    }
  }
}