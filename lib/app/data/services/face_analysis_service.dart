import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marinette/app/data/models/face_analysis_result.dart';
import 'package:marinette/app/data/services/face_shape_analyzer.dart';
import 'package:marinette/app/data/services/color_type_analyzer.dart';
import 'package:marinette/app/data/services/recommendations_service.dart';

class FaceAnalysisService extends GetxService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<FaceAnalysisResult?> analyzeFace(String imagePath) async {
    debugPrint('Starting face analysis for: $imagePath');
    try {
      late InputImage inputImage;

      if (kIsWeb) {
        final XFile pickedFile = XFile(imagePath);
        final Uint8List bytes = await pickedFile.readAsBytes();
        inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: const Size(800, 600),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: 800 * 4,
          ),
        );
      } else {
        final File imageFile = File(imagePath);
        inputImage = InputImage.fromFile(imageFile);
      }

      debugPrint('Processing image with ML Kit');
      final faces = await _faceDetector.processImage(inputImage);
      debugPrint('Found ${faces.length} faces');

      if (faces.isEmpty) {
        debugPrint('No faces detected');
        return null;
      }

      if (faces.length > 1) {
        debugPrint('Multiple faces detected');
        Get.snackbar('error'.tr, 'error_multiple_faces'.tr);
        return null;
      }

      final face = faces.first;
      debugPrint('Analyzing single face');

      // Визначення форми обличчя
      final faceShape = FaceShapeAnalyzer.analyzeFaceShape(face);
      debugPrint('Face shape determined: $faceShape');

      // Визначення кольоротипу (зменшуємо час очікування)
      final colorType = await ColorTypeAnalyzer.analyzeColorType(imagePath, face)
          .timeout(const Duration(seconds: 2));
      debugPrint('Color type determined: $colorType');

      // Отримання рекомендацій
      debugPrint('Generating recommendations');
      final makeupRecommendations =
      RecommendationsService.getMakeupRecommendations(faceShape, colorType);
      final hairstyleRecommendations =
      RecommendationsService.getHairstyleRecommendations(faceShape, colorType);
      final skincareRecommendations =
      RecommendationsService.getSkincareRecommendations(colorType);

      return FaceAnalysisResult(
        faceShape: _getFaceShapeName(faceShape),
        colorType: _getColorTypeName(colorType),
        makeupRecommendations: makeupRecommendations,
        hairstyleRecommendations: hairstyleRecommendations,
        skincareRecommendations: skincareRecommendations,
      );
    } catch (e) {
      debugPrint('Error during analysis: $e');
      rethrow;
    }
  }

  String _getFaceShapeName(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:
        return 'face_shape_oval'.tr;
      case FaceShape.round:
        return 'face_shape_round'.tr;
      case FaceShape.square:
        return 'face_shape_square'.tr;
      case FaceShape.heart:
        return 'face_shape_heart'.tr;
      case FaceShape.diamond:
        return 'face_shape_diamond'.tr;
      case FaceShape.rectangle:
        return 'face_shape_rectangle'.tr;
    }
  }

  String _getColorTypeName(ColorType type) {
    switch (type) {
      case ColorType.spring:
        return 'color_type_spring'.tr;
      case ColorType.summer:
        return 'color_type_summer'.tr;
      case ColorType.autumn:
        return 'color_type_autumn'.tr;
      case ColorType.winter:
        return 'color_type_winter'.tr;
    }
  }

  @override
  void onClose() {
    _faceDetector.close();
    super.onClose();
  }
}
