// frontend/lib/screens/ideas/widgets/hand_overlay_painter.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class HandOverlayPainter extends CustomPainter {
  final bool isValid;
  final double quality;
  final Size screenSize;

  HandOverlayPainter({
    required this.isValid,
    required this.quality,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar silueta guía de mano
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = isValid ? Colors.green : Colors.red;

    final handRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5,
      height: size.height * 0.5,
    );

    // Silueta simplificada de mano (rectángulo redondeado + dedos)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        handRect,
        const Radius.circular(20),
      ),
      paint,
    );

    // Dibujar 5 dedos superiores
    final fingerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isValid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);

    final fingerWidth = handRect.width * 0.12;
    for (int i = 0; i < 5; i++) {
      final x = handRect.left + (i + 0.5) * handRect.width / 5 - fingerWidth / 2;
      final fingerRect = Rect.fromLTWH(
        x,
        handRect.top - handRect.height * 0.25,
        fingerWidth,
        handRect.height * 0.3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fingerRect, const Radius.circular(8)),
        fingerPaint,
      );
    }

    // Barra de calidad
    if (quality > 0) {
      final qualityPaint = Paint()
        ..color = _getQualityColor(quality)
        ..style = PaintingStyle.fill;

      final barWidth = size.width * 0.4;
      final barHeight = 6.0;
      final barY = size.height - 100;

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
    if (quality > 70) return Colors.green;
    if (quality > 40) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(HandOverlayPainter oldDelegate) {
    return oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality;
  }
}
