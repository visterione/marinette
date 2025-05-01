import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:marinette/app/data/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatelessWidget {
  final ResultSaverService _saverService = Get.find<ResultSaverService>();
  final AuthService _authService = Get.find<AuthService>();
  final RxBool _isLoading = false.obs;
  final RxBool _isSyncing = false.obs;

  HistoryScreen({super.key});

  Future<void> _refreshResults() async {
    debugPrint('Refreshing history results');
    _isLoading.value = true;
    try {
      await _saverService.getAllResults();
    } catch (e) {
      debugPrint('Error refreshing results: $e');
      Get.snackbar(
        'error'.tr,
        'error_loading_results'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _openResult(Map<String, dynamic> resultData) {
    debugPrint('Opening result details');
    final result = FaceAnalysisResult(
      faceShape: resultData['faceShape'],
      colorType: resultData['colorType'],
      makeupRecommendations:
      List<String>.from(resultData['makeupRecommendations']),
      hairstyleRecommendations:
      List<String>.from(resultData['hairstyleRecommendations']),
      skincareRecommendations:
      List<String>.from(resultData['skincareRecommendations']),
    );

    Get.to(() => AnalysisResultScreen(
      imagePath: resultData['imagePath'],
      result: result,
    ));
  }

  Future<void> _deleteResult(String imagePath) async {
    debugPrint('Deleting result: $imagePath');
    try {
      await _saverService.deleteResult(imagePath);
      Get.snackbar(
        'info'.tr,
        'result_deleted_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error deleting result: $e');
      Get.snackbar(
        'error'.tr,
        'error_deleting_result'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _syncResults() async {
    if (!_authService.isLoggedIn) {
      Get.snackbar(
        'info'.tr,
        'login_to_sync'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _isSyncing.value = true;
    try {
      final syncedCount = await _saverService.syncResultsToFirestore();
      Get.snackbar(
        'success'.tr,
        syncedCount > 0
            ? 'synced_results'.trParams({'count': syncedCount.toString()})
            : 'all_results_synced'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error syncing results: $e');
      Get.snackbar(
        'error'.tr,
        'error_syncing_results'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSyncing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HistoryScreen');
    // При створенні екрану оновлюємо дані
    _refreshResults();

    return Scaffold(
      appBar: AppBar(
        title: Text('history'.tr),
        actions: [
          // Sync button (only if logged in)
          Obx(() => _authService.isLoggedIn
              ? IconButton(
            icon: _isSyncing.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.cloud_upload),
            tooltip: 'sync_to_cloud'.tr,
            onPressed: _isSyncing.value ? null : _syncResults,
          )
              : const SizedBox()),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshResults,
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _saverService.getAllResults(),
          builder: (context, snapshot) {
            debugPrint(
                'Building FutureBuilder with state: ${snapshot.connectionState}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('Error loading history: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'error_loading_results'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              debugPrint('No history data available');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_history'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            debugPrint(
                'Building history list with ${snapshot.data!.length} items');
            return RefreshIndicator(
              onRefresh: _refreshResults,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final result = snapshot.data![index];
                  debugPrint('Building history item $index');

                  final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                    result['timestamp'] as int,
                  );
                  final String formattedDate =
                  DateFormat('dd.MM.yyyy HH:mm').format(date);

                  // Check if result is synced to cloud
                  final bool isSynced = result['synced'] == true;
                  // Check if this is a remote image
                  final bool isRemoteImage = result['isRemote'] == true ||
                      (result['imagePath'] as String).contains('firebasestorage.googleapis.com');

                  return Dismissible(
                    key: Key(result['imagePath']),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await Get.dialog<bool>(
                        AlertDialog(
                          title: Text('confirm_delete'.tr),
                          content: Text('delete_result_confirmation'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: Text('cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: Text(
                                'delete'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                          false;
                    },
                    onDismissed: (direction) {
                      _deleteResult(result['imagePath']);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _openResult(result),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Зображення
                            if (result['imagePath'] != null)
                              SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  child: isRemoteImage
                                      ? CachedNetworkImage(
                                    imageUrl: result['imagePath'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint('Error loading remote image: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                      : Image.file(
                                    File(result['imagePath']),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading image: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // Інформація
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Cloud status icon
                                          if (_authService.isLoggedIn)
                                            Tooltip(
                                              message: isSynced
                                                  ? 'synced_to_cloud'.tr
                                                  : 'not_synced'.tr,
                                              child: Icon(
                                                isSynced ? Icons.cloud_done : Icons.cloud_off,
                                                size: 18,
                                                color: isSynced ? Colors.green : Colors.grey,
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            onPressed: () =>
                                                _deleteResult(result['imagePath']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${result['faceShape']} / ${result['colorType']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates_outlined,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(result['makeupRecommendations'] as List).length + (result['hairstyleRecommendations'] as List).length + (result['skincareRecommendations'] as List).length} ' + 'recommendations'.tr,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}