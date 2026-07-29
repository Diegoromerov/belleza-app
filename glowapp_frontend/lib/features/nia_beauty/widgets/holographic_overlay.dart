import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';

/// Widget que dibuja un óvalo de alineación (superposición holográfica).
/// Cambia fluidamente de dorado ([GlowTokens.roseGold]) a esmeralda ([GlowTokens.emerald])
/// dependiendo del parámetro [isAligned].
class HolographicOverlay extends StatelessWidget {
  final bool isAligned;
  final double width;
  final double height;
  final Duration animationDuration;

  const HolographicOverlay({
    super.key,
    required this.isAligned,
    this.width = 240.0,
    this.height = 320.0,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = isAligned ? GlowTokens.emerald : GlowTokens.roseGold;

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, height / 2),
        ),
        border: Border.all(
          color: targetColor,
          width: isAligned ? 3.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: targetColor.withValues(alpha: isAligned ? 0.4 : 0.2),
            blurRadius: isAligned ? 20.0 : 10.0,
            spreadRadius: isAligned ? 4.0 : 1.0,
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: animationDuration,
          child: Icon(
            isAligned ? Icons.check_circle_outline_rounded : Icons.face_rounded,
            key: ValueKey<bool>(isAligned),
            color: targetColor,
            size: 36.0,
          ),
        ),
      ),
    );
  }
}
