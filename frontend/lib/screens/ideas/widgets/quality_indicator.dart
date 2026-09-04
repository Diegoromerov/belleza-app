// frontend/lib/screens/ideas/widgets/quality_indicator.dart
import 'package:flutter/material.dart';

class QualityIndicator extends StatelessWidget {
  final double quality;

  const QualityIndicator({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    final text = quality > 75
        ? 'LUZ AMBIENTAL: ÓPTIMA'
        : quality > 45
            ? 'ENCUADRE EN CURSO'
            : 'AJUSTA LA ILUMINACIÓN';

    const color = Color(0xFFC5A052);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFF3D59B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
