// lib/widgets/academy/progress_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../design/components/academy_luxe_components.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final int completedLessons;
  final int totalLessons;
  final int xpPoints;

  const ProgressCard({
    super.key,
    required this.title,
    required this.completedLessons,
    required this.totalLessons,
    required this.xpPoints,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    final int percentage = (progress * 100).round();

    return LuxeCard(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      backgroundColor: LuxeColors.nude100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TU PROGRESO CLÍNICO',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '+$xpPoints XP',
                style: LuxeTypography.monoSm.copyWith(
                  color: LuxeColors.gold871,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: LuxeTypography.displaySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedLessons de $totalLessons Lecciones',
                style: LuxeTypography.bodySm,
              ),
              Text(
                '$percentage%',
                style: LuxeTypography.monoMd,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LuxeProgressBar(value: progress, height: 8),
        ],
      ),
    );
  }
}
