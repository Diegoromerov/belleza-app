// lib/widgets/provider/service_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String title = service['nombre'] ?? service['name'] ?? 'Servicio Profesional';
    final double price = double.tryParse(service['precio']?.toString() ?? '0') ?? 0.0;
    final String duration = service['duracion'] ?? '45 min';
    final String? imageUrl = service['imagen_url'] ?? service['image'];

    return LuxeCard(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      onTap: onTap,
      child: Row(
        children: [
          // IMAGEN CUADRADA CON BORDER RADIUS MD (6.5px)
          ClipRRect(
            borderRadius: BorderRadius.circular(LuxeSpacing.md),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: LuxeColors.nude200,
                      child: const Icon(Icons.content_cut, color: LuxeColors.gold871, size: 28),
                    ),
            ),
          ),

          const SizedBox(width: LuxeSpacing.lg),

          // DETALLES DEL SERVICIO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Duración: $duration',
                  style: LuxeTypography.bodySm,
                ),
              ],
            ),
          ),

          // PRECIO EN MONO DORADO (GOLD871)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(0)}',
                style: LuxeTypography.monoMd.copyWith(color: LuxeColors.gold871),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: LuxeColors.nude500),
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
