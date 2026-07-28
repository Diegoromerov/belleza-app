// frontend/lib/screens/ideas/widgets/score_card.dart
import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const ScoreCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon = Icons.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}
