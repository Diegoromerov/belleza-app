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
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = isValid ? Colors.green : Colors.red;

    // Dibujar el óvalo guía centrado
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(ovalRect, paint);

    // Si se detecta una cara, dibujar la caja delimitadora
    if (detectedFace != null) {
      final face = detectedFace!;
      final rect = face.boundingBox;
      
      final paintFace = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = isValid ? Colors.green : Colors.orange;

      canvas.drawRect(rect, paintFace);

      // Dibujar landmarks faciales esenciales
      final landmarkPaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill
        ..strokeWidth = 4.0;

      for (final landmark in face.landmarks.entries) {
        final point = landmark.value?.position;
        if (point != null) {
          canvas.drawCircle(Offset(point.x.toDouble(), point.y.toDouble()), 3, landmarkPaint);
        }
      }
    }

    // Mostrar barra de calidad
    if (quality > 0) {
      final qualityPaint = Paint()
        ..color = _getQualityColor(quality)
        ..style = PaintingStyle.fill;

      final barWidth = size.width * 0.4;
      final barHeight = 6.0;
      final barY = size.height - 100;

      // Fondo de barra
      final bgPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (size.width - barWidth) / 2,
            barY,
            barWidth,
            barHeight,
          ),
          Radius.circular(barHeight / 2),
        ),
        bgPaint,
      );

      // Barra de progreso
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (size.width - barWidth) / 2,
            barY,
            barWidth * (quality / 100).clamp(0.0, 1.0),
            barHeight,
          ),
          Radius.circular(barHeight / 2),
        ),
        qualityPaint,
      );
    }
  }

  Color _getQualityColor(double quality) {
    if (quality > 80) return Colors.green;
    if (quality > 50) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.detectedFace != detectedFace ||
        oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality;
  }
}
