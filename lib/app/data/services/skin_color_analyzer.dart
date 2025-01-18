import 'dart:io';
import 'dart:typed_data';
import 'dart:math' show Point;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class SkinToneResult {
  final double lightness; // 0-1: від темного до світлого
  final double warmth; // 0-1: від холодного до теплого
  final double saturation; // 0-1: від приглушеного до яскравого
  final List<int> rgbValues; // [R, G, B]

  SkinToneResult({
    required this.lightness,
    required this.warmth,
    required this.saturation,
    required this.rgbValues,
  });

  @override
  String toString() {
    return 'SkinTone(lightness: $lightness, warmth: $warmth, saturation: $saturation, RGB: $rgbValues)';
  }
}

class SkinColorAnalyzer {
  static Future<SkinToneResult> analyzeSkinTone(
      String imagePath, Face face) async {
    try {
      // Завантажуємо зображення
      final File imageFile = File(imagePath);
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      // Отримуємо область обличчя
      final cheekPoints = _getCheekPoints(face);
      final foreheadPoints = _getForeheadPoints(face);
      final analyzedPoints = [...cheekPoints, ...foreheadPoints];

      // Аналізуємо колір у вибраних точках
      List<List<int>> colorSamples = [];
      for (final point in analyzedPoints) {
        if (point.x.round() >= 0 &&
            point.x.round() < image.width &&
            point.y.round() >= 0 &&
            point.y.round() < image.height) {
          final pixel = image.getPixel(point.x.round(), point.y.round());
          colorSamples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        }
      }

      // Вираховуємо середні значення
      final averageRGB = _calculateAverageRGB(colorSamples);
      final hsv = _rgbToHSV(averageRGB[0], averageRGB[1], averageRGB[2]);

      return SkinToneResult(
        lightness: hsv[2], // V з HSV
        warmth: _calculateWarmth(averageRGB),
        saturation: hsv[1], // S з HSV
        rgbValues: averageRGB,
      );
    } catch (e) {
      rethrow;
    }
  }

  static List<Point<int>> _getCheekPoints(Face face) {
    final leftCheek = face.contours[FaceContourType.leftCheek]?.points ?? [];
    final rightCheek = face.contours[FaceContourType.rightCheek]?.points ?? [];
    return [...leftCheek, ...rightCheek];
  }

  static List<Point<int>> _getForeheadPoints(Face face) {
    final faceContour = face.contours[FaceContourType.face]?.points ?? [];
    if (faceContour.isEmpty) return [];

    // Беремо точки з верхньої третини обличчя
    final topY = faceContour.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final bottomY = faceContour.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final foreheadThreshold = topY + (bottomY - topY) ~/ 3;

    return faceContour.where((p) => p.y <= foreheadThreshold).toList();
  }

  static List<int> _calculateAverageRGB(List<List<int>> samples) {
    if (samples.isEmpty) return [0, 0, 0];

    int totalR = 0, totalG = 0, totalB = 0;
    for (final sample in samples) {
      totalR += sample[0];
      totalG += sample[1];
      totalB += sample[2];
    }

    return [
      totalR ~/ samples.length,
      totalG ~/ samples.length,
      totalB ~/ samples.length,
    ];
  }

  static List<double> _rgbToHSV(int r, int g, int b) {
    final rf = r / 255;
    final gf = g / 255;
    final bf = b / 255;

    final cmax = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    final cmin = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    final delta = cmax - cmin;

    // Вираховуємо H
    double h = 0;
    if (delta != 0) {
      if (cmax == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (cmax == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    // Вираховуємо S
    final s = cmax == 0 ? 0.0 : delta / cmax;

    // V вже маємо (cmax)
    return [h, s, cmax];
  }

  static double _calculateWarmth(List<int> rgb) {
    // Порівнюємо кількість теплих (червоний) і холодних (синій) тонів
    final redAmount = rgb[0] / 255;
    final blueAmount = rgb[2] / 255;

    // Нормалізуємо до діапазону 0-1, де:
    // 0 - дуже холодний
    // 0.5 - нейтральний
    // 1 - дуже теплий
    return (redAmount - blueAmount + 1) / 2;
  }
}
