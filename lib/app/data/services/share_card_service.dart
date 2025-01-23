import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';

class ShareCardService {
  static Future<void> shareAnalysisResult({
    required String imagePath,
    required FaceAnalysisResult result,
  }) async {
    final shareCard = Material(
      child: Container(
        width: 1080,
        height: 1920,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink, Colors.purple],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 1080,
              width: 1080,
              child: Stack(
                children: [
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    height: 1080,
                    width: 1080,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.faceShape,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          result.colorType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecommendationSection(
                      '💄',
                      'makeup_recommendations'.tr,
                      result.makeupRecommendations.take(3).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildRecommendationSection(
                      '💇‍♀️',
                      'hairstyle_recommendations'.tr,
                      result.hairstyleRecommendations.take(3).toList(),
                    ),
                    const SizedBox(height: 20),
                    _buildRecommendationSection(
                      '✨',
                      'skincare_recommendations'.tr,
                      result.skincareRecommendations.take(3).toList(),
                    ),
                    const Spacer(),
                    const Center(
                      child: Text(
                        'Beauty Recommendations App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final repaintBoundary = RenderRepaintBoundary();
      final view = BuildOwner();
      final pipelineOwner = PipelineOwner();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: shareCard,
      ).attachToRenderTree(BuildOwner(focusManager: FocusManager()));

      pipelineOwner.rootNode = repaintBoundary;
      view.buildScope(rootElement);
      view.buildScope(rootElement);
      await Future.delayed(const Duration(milliseconds: 20));
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final shareCardPath = '${tempDir.path}/share_card.png';
      await File(shareCardPath).writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(shareCardPath)],
        text: 'Discover your beauty type with Beauty Recommendations App! 🎭✨',
      );
    } catch (e) {
      debugPrint('Error sharing analysis result: $e');
      Get.snackbar('error'.tr, 'error_sharing'.tr);
    }
  }

  static Widget _buildRecommendationSection(
    String icon,
    String title,
    List<String> recommendations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
