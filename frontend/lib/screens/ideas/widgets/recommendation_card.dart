import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../widgets/glass_card.dart';

class RecommendationCard extends StatelessWidget {
  final String recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16.0,
      backgroundColor: const Color(0xFFF9F2ED).withOpacity(0.22),
      borderColor: const Color(0xFFE5D9D4).withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Recomendación Personalizada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: recommendation,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 15, height: 1.6),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              listBullet: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
