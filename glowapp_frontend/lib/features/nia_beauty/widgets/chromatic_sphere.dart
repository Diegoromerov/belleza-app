import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';

/// Widget animado que dibuja una esfera cromática con gradiente radial que simula
/// un efecto de respiración/pulsación durante un ciclo configurable (por defecto 2 segundos).
class ChromaticSphere extends StatefulWidget {
  final double size;
  final Duration duration;

  const ChromaticSphere({
    super.key,
    this.size = 200.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ChromaticSphere> createState() => _ChromaticSphereState();
}

class _ChromaticSphereState extends State<ChromaticSphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ChromaticSpherePainter(
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

class _ChromaticSpherePainter extends CustomPainter {
  final double progress;

  _ChromaticSpherePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2;
    
    // Variación del radio para efecto de respiración (pulsación de ±10%)
    final currentRadius = baseRadius * (0.9 + (0.2 * progress));

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          GlowTokens.roseGold.withValues(alpha: 0.85),
          GlowTokens.terracota.withValues(alpha: 0.6),
          GlowTokens.amber.withValues(alpha: 0.3),
          GlowTokens.creamSilk.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 0.8, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: currentRadius),
      );

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ChromaticSpherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
