import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ResultSaverService extends GetxService {
  static const String resultsFolderName = 'analysis_results';

  Future<ResultSaverService> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/$resultsFolderName');

      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }
      debugPrint('ResultSaverService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ResultSaverService: $e');
    }
    return this;
  }

  Future<String> saveResult({
    required String imagePath,
    required FaceAnalysisResult result,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/$resultsFolderName');

      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final resultPath = '${resultsDir.path}/result_$timestamp';

      // Копіюємо фото
      final File imageFile = File(imagePath);
      final String newImagePath = '$resultPath.jpg';
      await imageFile.copy(newImagePath);

      // Зберігаємо результати аналізу
      final resultData = {
        'imagePath': newImagePath,
        'faceShape': result.faceShape,
        'colorType': result.colorType,
        'makeupRecommendations': result.makeupRecommendations,
        'hairstyleRecommendations': result.hairstyleRecommendations,
        'skincareRecommendations': result.skincareRecommendations,
        'timestamp': timestamp,
      };

      final File resultFile = File('$resultPath.json');
      await resultFile.writeAsString(json.encode(resultData));

      debugPrint('Result saved successfully: $newImagePath');
      return newImagePath;
    } catch (e) {
      debugPrint('Error saving result: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllResults() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/$resultsFolderName');

      if (!await resultsDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await resultsDir
          .list()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      List<Map<String, dynamic>> results = [];

      for (var file in files) {
        try {
          final content = await File(file.path).readAsString();
          final data = json.decode(content) as Map<String, dynamic>;

          // Перевіряємо, чи існує зображення
          final imageFile = File(data['imagePath'] as String);
          if (await imageFile.exists()) {
            results.add(data);
          } else {
            // Якщо зображення відсутнє, видаляємо JSON файл
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error reading result file: $e');
          continue;
        }
      }

      // Сортуємо за часом (найновіші спочатку)
      results.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return results;
    } catch (e) {
      debugPrint('Error getting results: $e');
      return [];
    }
  }

  Future<void> deleteResult(String imagePath) async {
    try {
      // Видаляємо фото
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Видаляємо JSON з результатами
      final jsonPath = imagePath.replaceAll('.jpg', '.json');
      final File resultFile = File(jsonPath);
      if (await resultFile.exists()) {
        await resultFile.delete();
      }

      debugPrint('Result deleted successfully: $imagePath');
    } catch (e) {
      debugPrint('Error deleting result: $e');
      rethrow;
    }
  }
}
