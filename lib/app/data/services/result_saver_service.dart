import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ResultSaverService extends GetxService {
  static const String resultsFolderName = 'analysis_results';
  final RxList<Map<String, dynamic>> _results = <Map<String, dynamic>>[].obs;
  bool _isInitialized = false;
  late final UserPreferencesService _userPrefs;

  Future<ResultSaverService> init() async {
    try {
      if (_isInitialized) return this;

      _userPrefs = Get.find<UserPreferencesService>();
      final userId = _userPrefs.getCurrentUserId();

      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/$resultsFolderName/$userId');

      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }

      await _loadExistingResults();

      _isInitialized = true;
      debugPrint('ResultSaverService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ResultSaverService: $e');
    }
    return this;
  }

  // Замінюємо getter на звичайний асинхронний метод
  Future<String> _getUserResultsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final userId = _userPrefs.getCurrentUserId();
    return '${appDir.path}/$resultsFolderName/$userId';
  }

  Future<void> _loadExistingResults() async {
    try {
      final resultsDir = Directory(await _getUserResultsPath());

      if (!await resultsDir.exists()) return;

      final List<FileSystemEntity> files = await resultsDir
          .list()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      final List<Map<String, dynamic>> loadedResults = [];

      for (var file in files) {
        try {
          final content = await File(file.path).readAsString();
          final data = json.decode(content) as Map<String, dynamic>;

          final imageFile = File(data['imagePath'] as String);
          if (await imageFile.exists()) {
            loadedResults.add(data);
          } else {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error reading result file: $e');
          continue;
        }
      }

      loadedResults.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      _results.value = loadedResults;
    } catch (e) {
      debugPrint('Error loading existing results: $e');
    }
  }

  Future<String> saveResult({
    required String imagePath,
    required FaceAnalysisResult result,
  }) async {
    try {
      final resultsDir = Directory(await _getUserResultsPath());

      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final resultPath = '${resultsDir.path}/result_$timestamp';

      final File imageFile = File(imagePath);
      final String newImagePath = '$resultPath.jpg';
      await imageFile.copy(newImagePath);

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

      _results.insert(0, resultData);

      debugPrint('Result saved successfully: $newImagePath');
      return newImagePath;
    } catch (e) {
      debugPrint('Error saving result: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllResults() async {
    if (!_isInitialized) {
      await init();
    }

    await _loadExistingResults();
    return _results;
  }

  Future<void> deleteResult(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      final jsonPath = imagePath.replaceAll('.jpg', '.json');
      final resultFile = File(jsonPath);
      if (await resultFile.exists()) {
        await resultFile.delete();
      }

      _results.removeWhere((result) => result['imagePath'] == imagePath);

      debugPrint('Result deleted successfully: $imagePath');
    } catch (e) {
      debugPrint('Error deleting result: $e');
      rethrow;
    }
  }

  Future<void> clearAllResults() async {
    try {
      final resultsDir = Directory(await _getUserResultsPath());
      if (await resultsDir.exists()) {
        await resultsDir.delete(recursive: true);
      }
      _results.clear();
      debugPrint('All results cleared successfully');
    } catch (e) {
      debugPrint('Error clearing results: $e');
      rethrow;
    }
  }
}
