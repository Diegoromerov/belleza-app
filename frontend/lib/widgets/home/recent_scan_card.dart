// lib/widgets/home/recent_scan_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

class RecentScanCard extends StatelessWidget {
  final String dateText;
  final String subtono;
  final String estacion;
  final int hydrationPercent;
  final VoidCallback? onTap;

  const RecentScanCard({
    super.key,
    this.dateText = 'Hace 2 días',
    this.subtono = 'CÁLIDO',
    this.estacion = 'OTOÑO',
    this.hydrationPercent = 78,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LuxeCard(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ÚLTIMO DIAGNÓSTICO BIOMÉTRICO',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                dateText,
                style: LuxeTypography.monoSm,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUBTONO', style: TextStyle(fontSize: 10, color: LuxeColors.nude500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(subtono, style: LuxeTypography.monoMd),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTACIÓN', style: TextStyle(fontSize: 10, color: LuxeColors.nude500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(estacion, style: LuxeTypography.monoMd),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HIDRATACIÓN', style: TextStyle(fontSize: 10, color: LuxeColors.nude500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text('$hydrationPercent%', style: LuxeTypography.monoMd),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver Historial',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LuxeColors.gold871),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: LuxeColors.gold871),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
