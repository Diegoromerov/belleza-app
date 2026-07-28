import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../widgets/glass_card.dart';

class RecommendationCard extends StatelessWidget {
  final String recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16.0,
      backgroundColor: const Color(0xFFF9F2ED).withValues(alpha: 0.22),
      borderColor: const Color(0xFFE5D9D4).withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECOMENDACIÓN DE AURA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: Color(0xFF993C1D),
            ),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: recommendation,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 15,
                height: 1.6,
                fontFamily: 'serif',
              ),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              listBullet: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
