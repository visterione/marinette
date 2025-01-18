import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' show Point;

enum FaceShape {
  oval,
  round,
  square,
  heart,
  diamond,
  rectangle,
}

class FaceShapeAnalyzer {
  static FaceShape analyzeFaceShape(Face face) {
    final double faceWidth = face.boundingBox.width;
    final double faceHeight = face.boundingBox.height;
    final double ratio = faceHeight / faceWidth;

    // Отримуємо контури обличчя
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null) return FaceShape.oval;

    // Аналіз форми на основі співвідношень та контурів
    if (ratio > 1.5) {
      return _analyzeElongatedFace(faceContour);
    } else if (ratio < 1.2) {
      return _analyzeWideFace(faceContour);
    } else {
      return _analyzeMediumFace(faceContour);
    }
  }

  static FaceShape _analyzeElongatedFace(FaceContour contour) {
    // Аналіз верхньої частини обличчя
    double topWidth = _getWidthAtPosition(contour.points, 0.2);
    double bottomWidth = _getWidthAtPosition(contour.points, 0.8);

    if (topWidth < bottomWidth * 0.85) {
      return FaceShape.heart;
    } else if (topWidth > bottomWidth * 1.15) {
      return FaceShape.diamond;
    }

    return FaceShape.oval;
  }

  static FaceShape _analyzeWideFace(FaceContour contour) {
    // Аналіз кутів щелепи
    double jawAngle = _calculateJawAngle(contour.points);

    if (jawAngle > 80) {
      return FaceShape.square;
    }

    return FaceShape.round;
  }

  static FaceShape _analyzeMediumFace(FaceContour contour) {
    // Аналіз пропорцій середньої частини обличчя
    double middleWidth = _getWidthAtPosition(contour.points, 0.5);
    double topWidth = _getWidthAtPosition(contour.points, 0.2);

    if (middleWidth > topWidth * 1.1) {
      return FaceShape.rectangle;
    }

    return FaceShape.oval;
  }

  static double _getWidthAtPosition(
      List<Point<int>> points, double heightPercent) {
    if (points.isEmpty) return 0;

    final firstPoint = points.first;
    final lastPoint = points.last;

    int targetY =
        (firstPoint.y + (lastPoint.y - firstPoint.y) * heightPercent).round();

    var pointsAtHeight =
        points.where((p) => (p.y - targetY).abs() < 5).toList();

    if (pointsAtHeight.isEmpty) return 0;

    var xValues = pointsAtHeight.map((p) => p.x).toList();

    double minX = xValues.reduce((a, b) => a < b ? a : b).toDouble();
    double maxX = xValues.reduce((a, b) => a > b ? a : b).toDouble();

    return maxX - minX;
  }

  static double _calculateJawAngle(List<Point<int>> points) {
    if (points.length < 3) return 90;

    // Спрощений розрахунок кута щелепи
    var bottomPoints = points.where((p) {
      var maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      return p.y > maxY - 20;
    }).toList();

    if (bottomPoints.length < 3) return 90;

    var sorted = bottomPoints..sort((a, b) => a.x.compareTo(b.x));
    var first = sorted.first;
    var last = sorted.last;
    var middle = sorted[sorted.length ~/ 2];

    // Розрахунок кута між трьома точками
    double dx1 = (first.x - middle.x).toDouble();
    double dy1 = (first.y - middle.y).toDouble();
    double dx2 = (last.x - middle.x).toDouble();
    double dy2 = (last.y - middle.y).toDouble();

    double dotProduct = dx1 * dx2 + dy1 * dy2;
    double magnitude1 = sqrt(dx1 * dx1 + dy1 * dy1);
    double magnitude2 = sqrt(dx2 * dx2 + dy2 * dy2);

    if (magnitude1 == 0 || magnitude2 == 0) return 90;

    return (180 / 3.14159) * (dotProduct / (magnitude1 * magnitude2));
  }

  static double sqrt(double x) => x <= 0 ? 0 : x.roundToDouble();
}
