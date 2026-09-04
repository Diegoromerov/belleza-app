import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceOverlayPainter extends CustomPainter {
  final Face? detectedFace;
  final bool isValid;
  final double quality;
  final Size screenSize;
  final double animationValue;

  FaceOverlayPainter({
    this.detectedFace,
    required this.isValid,
    required this.quality,
    required this.screenSize,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 35);
    final ovalWidth = size.width * 0.65;
    final ovalHeight = size.height * 0.48;
    final ovalRect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

    // 1. Máscara de recorte translúcida suave (Haute Beauté)
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bgPath, bgPaint);

    // 2. Tono oro champán sutil (Alta Costura)
    const goldColor = Color(0xFFC5A052);
    const goldSoft = Color(0xFFF3D59B);

    // 3. Guía oval principal ultrafina
    final ovalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = isValid ? goldColor : goldSoft.withValues(alpha: 0.7);
    canvas.drawOval(ovalRect, ovalPaint);

    // 4. Corchetes angulares de visagismo milimétricos (Haute Joaillerie)
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square
      ..color = goldColor.withValues(alpha: 0.85);

    const bSize = 18.0;
    const bOffset = 6.0;

    // Superior Izquierda
    canvas.drawLine(Offset(ovalRect.left - bOffset, ovalRect.top + bSize), Offset(ovalRect.left - bOffset, ovalRect.top - bOffset), bracketPaint);
    canvas.drawLine(Offset(ovalRect.left - bOffset, ovalRect.top - bOffset), Offset(ovalRect.left + bSize, ovalRect.top - bOffset), bracketPaint);

    // Superior Derecha
    canvas.drawLine(Offset(ovalRect.right + bOffset, ovalRect.top + bSize), Offset(ovalRect.right + bOffset, ovalRect.top - bOffset), bracketPaint);
    canvas.drawLine(Offset(ovalRect.right + bOffset, ovalRect.top - bOffset), Offset(ovalRect.right - bSize, ovalRect.top - bOffset), bracketPaint);

    // Inferior Izquierda
    canvas.drawLine(Offset(ovalRect.left - bOffset, ovalRect.bottom - bSize), Offset(ovalRect.left - bOffset, ovalRect.bottom + bOffset), bracketPaint);
    canvas.drawLine(Offset(ovalRect.left - bOffset, ovalRect.bottom + bOffset), Offset(ovalRect.left + bSize, ovalRect.bottom + bOffset), bracketPaint);

    // Inferior Derecha
    canvas.drawLine(Offset(ovalRect.right + bOffset, ovalRect.bottom - bSize), Offset(ovalRect.right + bOffset, ovalRect.bottom + bOffset), bracketPaint);
    canvas.drawLine(Offset(ovalRect.right + bOffset, ovalRect.bottom + bOffset), Offset(ovalRect.right - bSize, ovalRect.bottom + bOffset), bracketPaint);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.detectedFace != detectedFace ||
        oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality ||
        oldDelegate.animationValue != animationValue;
  }
}
