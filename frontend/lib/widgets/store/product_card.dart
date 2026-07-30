// lib/widgets/store/product_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onQuickView;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onQuickView,
  });

  @override
  Widget build(BuildContext context) {
    final String name = product['nombre'] ?? product['name'] ?? 'Producto Luxe';
    final double price = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
    final String? imageUrl = product['imagen_url'] ?? product['image'];
    final String category = product['tag_especialidad'] ?? product['categoria'] ?? 'GlowStore';
    final bool isPremium = product['is_premium'] ?? false;
    final String sku = product['sku'] ?? 'SKU-${product['id']}';

    return LuxeCard(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN Y BADGES
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpacing.md),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: LuxeColors.nude200,
                            child: const Icon(Icons.spa_outlined, color: LuxeColors.gold871, size: 32),
                          ),
                        )
                      : Container(
                          color: LuxeColors.nude200,
                          child: const Icon(Icons.spa_outlined, color: LuxeColors.gold871, size: 32),
                        ),
                ),
              ),

              // BADGES
              Positioned(
                top: 6,
                left: 6,
                child: Row(
                  children: [
                    if (isPremium) ...[
                      const LuxeBadge(
                        label: 'PREMIUM',
                        backgroundColor: LuxeColors.gold871,
                        textColor: LuxeColors.nude900,
                      ),
                      const SizedBox(width: 4),
                    ],
                    LuxeBadge(label: category),
                  ],
                ),
              ),

              // BOTÓN DE VISTA RÁPIDA
              if (onQuickView != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: LuxeColors.nude100.withOpacity(0.85),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.visibility_outlined, size: 16, color: LuxeColors.nude900),
                      onPressed: onQuickView,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: LuxeSpacing.md),

          // CÓDIGO SKU
          Text(
            sku,
            style: LuxeTypography.monoSm,
          ),

          const SizedBox(height: 4),

          // TÍTULO DEL PRODUCTO
          Text(
            name,
            style: LuxeTypography.displaySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),
          const SizedBox(height: LuxeSpacing.md),

          // PRECIO Y BOTÓN AGREGAR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAlignment.center,
            children: [
              Text(
                '\$${price.toStringAsFixed(0)}',
                style: LuxeTypography.monoMd,
              ),
              LuxeButton(
                label: 'Agregar',
                icon: Icons.shopping_bag_outlined,
                variant: LuxeButtonVariant.goldShimmer,
                onPressed: onAddToCart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
