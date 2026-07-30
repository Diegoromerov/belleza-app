import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

/// Tarjeta de Métricas clave de Proveedor (Ingresos, Citas, Rating)
class ProviderMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  const ProviderMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      decoration: BoxDecoration(
        color: LuxeColors.nude100,
        borderRadius: BorderRadius.circular(LuxeSpacing.md),
        border: const Border(
          left: BorderSide(color: LuxeColors.gold871, width: 4.0),
          top: BorderSide(color: LuxeColors.nude200, width: 0.5),
          right: BorderSide(color: LuxeColors.nude200, width: 0.5),
          bottom: BorderSide(color: LuxeColors.nude200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, color: LuxeColors.gold871, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: LuxeTypography.monoMd.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: LuxeTypography.bodySm),
          ],
        ],
      ),
    );
  }
}

/// Tile de Cita de Proveedor con Badges de Estado
class ProviderAppointmentTile extends StatelessWidget {
  final String clientName;
  final String serviceName;
  final String timeText;
  final String status; // 'CONFIRMADA', 'COMPLETADA', 'CANCELADA'
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const ProviderAppointmentTile({
    super.key,
    required this.clientName,
    required this.serviceName,
    required this.timeText,
    this.status = 'CONFIRMADA',
    this.avatarUrl,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;

    switch (status.toUpperCase()) {
      case 'COMPLETADA':
        badgeBg = LuxeColors.gold871.withOpacity(0.15);
        badgeFg = LuxeColors.goldDark;
        break;
      case 'CANCELADA':
        badgeBg = const Color(0xFFFFEBEE);
        badgeFg = const Color(0xFFB00020);
        break;
      case 'CONFIRMADA':
      default:
        badgeBg = LuxeColors.nude200;
        badgeFg = LuxeColors.nude900;
        break;
    }

    return Container(
      minHeight: 80,
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: LuxeColors.nude100,
        borderRadius: BorderRadius.circular(LuxeSpacing.md),
        border: Border.all(color: LuxeColors.nude200, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(LuxeSpacing.lg),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: LuxeColors.nude200,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? const Icon(Icons.person_outline, color: LuxeColors.gold871)
              : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                clientName,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: LuxeColors.nude900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(timeText, style: LuxeTypography.monoSm),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(serviceName, style: LuxeTypography.bodySm.copyWith(color: LuxeColors.nude700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LuxeBadge(label: status, backgroundColor: badgeBg, textColor: badgeFg),
                if (onAccept != null && onReject != null)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: LuxeColors.nude500, size: 20),
                        onPressed: onReject,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: LuxeColors.gold871, size: 20),
                        onPressed: onAccept,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
