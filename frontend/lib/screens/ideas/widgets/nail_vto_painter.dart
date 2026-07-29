// frontend/lib/screens/ideas/widgets/nail_vto_painter.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class NailVtoPainter extends CustomPainter {
  final Color nailColor;
  final String nailStyle; // 'Almond', 'Square', 'Oval', 'Coffin'
  final String finish; // 'Mate', 'Satinado', 'Brillante'
  final double opacity;

  NailVtoPainter({
    required this.nailColor,
    required this.nailStyle,
    this.finish = 'Brillante',
    this.opacity = 0.85,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final handRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5,
      height: size.height * 0.5,
    );

    final fingerWidth = handRect.width * 0.11;
    final fingerHeights = [
      handRect.height * 0.22, // Meñique
      handRect.height * 0.28, // Anular
      handRect.height * 0.32, // Medio
      handRect.height * 0.27, // Índice
      handRect.height * 0.20, // Pulgar
    ];

    final paint = Paint()
      ..color = nailColor.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    if (finish == 'Satinado') {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    } else if (finish == 'Brillante') {
      paint.blendMode = BlendMode.colorDodge;
    }

    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(finish == 'Brillante' ? 0.35 : 0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = handRect.left + (i + 0.5) * handRect.width / 5 - fingerWidth / 2;
      final y = handRect.top - fingerHeights[i];
      final nailRect = Rect.fromLTWH(x, y, fingerWidth, fingerWidth * 1.5);

      Path nailPath;
      switch (nailStyle.toLowerCase()) {
        case 'almond':
          nailPath = _createAlmondPath(nailRect);
          break;
        case 'square':
          nailPath = _createSquarePath(nailRect);
          break;
        case 'coffin':
          nailPath = _createCoffinPath(nailRect);
          break;
        case 'oval':
        default:
          nailPath = _createOvalPath(nailRect);
          break;
      }

      canvas.drawPath(nailPath, paint);

      // Brillo specular simulado
      final shineRect = Rect.fromLTWH(
        nailRect.left + nailRect.width * 0.2,
        nailRect.top + nailRect.height * 0.15,
        nailRect.width * 0.25,
        nailRect.height * 0.5,
      );
      canvas.drawOval(shineRect, shinePaint);
    }
  }

  Path _createAlmondPath(Rect rect) {
    final path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.top + rect.height * 0.4);
    path.quadraticBezierTo(
      rect.center.dx,
      rect.top - rect.height * 0.2,
      rect.right,
      rect.top + rect.height * 0.4,
    );
    path.lineTo(rect.right, rect.bottom);
    path.close();
    return path;
  }

  Path _createSquarePath(Rect rect) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
    );
    return path;
  }

  Path _createCoffinPath(Rect rect) {
    final path = Path();
    final inset = rect.width * 0.2;
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left + inset, rect.top);
    path.lineTo(rect.right - inset, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.close();
    return path;
  }

  Path _createOvalPath(Rect rect) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.width / 2),
      ),
    );
    return path;
  }

  @override
  bool shouldRepaint(NailVtoPainter oldDelegate) {
    return oldDelegate.nailColor != nailColor ||
        oldDelegate.nailStyle != nailStyle ||
        oldDelegate.finish != finish ||
        oldDelegate.opacity != opacity;
  }
}
