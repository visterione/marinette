import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/user_preferences_service.dart';
import 'package:marinette/app/data/services/firestore_analysis_service.dart';
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ResultSaverService extends GetxService {
  static const String resultsFolderName = 'analysis_results';
  final RxList<Map<String, dynamic>> _results = <Map<String, dynamic>>[].obs;
  final RxBool _isSyncing = false.obs;
  bool _isInitialized = false;
  late final UserPreferencesService _userPrefs;
  late final FirestoreAnalysisService _firestoreAnalysisService;
  late final AuthService _authService;
  String? _currentUserId;

  // Getter for syncing state
  bool get isSyncing => _isSyncing.value;

  Future<ResultSaverService> init() async {
    try {
      if (_isInitialized) return this;

      _userPrefs = Get.find<UserPreferencesService>();
      _firestoreAnalysisService = Get.find<FirestoreAnalysisService>();
      _authService = Get.find<AuthService>();

      // Сохраняем текущий идентификатор пользователя
      _currentUserId = _authService.currentUser?.uid;

      final userId = _userPrefs.getCurrentUserId();

      final appDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${appDir.path}/$resultsFolderName/$userId');

      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }

      await _loadExistingResults();

      // Auto-sync local results to Firestore if user is logged in
      if (_authService.isLoggedIn) {
        syncResultsToFirestore();
      }

      // Listen to auth state changes
      _authService.userStream.listen((user) {
        final newUserId = user?.uid;

        // Если пользователь изменился (не просто вошел/вышел, а именно сменился)
        if (_currentUserId != newUserId) {
          debugPrint('User changed from $_currentUserId to $newUserId');
          // Сбрасываем локальные результаты перед загрузкой новых для текущего пользователя
          _results.clear();
        }

        // Обновляем текущий userId
        _currentUserId = newUserId;

        // Перезагружаем результаты для нового пользователя
        _loadExistingResults();

        // Синхронизируем данные только если пользователь вошел
        if (user != null) {
          syncResultsToFirestore();
        }
      });

      _isInitialized = true;
      debugPrint('ResultSaverService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ResultSaverService: $e');
    }
    return this;
  }

  // Асинхронный метод для получения пути к папке с результатами пользователя
  Future<String> _getUserResultsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final userId = _userPrefs.getCurrentUserId();
    return '${appDir.path}/$resultsFolderName/$userId';
  }

  Future<void> _loadExistingResults() async {
    try {
      // Clear existing results first
      _results.clear();

      // Always check local storage first
      final resultsDir = Directory(await _getUserResultsPath());

      if (!await resultsDir.exists()) return;

      final List<FileSystemEntity> files = await resultsDir
          .list()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      final List<Map<String, dynamic>> loadedResults = [];

      // Получаем текущий userId для фильтрации результатов
      final currentUserId = _authService.currentUser?.uid;

      for (var file in files) {
        try {
          final content = await File(file.path).readAsString();
          final data = json.decode(content) as Map<String, dynamic>;

          // Проверяем, существует ли изображение
          final imageFile = File(data['imagePath'] as String);
          if (await imageFile.exists()) {
            // Если userId не указан в данных, добавляем его
            if (!data.containsKey('userId')) {
              data['userId'] = currentUserId;
              // Обновляем файл с userId
              await File(file.path).writeAsString(json.encode(data));
            }

            // Загружаем только результаты текущего пользователя или без userId
            if (currentUserId == null ||
                data['userId'] == null ||
                data['userId'] == currentUserId) {
              loadedResults.add(data);
            } else {
              debugPrint('Skipping result that belongs to another user: ${data['userId']}');
            }
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

      // If user is logged in, also fetch results from Firestore
      // and merge with local results
      if (_authService.isLoggedIn) {
        await _mergeWithFirestoreResults();
      }
    } catch (e) {
      debugPrint('Error loading existing results: $e');
    }
  }

  /// Save analysis result both locally and to Firestore if user is logged in
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

      // Create a local copy of the image
      final File imageFile = File(imagePath);
      final String newImagePath = '$resultPath.jpg';
      await imageFile.copy(newImagePath);

      // Prepare result data for local storage
      final resultData = {
        'imagePath': newImagePath,
        'faceShape': result.faceShape,
        'colorType': result.colorType,
        'makeupRecommendations': result.makeupRecommendations,
        'hairstyleRecommendations': result.hairstyleRecommendations,
        'skincareRecommendations': result.skincareRecommendations,
        'timestamp': timestamp,
        'synced': false,
        'userId': _authService.currentUser?.uid,  // Добавляем userId локально
      };

      // Save to local storage
      final File resultFile = File('$resultPath.json');
      await resultFile.writeAsString(json.encode(resultData));

      // Insert into local results list
      _results.insert(0, resultData);

      // If user is logged in, also save to Firestore
      if (_authService.isLoggedIn) {
        final firestoreResult = await _firestoreAnalysisService.saveAnalysisResult(
          imagePath: newImagePath,
          result: result,
        );

        if (firestoreResult != null) {
          // Update local result with Firestore info
          resultData['firestoreId'] = firestoreResult['id'];
          resultData['firestoreImagePath'] = firestoreResult['imagePath'];
          resultData['synced'] = true;

          // Update the JSON file with synced status
          await resultFile.writeAsString(json.encode(resultData));
        }
      }

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

    // Принудительно перезагружаем результаты текущего пользователя
    final currentUserId = _authService.currentUser?.uid;

    // Если список не пуст, проверяем, что все результаты соответствуют текущему пользователю
    if (_results.isNotEmpty) {
      bool needsReload = false;

      // Если хотя бы один результат принадлежит другому пользователю, перезагружаем
      for (var result in _results) {
        if (result['userId'] != null &&
            currentUserId != null &&
            result['userId'] != currentUserId) {
          debugPrint('Found result belonging to different user, reloading...');
          needsReload = true;
          break;
        }
      }

      if (needsReload) {
        await _loadExistingResults();
      }
    } else {
      // Если список пуст, загружаем результаты
      await _loadExistingResults();
    }

    return _results;
  }

  Future<void> deleteResult(String imagePath) async {
    try {
      // Get result data from local list
      final resultData = _results.firstWhere(
            (result) => result['imagePath'] == imagePath,
        orElse: () => <String, dynamic>{},
      );

      // If result exists in Firestore, delete it there too
      if (resultData.isNotEmpty &&
          resultData['synced'] == true &&
          resultData.containsKey('firestoreId') &&
          _authService.isLoggedIn) {

        await _firestoreAnalysisService.deleteAnalysisResult(
          resultData['firestoreId'],
          resultData['firestoreImagePath'] ?? '',
        );
      }

      // Delete local files
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      final jsonPath = imagePath.replaceAll('.jpg', '.json');
      final resultFile = File(jsonPath);
      if (await resultFile.exists()) {
        await resultFile.delete();
      }

      // Remove from local list
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

      // If user is logged in, also delete from Firestore
      if (_authService.isLoggedIn) {
        try {
          final firestoreResults = await _firestoreAnalysisService.getUserAnalysisResults();
          for (final result in firestoreResults) {
            await _firestoreAnalysisService.deleteAnalysisResult(
              result['id'],
              result['imagePath'] ?? '',
            );
          }
        } catch (e) {
          debugPrint('Error clearing results from Firestore: $e');
        }
      }

      debugPrint('All results cleared successfully');
    } catch (e) {
      debugPrint('Error clearing results: $e');
      rethrow;
    }
  }

  /// Sync local results to Firestore
  Future<int> syncResultsToFirestore() async {
    if (!_authService.isLoggedIn) {
      debugPrint('User not logged in, cannot sync to Firestore');
      return 0;
    }

    _isSyncing.value = true;

    try {
      // Get local results that belong to current user and have not been synced
      final currentUserId = _authService.currentUser!.uid;
      final unsyncedResults = _results.where((result) =>
      (result['userId'] == currentUserId || result['userId'] == null) &&
          (result['synced'] != true || !result.containsKey('firestoreId'))
      ).toList();

      if (unsyncedResults.isEmpty) {
        debugPrint('No unsynced results for current user to upload');
        _isSyncing.value = false;
        return 0;
      }

      final syncedCount = await _firestoreAnalysisService.syncLocalResultsToFirestore(unsyncedResults);

      if (syncedCount > 0) {
        // Reload to get updated data
        await _loadExistingResults();
      }

      return syncedCount;
    } catch (e) {
      debugPrint('Error syncing results to Firestore: $e');
      return 0;
    } finally {
      _isSyncing.value = false;
    }
  }

  /// Merge local results with Firestore results
  Future<void> _mergeWithFirestoreResults() async {
    if (!_authService.isLoggedIn) return;

    try {
      final currentUserId = _authService.currentUser!.uid;
      final firestoreResults = await _firestoreAnalysisService.getUserAnalysisResults();

      if (firestoreResults.isEmpty) return;

      // Create a map of local results by timestamp for quick lookup
      final Map<int, Map<String, dynamic>> localResultsByTimestamp = {};
      for (final result in _results) {
        localResultsByTimestamp[result['timestamp']] = result;
      }

      // Create list for results that only exist in Firestore
      final List<Map<String, dynamic>> newResults = [];

      for (final firestoreResult in firestoreResults) {
        final timestamp = firestoreResult['timestamp'] as int;

        if (localResultsByTimestamp.containsKey(timestamp)) {
          // Update local result with Firestore data
          final localResult = localResultsByTimestamp[timestamp]!;
          localResult['firestoreId'] = firestoreResult['id'];
          localResult['firestoreImagePath'] = firestoreResult['imagePath'];
          localResult['synced'] = true;
          localResult['userId'] = currentUserId; // Убедимся, что userId установлен

          // Update the JSON file
          final jsonPath = localResult['imagePath'].replaceAll('.jpg', '.json');
          final resultFile = File(jsonPath);
          if (await resultFile.exists()) {
            await resultFile.writeAsString(json.encode(localResult));
          }
        } else {
          // This result only exists in Firestore
          newResults.add({
            'imagePath': firestoreResult['imagePath'], // Remote path
            'faceShape': firestoreResult['faceShape'],
            'colorType': firestoreResult['colorType'],
            'makeupRecommendations': List<String>.from(firestoreResult['makeupRecommendations']),
            'hairstyleRecommendations': List<String>.from(firestoreResult['hairstyleRecommendations']),
            'skincareRecommendations': List<String>.from(firestoreResult['skincareRecommendations']),
            'timestamp': timestamp,
            'firestoreId': firestoreResult['id'],
            'firestoreImagePath': firestoreResult['imagePath'],
            'synced': true,
            'isRemote': true, // Flag to indicate this is a remote result
            'userId': currentUserId, // Always set the current user ID
          });
        }
      }

      // Add new results to the list
      if (newResults.isNotEmpty) {
        _results.addAll(newResults);
        // Sort by timestamp
        _results.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      }

      debugPrint('Merged ${newResults.length} results from Firestore');
    } catch (e) {
      debugPrint('Error merging with Firestore results: $e');
    }
  }
}