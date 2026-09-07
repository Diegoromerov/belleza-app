import 'package:flutter/material.dart';

class HandOverlayPainter extends CustomPainter {
  final bool isValid;
  final double quality;
  final Size screenSize;
  final double animationValue;

  HandOverlayPainter({
    required this.isValid,
    required this.quality,
    required this.screenSize,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);
    final handWidth = size.width * 0.58;
    final handHeight = size.height * 0.48;
    final handRect = Rect.fromCenter(center: center, width: handWidth, height: handHeight);

    // 1. Fondo translúcido sutil
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Colores refinados oro champán
    const goldColor = Color(0xFFC5A052);
    const goldSoft = Color(0xFFF3D59B);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = isValid ? goldColor : goldSoft.withValues(alpha: 0.7);

    // 3. Guía continua y estilizada de mano & dedos
    final fingerWidth = handWidth * 0.15;
    final fingerHeight = handHeight * 0.38;

    for (int i = 0; i < 5; i++) {
      final fx = handRect.left + (i + 0.5) * handWidth / 5 - fingerWidth / 2;
      final fy = handRect.top - (i == 2 ? 16 : (i == 1 || i == 3 ? 9 : 0));
      final fingerRect = Rect.fromLTWH(fx, fy, fingerWidth, fingerHeight);

      // Trazo sutil de dedo
      canvas.drawRRect(
        RRect.fromRectAndRadius(fingerRect, const Radius.circular(10)),
        linePaint,
      );

      // Línea fina del lecho ungueal / manicura
      final nailRect = Rect.fromLTWH(fx + 2, fy + 3, fingerWidth - 4, fingerHeight * 0.30);
      final nailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = goldColor.withValues(alpha: 0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(nailRect, const Radius.circular(6)), nailPaint);
    }

    // Palma estilizada
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(handRect.left, handRect.top + handHeight * 0.22, handWidth, handHeight * 0.72),
      const Radius.circular(28),
    );
    canvas.drawRRect(palmRect, linePaint);
  }

  @override
  bool shouldRepaint(HandOverlayPainter oldDelegate) {
    return oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality ||
        oldDelegate.animationValue != animationValue;
  }
}
