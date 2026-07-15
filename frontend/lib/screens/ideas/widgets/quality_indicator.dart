// frontend/lib/screens/ideas/widgets/quality_indicator.dart
import 'package:flutter/material.dart';

class QualityIndicator extends StatelessWidget {
  final double quality;

  const QualityIndicator({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    final color = _getQualityColor(quality);
    final text = quality > 80
        ? '✅ Excelente'
        : quality > 50
            ? '⚠️ Aceptable'
            : '❌ Mejora la posición';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(double quality) {
    if (quality > 80) return Colors.green;
    if (quality > 50) return Colors.orange;
    return Colors.red;
  }
}
