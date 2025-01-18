import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:path_provider/path_provider.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String imagePath;
  final FaceAnalysisResult result;
  final String? heroTag;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    required this.result,
    this.heroTag,
  });

  Future<void> _shareResults() async {
    try {
      // Створюємо текст для шерінгу
      final String shareText = '''
🎭 Результати аналізу:

👤 Форма обличчя: ${result.faceShape}
🎨 Кольоротип: ${result.colorType}

💄 Рекомендації з макіяжу:
${result.makeupRecommendations.map((r) => '• $r').join('\n')}

💇‍♀️ Рекомендації із зачіски:
${result.hairstyleRecommendations.map((r) => '• $r').join('\n')}

✨ Догляд за шкірою:
${result.skincareRecommendations.map((r) => '• $r').join('\n')}

Проаналізовано за допомогою Beauty Recommendations App
''';

      // Копіюємо зображення у тимчасову директорію
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/shared_image.jpg';
      await File(imagePath).copy(tempImagePath);

      // Шерімо текст та зображення
      await Share.shareXFiles(
        [XFile(tempImagePath)],
        text: shareText,
        subject: 'Мої б\'юті-рекомендації',
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_sharing'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? imagePath;

    return Scaffold(
      appBar: AppBar(
        title: Text('recommendations'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Stack(
              children: [
                Hero(
                  tag: tag,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(179),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${result.faceShape} / ${result.colorType}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Recommendations
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecommendationSection(
                    title: 'makeup_recommendations'.tr,
                    recommendations: result.makeupRecommendations,
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationSection(
                    title: 'hairstyle_recommendations'.tr,
                    recommendations: result.hairstyleRecommendations,
                    icon: Icons.content_cut,
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationSection(
                    title: 'skincare_recommendations'.tr,
                    recommendations: result.skincareRecommendations,
                    icon: Icons.spa,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection({
    required String title,
    required List<String> recommendations,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Colors.pink),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
