import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/biometric_result.dart';
import '../../../widgets/glass_card.dart';

class ProductCard extends StatelessWidget {
  final ProductDetail product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cardContent = GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 12.0,
      padding: const EdgeInsets.all(8.0),
      backgroundColor: const Color(0xFFF9F2ED).withValues(alpha: 0.18),
      borderColor: const Color(0xFFE5D9D4).withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.photo),
                  )
                : const Icon(Icons.photo, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.brand,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                if (product.compatible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ Compatible con tu perfil',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF791F1F).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⚠ Revisar antes de usar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF791F1F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (product.price.isNotEmpty)
            Text(
              product.price,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );

    final widgetWithOpacity = Opacity(
      opacity: product.compatible ? 1.0 : 0.7,
      child: cardContent,
    );

    if (product.compatibilityReason.isNotEmpty) {
      return Tooltip(
        message: product.compatibilityReason,
        child: widgetWithOpacity,
      );
    }

    return widgetWithOpacity;
  }
}
