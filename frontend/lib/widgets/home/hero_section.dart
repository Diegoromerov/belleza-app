// lib/widgets/home/hero_section.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../core/theme/belleza_luxe_gradients.dart';
import '../../design/components/luxe_components.dart';

class HeroSection extends StatelessWidget {
  final String userName;
  final String avatarUrl;
  final double skinScore;
  final String skinStatus;
  final VoidCallback? onProfileTap;

  const HeroSection({
    super.key,
    required this.userName,
    this.avatarUrl = '',
    this.skinScore = 88.5,
    this.skinStatus = 'Luminosidad Óptima',
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      decoration: BoxDecoration(
        gradient: LuxeGradients.goldShimmer,
        borderRadius: BorderRadius.circular(LuxeSpacing.md),
        border: Border.all(color: LuxeColors.nude200, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // AVATAR CON BORDE DORADO SUTIL
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxeColors.gold871, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: LuxeColors.nude200,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person_outline, color: LuxeColors.gold871, size: 28)
                        : null,
                  ),
                ),
              ),

              const SizedBox(width: LuxeSpacing.lg),

              // BIENVENIDA EDITORIAL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $userName',
                      style: LuxeTypography.displayMd,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RITUAL DE BELLEZA PERSONALIZADO',
                      style: LuxeTypography.monoSm,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: LuxeColors.nude200, height: 1),
          const SizedBox(height: 16),

          // RESUMEN RÁPIDO DE ESTADO DE PIEL Y RADARCHART MINIATURA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTADO DE PIEL AURA',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skinStatus,
                    style: LuxeTypography.bodySm,
                  ),
                ],
              ),

              // SCORE EN MONO MD
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: LuxeColors.nude100,
                      shape: BoxShape.circle,
                      border: Border.all(color: LuxeColors.gold871, width: 1),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 16, color: LuxeColors.gold871),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${skinScore.toStringAsFixed(1)} pts',
                    style: LuxeTypography.monoMd,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
