import 'dart:math';
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
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final ovalWidth = size.width * 0.68;
    final ovalHeight = size.height * 0.52;
    final ovalRect = Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

    // 1. Mascara de recorte para fondo translúcido fuera del óvalo
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);
    
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bgPath, bgPaint);

    // 2. Colores del estado neón: Terracota (Buscando) -> Dorado (Alineando) -> Esmeralda (Perfecto)
    final mainColor = isValid
        ? const Color(0xFF00E676) // Verde Neón Esmeralda
        : (detectedFace != null ? const Color(0xFFD4AF37) : const Color(0xFFE05A47)); // Dorado / Terracota

    // 3. Anillo Neón Exterior con Glow Blur
    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = mainColor.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(ovalRect, outerGlowPaint);

    // 4. Anillo Interior Fino Blanco / Neón
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isValid ? Colors.white : mainColor.withOpacity(0.9);
    canvas.drawOval(ovalRect, innerPaint);

    // 5. Corchetes Angulares de Enfoque Cyber-Champán en las 4 Esquinas
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = mainColor;

    const bracketSize = 24.0;
    // Esquina Superior Izquierda
    canvas.drawLine(Offset(ovalRect.left - 8, ovalRect.top + bracketSize), Offset(ovalRect.left - 8, ovalRect.top - 8), bracketPaint);
    canvas.drawLine(Offset(ovalRect.left - 8, ovalRect.top - 8), Offset(ovalRect.left + bracketSize, ovalRect.top - 8), bracketPaint);

    // Esquina Superior Derecha
    canvas.drawLine(Offset(ovalRect.right + 8, ovalRect.top + bracketSize), Offset(ovalRect.right + 8, ovalRect.top - 8), bracketPaint);
    canvas.drawLine(Offset(ovalRect.right + 8, ovalRect.top - 8), Offset(ovalRect.right - bracketSize, ovalRect.top - 8), bracketPaint);

    // Esquina Inferior Izquierda
    canvas.drawLine(Offset(ovalRect.left - 8, ovalRect.bottom - bracketSize), Offset(ovalRect.left - 8, ovalRect.bottom + 8), bracketPaint);
    canvas.drawLine(Offset(ovalRect.left - 8, ovalRect.bottom + 8), Offset(ovalRect.left + bracketSize, ovalRect.bottom + 8), bracketPaint);

    // Esquina Inferior Derecha
    canvas.drawLine(Offset(ovalRect.right + 8, ovalRect.bottom - bracketSize), Offset(ovalRect.right + 8, ovalRect.bottom + 8), bracketPaint);
    canvas.drawLine(Offset(ovalRect.right + 8, ovalRect.bottom + 8), Offset(ovalRect.right - bracketSize, ovalRect.bottom + 8), bracketPaint);

    // 6. Micro-partículas doradas orbitando a 30 FPS
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = mainColor.withOpacity(0.9);

    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * (2 * pi / particleCount)) + (animationValue * 2 * pi);
      final px = center.dx + (ovalWidth / 2) * cos(angle);
      final py = center.dy + (ovalHeight / 2) * sin(angle);
      canvas.drawCircle(Offset(px, py), 3.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.detectedFace != detectedFace ||
        oldDelegate.isValid != isValid ||
        oldDelegate.quality != quality ||
        oldDelegate.animationValue != animationValue;
  }
}
