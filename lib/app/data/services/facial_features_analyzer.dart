import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' show Point, min, max, sqrt, pow, atan2, pi;
import 'package:marinette/app/data/models/facial_features.dart';

class FacialFeaturesAnalyzer {
  static Future<FacialFeatures> analyzeFace(Face face) async {
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null) {
      throw Exception('Face contour not detected');
    }

    final points = faceContour.points;

    // Аналіз симетрії
    final symmetry = _calculateSymmetry(points);

    // Основні виміри
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;

    // Аналіз щелепи
    final jawlineStrength = _analyzeJawline(face);

    // Аналіз вилиць
    final cheekboneProminence = _analyzeCheekbones(face);

    // Аналіз чола
    final foreheadHeight = _analyzeForeheadHeight(face);

    return FacialFeatures(
      symmetry: symmetry,
      faceWidth: faceWidth,
      faceHeight: faceHeight,
      jawlineStrength: jawlineStrength,
      cheekboneProminence: cheekboneProminence,
      foreheadHeight: foreheadHeight,
      facialContours: points,
    );
  }

  static double _calculateSymmetry(List<Point<int>> points) {
    if (points.isEmpty) return 0.0;

    // Знаходимо центральну вертикальну лінію
    double centerX =
        points.map((p) => p.x).reduce((a, b) => a + b) / points.length;

    // Рахуємо відхилення від симетрії
    double totalDeviation = 0;
    int pairs = 0;

    for (int i = 0; i < points.length ~/ 2; i++) {
      Point<int> leftPoint = points[i];
      Point<int> rightPoint = points[points.length - 1 - i];

      double leftDist = (centerX - leftPoint.x).abs();
      double rightDist = (rightPoint.x - centerX).abs();

      totalDeviation += (leftDist - rightDist).abs();
      pairs++;
    }

    // Нормалізуємо результат до діапазону 0-1
    double avgDeviation = totalDeviation / pairs;
    double maxPossibleDeviation = points.map((p) => p.x).reduce(max).toDouble();

    return 1 - (avgDeviation / maxPossibleDeviation);
  }

  static double _analyzeJawline(Face face) {
    final jawContour = face.contours[FaceContourType.lowerLipBottom];
    if (jawContour == null) return 0.5;

    final points = jawContour.points;
    if (points.isEmpty) return 0.5;

    // Аналізуємо кут і чіткість лінії щелепи
    double angleStrength = _calculateJawlineAngle(points);
    double lineDefinition = _calculateLineDefinition(points);

    return (angleStrength + lineDefinition) / 2;
  }

  static double _analyzeCheekbones(Face face) {
    final leftCheek = face.contours[FaceContourType.leftCheek];
    final rightCheek = face.contours[FaceContourType.rightCheek];

    if (leftCheek == null || rightCheek == null) return 0.5;

    // Аналізуємо випуклість і положення вилиць
    double cheekboneWidth =
        _calculateCheekboneWidth(leftCheek.points, rightCheek.points);
    double cheekboneHeight =
        _calculateCheekboneHeight(leftCheek.points, rightCheek.points);

    return (cheekboneWidth + cheekboneHeight) / 2;
  }

  static double _analyzeForeheadHeight(Face face) {
    final faceContour = face.contours[FaceContourType.face];
    final noseContour = face.contours[FaceContourType.noseBridge];

    if (faceContour == null || noseContour == null) return 0.5;

    // Вимірюємо висоту чола відносно загальної висоти обличчя
    double totalHeight = face.boundingBox.height;
    double foreheadToNose =
        (noseContour.points.first.y - faceContour.points.first.y).toDouble();

    return foreheadToNose / totalHeight;
  }

  static double _calculateJawlineAngle(List<Point<int>> points) {
    if (points.length < 3) return 0.5;

    Point<int> start = points.first;
    Point<int> end = points.last;

    double angle =
        atan2((end.y - start.y).toDouble(), (end.x - start.x).toDouble());
    return (angle.abs() / pi) * 2; // Нормалізуємо до 0-1
  }

  static double _calculateLineDefinition(List<Point<int>> points) {
    if (points.length < 2) return 0.5;

    double totalDeviation = 0;
    for (int i = 1; i < points.length; i++) {
      Point<int> prev = points[i - 1];
      Point<int> curr = points[i];

      totalDeviation += sqrt(pow(curr.x - prev.x, 2) + pow(curr.y - prev.y, 2));
    }

    return 1 - (totalDeviation / (points.length * 10)); // Нормалізуємо до 0-1
  }

  static double _calculateCheekboneWidth(
      List<Point<int>> leftPoints, List<Point<int>> rightPoints) {
    if (leftPoints.isEmpty || rightPoints.isEmpty) return 0.5;

    double leftMax = leftPoints.map((p) => p.x).reduce(min).toDouble();
    double rightMax = rightPoints.map((p) => p.x).reduce(max).toDouble();

    return (rightMax - leftMax) / 100; // Нормалізуємо до 0-1
  }

  static double _calculateCheekboneHeight(
      List<Point<int>> leftPoints, List<Point<int>> rightPoints) {
    if (leftPoints.isEmpty || rightPoints.isEmpty) return 0.5;

    double leftY =
        leftPoints.map((p) => p.y).reduce((a, b) => a + b) / leftPoints.length;
    double rightY = rightPoints.map((p) => p.y).reduce((a, b) => a + b) /
        rightPoints.length;

    return 1 - (((leftY - rightY).abs()) / 50); // Нормалізуємо до 0-1
  }
}
