// frontend/lib/screens/ideas/widgets/vto_painter.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class VtoPainter extends CustomPainter {
  final Face? face;
  final Color? lipstickColor;
  final double lipstickOpacity;
  final String finish; // 'Mate', 'Satinado', 'Brillante'
  final Size imageSize;
  final InputImageRotation rotation;

  VtoPainter({
    this.face,
    this.lipstickColor,
    this.lipstickOpacity = 0.6,
    this.finish = 'Mate',
    required this.imageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null || lipstickColor == null) return;

    // Obtener contornos de labios de ML Kit
    final upperLipTop = face!.contours[FaceContourType.upperLipTop]?.points;
    final upperLipBottom = face!.contours[FaceContourType.upperLipBottom]?.points;
    final lowerLipTop = face!.contours[FaceContourType.lowerLipTop]?.points;
    final lowerLipBottom = face!.contours[FaceContourType.lowerLipBottom]?.points;

    if (upperLipTop != null && upperLipBottom != null) {
      _drawLipContour(canvas, size, upperLipTop, upperLipBottom);
    }

    if (lowerLipTop != null && lowerLipBottom != null) {
      _drawLipContour(canvas, size, lowerLipTop, lowerLipBottom);
    }
  }

  void _drawLipContour(Canvas canvas, Size size, List<Point<int>> topPoints, List<Point<int>> bottomPoints) {
    if (topPoints.isEmpty || bottomPoints.isEmpty) return;

    final path = Path();
    final firstPoint = _translateX(topPoints.first.x.toDouble(), size);
    final firstY = _translateY(topPoints.first.y.toDouble(), size);
    path.moveTo(firstPoint, firstY);

    for (int i = 1; i < topPoints.length; i++) {
      path.lineTo(
        _translateX(topPoints[i].x.toDouble(), size),
        _translateY(topPoints[i].y.toDouble(), size),
      );
    }

    for (int i = bottomPoints.length - 1; i >= 0; i--) {
      path.lineTo(
        _translateX(bottomPoints[i].x.toDouble(), size),
        _translateY(bottomPoints[i].y.toDouble(), size),
      );
    }
    path.close();

    final paint = Paint()
      ..color = lipstickColor!.withOpacity(lipstickOpacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    if (finish == 'Satinado') {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    } else if (finish == 'Brillante') {
      paint.blendMode = BlendMode.colorDodge;
    }

    canvas.drawPath(path, paint);
  }

  double _translateX(double x, Size size) {
    if (imageSize.width == 0) return x;
    return x * size.width / imageSize.width;
  }

  double _translateY(double y, Size size) {
    if (imageSize.height == 0) return y;
    return y * size.height / imageSize.height;
  }

  @override
  bool shouldRepaint(VtoPainter oldDelegate) {
    return oldDelegate.face != face ||
        oldDelegate.lipstickColor != lipstickColor ||
        oldDelegate.lipstickOpacity != lipstickOpacity ||
        oldDelegate.finish != finish;
  }
}
