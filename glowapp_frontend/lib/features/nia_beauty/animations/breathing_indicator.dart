import 'package:flutter/material.dart';

/// Indicador de respiración orgánica usando [AnimatedOpacity] y [AnimatedScale]
/// con curva suave estilo cubic-bezier(0.16, 1, 0.3, 1) (`Cubic(0.16, 1.0, 0.3, 1.0)`).
class BreathingIndicator extends StatefulWidget {
  final Widget child;
  final Duration cycleDuration;
  final double minScale;
  final double maxScale;
  final double minOpacity;
  final double maxOpacity;

  const BreathingIndicator({
    super.key,
    required this.child,
    this.cycleDuration = const Duration(seconds: 3),
    this.minScale = 0.92,
    this.maxScale = 1.08,
    this.minOpacity = 0.65,
    this.maxOpacity = 1.0,
  });

  @override
  State<BreathingIndicator> createState() => _BreathingIndicatorState();
}

class _BreathingIndicatorState extends State<BreathingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Curva personalizada cubic-bezier(0.16, 1, 0.3, 1)
  static const Curve _organicBreathingCurve = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: _organicBreathingCurve,
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
        final progress = _animation.value;
        final currentScale = widget.minScale + (widget.maxScale - widget.minScale) * progress;
        final currentOpacity = widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * progress;

        return Transform.scale(
          scale: currentScale,
          child: Opacity(
            opacity: currentOpacity,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
