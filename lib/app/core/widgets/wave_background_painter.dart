import 'package:flutter/material.dart';

class WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Початкова точка
    path.moveTo(0, size.height * 0.3);

    // Перша хвиля
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.5,
      size.height * 0.3,
    );

    // Друга хвиля
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.25,
      size.width,
      size.height * 0.3,
    );

    // Завершення шляху
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
