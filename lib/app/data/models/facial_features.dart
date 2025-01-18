import 'dart:math' show Point;

class FacialFeatures {
  final double symmetry;
  final double faceWidth;
  final double faceHeight;
  final double jawlineStrength;
  final double cheekboneProminence;
  final double foreheadHeight;
  final List<Point<int>> facialContours;

  FacialFeatures({
    required this.symmetry,
    required this.faceWidth,
    required this.faceHeight,
    required this.jawlineStrength,
    required this.cheekboneProminence,
    required this.foreheadHeight,
    required this.facialContours,
  });
}
