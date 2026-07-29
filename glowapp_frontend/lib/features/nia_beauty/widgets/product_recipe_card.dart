import 'package:flutter/material.dart';
import '../../../models/glow_product.dart';
import '../../../shared/glow_tokens.dart';
import 'glow_glass_card.dart';

/// Widget de Tarjeta de Producto de Receta para GlowStore.
/// Cuenta con:
/// 1. Fondo glassmorphism cálido (`GlowGlassCard`).
/// 2. Etiqueta dorada ([GlowTokens.roseGold]) con el beneficio principal (ej: "[Hidratación profunda]").
/// 3. Botón de añadir al carrito en tono Terracota ([GlowTokens.terracota]).
class ProductRecipeCard extends StatelessWidget {
  final GlowProduct product;
  final bool isInCart;
  final VoidCallback? onAddToCart;

  const ProductRecipeCard({
    super.key,
    required this.product,
    this.isInCart = false,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GlowGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen / Icono de Producto con fondo cálido
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: GlowTokens.terracota.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    product.icon,
                    size: 48,
                    color: GlowTokens.terracota,
                  ),
                ),
                // Etiqueta Dorada de Beneficio Principal
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GlowTokens.roseGold,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: GlowTokens.roseGold.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '[${product.benefitTag}]',
                      style: const TextStyle(
                        fontFamily: GlowTokens.fontInter,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: GlowTokens.nightAndean,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Categoría del Producto
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              fontFamily: GlowTokens.fontJetBrainsMono,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: GlowTokens.terracota,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),

          // Título del Producto
          Text(
            product.title,
            style: const TextStyle(
              fontFamily: GlowTokens.fontPlayfairDisplay,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GlowTokens.nightAndean,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Precio del Producto
          Text(
            product.price,
            style: const TextStyle(
              fontFamily: GlowTokens.fontInter,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: GlowTokens.nightAndean,
            ),
          ),
          const SizedBox(height: 10),

          // Botón Añadir al Carrito (Terracota #C89D93)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: isInCart ? GlowTokens.emerald : GlowTokens.terracota,
                foregroundColor: GlowTokens.creamSilk,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInCart
                        ? Icons.check_circle_outline_rounded
                        : Icons.shopping_bag_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isInCart ? 'Añadido' : 'Añadir al Carrito',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
