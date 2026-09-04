// frontend/lib/screens/ideas/widgets/capture_quality_guard.dart
import 'package:flutter/material.dart';

enum CaptureLightingStatus { ideal, tooDark, tooBright }
enum CaptureDistanceStatus { ideal, tooClose, tooFar }

class CaptureQualityGuard {
  /// Evalúa el brillo promedio (0 - 255)
  static CaptureLightingStatus evaluateLighting(double luminance) {
    if (luminance < 45) return CaptureLightingStatus.tooDark;
    if (luminance > 220) return CaptureLightingStatus.tooBright;
    return CaptureLightingStatus.ideal;
  }

  /// Evalúa el tamaño relativo del rostro en el visor
  static CaptureDistanceStatus evaluateDistance(double faceWidthRatio) {
    if (faceWidthRatio < 0.35) return CaptureDistanceStatus.tooFar;
    if (faceWidthRatio > 0.75) return CaptureDistanceStatus.tooClose;
    return CaptureDistanceStatus.ideal;
  }
}

class QualityGuidanceBadge extends StatelessWidget {
  final CaptureLightingStatus lightingStatus;
  final CaptureDistanceStatus distanceStatus;

  const QualityGuidanceBadge({
    super.key,
    required this.lightingStatus,
    required this.distanceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLightingOk = lightingStatus == CaptureLightingStatus.ideal;
    final bool isDistanceOk = distanceStatus == CaptureDistanceStatus.ideal;
    final bool isAllReady = isLightingOk && isDistanceOk;

    String message = 'Posición y luz ideales para diagnóstico';
    IconData icon = Icons.check_circle_outline_rounded;
    Color bgColor = const Color(0xFF1E1A16).withValues(alpha: 0.85);
    Color accentColor = const Color(0xFFD4AF37);

    if (lightingStatus == CaptureLightingStatus.tooDark) {
      message = 'Poca luz: Ubícate frente a una fuente de luz natural';
      icon = Icons.wb_sunny_outlined;
      accentColor = Colors.orangeAccent;
    } else if (lightingStatus == CaptureLightingStatus.tooBright) {
      message = 'Demasiada luz: Evita el reflejo directo';
      icon = Icons.brightness_medium_outlined;
      accentColor = Colors.orangeAccent;
    } else if (distanceStatus == CaptureDistanceStatus.tooFar) {
      message = 'Acércate un poco más al óvalo';
      icon = Icons.crop_free_rounded;
      accentColor = Colors.amberAccent;
    } else if (distanceStatus == CaptureDistanceStatus.tooClose) {
      message = 'Aléjate ligeramente para encuadrar tu rostro';
      icon = Icons.zoom_out_map_rounded;
      accentColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAllReady ? const Color(0xFFD4AF37) : accentColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: isAllReady ? Colors.white : accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
