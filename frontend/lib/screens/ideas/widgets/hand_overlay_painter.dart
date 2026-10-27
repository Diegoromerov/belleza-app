import 'dart:math';
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
    final center = Offset(size.width / 2, size.height / 2);
    final handWidth = size.width * 0.55;
    final handHeight = size.height * 0.50;
    final handRect = Rect.fromCenter(center: center, width: handWidth, height: handHeight);

    final mainColor = isValid ? const Color(0xFF00E676) : const Color(0xFFD4AF37);

    // 1. Fondo translúcido
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.40)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Silueta anatómica continua de la palma de la mano
    final palmPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = mainColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final palmPath = Path();
    final palmRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(handRect.left, handRect.top + handRect.height * 0.2, handRect.width, handRect.height * 0.8),
      const Radius.circular(32),
    );
    palmPath.addRRect(palmRRect);
    canvas.drawPath(palmPath, palmPaint);

    // 3. Silueta anatómica de los 5 dedos con arcos de uña Neón
    final fingerWidth = handRect.width * 0.14;
    final fingerHeight = handRect.height * 0.35;

    for (int i = 0; i < 5; i++) {
      final fx = handRect.left + (i + 0.5) * handRect.width / 5 - fingerWidth / 2;
      final fy = handRect.top - (i == 2 ? 15 : (i == 1 || i == 3 ? 8 : 0));
      final fingerRect = Rect.fromLTWH(fx, fy, fingerWidth, fingerHeight);

      final fingerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = mainColor.withOpacity(0.85);

      canvas.drawRRect(
        RRect.fromRectAndRadius(fingerRect, const Radius.circular(12)),
        fingerPaint,
      );

      // Arco Neón sobre la matriz de cada uña
      final nailArcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = isValid ? const Color(0xFF00E676) : const Color(0xFFE05A47);

      final nailRect = Rect.fromLTWH(fx + 2, fy + 4, fingerWidth - 4, fingerHeight * 0.35);
      canvas.drawArc(nailRect, pi, pi, false, nailArcPaint);
    }

    // 4. Indicador de escaneo orbital activo
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = mainColor.withOpacity(0.5);

    final radiusPulse = (handWidth / 2) + (sin(animationValue * 2 * pi) * 6);
    canvas.drawCircle(center, radiusPulse, pulsePaint);
  }

  @override
  bool shouldRepaint(HandOverlayPainter oldDelegate) {
    return oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality ||
        oldDelegate.animationValue != animationValue;
  }
}
