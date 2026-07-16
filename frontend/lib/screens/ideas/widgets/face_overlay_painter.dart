// frontend/lib/screens/ideas/widgets/face_overlay_painter.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceOverlayPainter extends CustomPainter {
  final Face? detectedFace;
  final bool isValid;
  final double quality;
  final Size screenSize;

  FaceOverlayPainter({
    this.detectedFace,
    required this.isValid,
    required this.quality,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fondo oscuro semitransparente para resaltar el óvalo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Óvalo guía principal
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = isValid ? Colors.greenAccent : Colors.redAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: size.width * 0.65,
      height: size.height * 0.55,
    );
    canvas.drawOval(ovalRect, paint);

    // 3. Borde interior para efecto de "resplandor"
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isValid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
    canvas.drawOval(ovalRect.deflate(6), innerPaint);

    // 4. Bounding box de la cara detectada (solo si no es nulo)
    if (detectedFace != null) {
      final rect = detectedFace!.boundingBox;
      final facePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.cyan;
      canvas.drawRect(rect, facePaint);
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.detectedFace != detectedFace ||
        oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality;
  }
}
