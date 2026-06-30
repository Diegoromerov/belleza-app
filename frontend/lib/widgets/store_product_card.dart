// frontend/lib/widgets/store_product_card.dart
import 'package:flutter/material.dart';
import '../shared/theme.dart';

class StoreProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String? bookingId;
  final VoidCallback onQuickViewPressed;
  final Function(Map<String, dynamic> prod) onAddToCart;

  const StoreProductCard({
    super.key,
    required this.product,
    this.bookingId,
    required this.onQuickViewPressed,
    required this.onAddToCart,
  });

  String _formatCOP(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} COP';
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      width: double.infinity,
      height: double.infinity,
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
    final stock = product['stock'] as int? ?? 0;
    final imageUrl = product['imagen_url']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con hover zoom y Quick View
          Expanded(
            child: Stack(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
                // Botón Vista Rápida
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Opacity(
                    opacity: 0.9,
                    child: ElevatedButton(
                      onPressed: onQuickViewPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.text,
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Vista Rápida', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                // Badge de Visibilidad del Producto
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (product['tipo_visibilidad'] == 'INSUMO_PRESTADOR')
                          ? const Color(0xFFDC2626) // Rojo elegante para Insumos
                          : const Color(0xFF059669), // Verde esmeralda para Público
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (product['tipo_visibilidad'] == 'INSUMO_PRESTADOR')
                          ? 'PROFESIONAL'
                          : 'PÚBLICO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['tag_especialidad']?.toString().toUpperCase() ?? 'COSMÉTICOS',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['nombre']?.toString() ?? 'Producto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                // Calificación Ficticia (Shopify Stars)
                Row(
                  children: List.generate(5, (starIdx) {
                    return const Icon(Icons.star, color: Colors.amber, size: 12);
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        if (bookingId != null && product.containsKey('precio_con_reserva')) {
                          final originalPrice = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
                          final discountPrice = double.tryParse(product['precio_con_reserva']?.toString() ?? '0') ?? 0.0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCOP(originalPrice),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                _formatCOP(discountPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          _formatCOP(price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        );
                      }
                    ),
                    if (stock > 0)
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primary, size: 20),
                        onPressed: () => onAddToCart(product),
                      )
                    else
                      const Text(
                        'Agotado',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
