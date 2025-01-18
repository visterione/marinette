import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/result_saver_service.dart';
import 'package:marinette/app/modules/analysis/analysis_result_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final ResultSaverService _saverService = Get.find<ResultSaverService>();

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('history'.tr),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _saverService.getAllResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final result = snapshot.data![index];
              final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                result['timestamp'] as int,
              );
              final String formattedDate =
                  DateFormat('dd.MM.yyyy HH:mm').format(date);

              return Card(
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
                            child: Image.file(
                              File(result['imagePath']),
                              fit: BoxFit.cover,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _deleteResult(result['imagePath']),
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
                            Text(
                              '${result['makeupRecommendations'].length} рекомендацій',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openResult(Map<String, dynamic> resultData) {
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
    final confirmed = await Get.dialog<bool>(
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
    );

    if (confirmed == true) {
      await _saverService.deleteResult(imagePath);
      Get.forceAppUpdate();
    }
  }
}
