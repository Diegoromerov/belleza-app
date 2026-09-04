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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFFAF5ED),
              border: Border.all(color: const Color(0xFFEADBCE), width: 0.8),
            ),
            child: product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC5A052)),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.spa_outlined, color: Color(0xFFC5A052), size: 22),
                  )
                : const Icon(Icons.spa_outlined, color: Color(0xFFC5A052), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F1A15)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.brand,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                if (product.compatible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF3D59B), width: 0.8),
                    ),
                    child: const Text(
                      'Fórmula compatible',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8B6B23),
                        fontWeight: FontWeight.w600,
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
