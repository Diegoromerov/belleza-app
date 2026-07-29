import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';

/// Modelo liviano de partícula para el sistema de destellos dorados.
class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double theta;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.theta,
  });

  factory _Particle.random(math.Random random) {
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: random.nextDouble() * 2.5 + 1.0,
      speed: random.nextDouble() * 0.15 + 0.05,
      opacity: random.nextDouble() * 0.6 + 0.2,
      theta: random.nextDouble() * math.pi * 2,
    );
  }

  void update(double delta) {
    theta += delta * 0.5;
    y -= speed * delta * 0.2;
    x += math.sin(theta) * 0.001;

    // Reiniciar posición al salir de la pantalla
    if (y < -0.05) {
      y = 1.05;
    }
  }
}

/// Widget animado de alta eficiencia (sin jank) que renderiza partículas doradas
/// ([GlowTokens.roseGold]) flotando suavemente utilizando [TickerProviderStateMixin].
class ParticleSystem extends StatefulWidget {
  final int numberOfParticles;
  final Widget? child;

  const ParticleSystem({
    super.key,
    this.numberOfParticles = 25,
    this.child,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.numberOfParticles,
      (_) => _Particle.random(_random),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Actualizar posiciones de partículas de forma eficiente por frame
        for (final particle in _particles) {
          particle.update(0.016);
        }

        return CustomPaint(
          painter: _ParticleSystemPainter(
            particles: _particles,
            color: GlowTokens.roseGold,
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _ParticleSystemPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticleSystemPainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final center = Offset(particle.x * size.width, particle.y * size.height);
      paint.color = color.withValues(alpha: particle.opacity);
      canvas.drawCircle(center, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleSystemPainter oldDelegate) {
    return true;
  }
}
