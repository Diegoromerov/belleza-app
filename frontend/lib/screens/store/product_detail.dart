// lib/screens/store/product_detail.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>)? onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _increment() {
    final stock = widget.product['stock'] as int? ?? 10;
    if (_quantity < stock) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.product['nombre'] ?? widget.product['name'] ?? 'Producto Luxe';
    final double price = double.tryParse(widget.product['precio']?.toString() ?? '0') ?? 0.0;
    final String description = widget.product['descripcion'] ?? 'Fórmula clínica exclusiva con activos botánicos concentrados.';
    final String? imageUrl = widget.product['imagen_url'] ?? widget.product['image'];
    final String category = widget.product['tag_especialidad'] ?? widget.product['categoria'] ?? 'Ritual';
    final String sku = widget.product['sku'] ?? 'SKU-${widget.product['id']}';
    final List<String> ingredients = (widget.product['ingredientes'] as List?)?.cast<String>() ?? [
      'Ácido Hialurónico Multimolecular',
      'Aceite Orgánico de Maracuyá',
      'Péptidos de Cobre',
      'Niacinamida al 5%',
    ];

    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: LuxeColors.nude900, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN HERO DEL PRODUCTO
            Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: LuxeColors.nude100,
                borderRadius: BorderRadius.circular(LuxeSpacing.md),
                border: Border.all(color: LuxeColors.nude200, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpacing.md),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.spa_outlined, size: 64, color: LuxeColors.gold871),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU & CATEGORÍA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sku, style: LuxeTypography.monoSm),
                      LuxeBadge(label: category),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // TÍTULO EDITORIAL
                  Text(
                    name,
                    style: LuxeTypography.displayMd,
                  ),

                  const SizedBox(height: 12),

                  // PRECIO
                  Text(
                    '\$${price.toStringAsFixed(0)} COP',
                    style: LuxeTypography.monoMd.copyWith(fontSize: 22),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: LuxeColors.nude200),
                  const SizedBox(height: 16),

                  // DESCRIPCIÓN EN GOLDEN RATIO
                  Text(
                    description,
                    style: LuxeTypography.bodyMd,
                  ),

                  const SizedBox(height: 24),

                  // SECCIÓN DE INGREDIENTES CON BULLETS EN ORO 871
                  const Text(
                    'INGREDIENTES ACTIVOS',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: ingredients.map((ing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: LuxeColors.gold871,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(ing, style: LuxeTypography.bodySm.copyWith(color: LuxeColors.nude900)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // SELECTOR DE CANTIDAD CON TIPOGRAFÍA MONO
                  Row(
                    children: [
                      const Text(
                        'CANTIDAD:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: LuxeColors.nude700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: LuxeColors.nude200),
                          borderRadius: BorderRadius.circular(LuxeSpacing.md),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16, color: LuxeColors.nude900),
                              onPressed: _decrement,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('$_quantity', style: LuxeTypography.monoMd),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16, color: LuxeColors.nude900),
                              onPressed: _increment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN AGREGAR AL CARRITO
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: LuxeButton(
                      label: 'AGREGAR AL CARRITO',
                      icon: Icons.shopping_bag_outlined,
                      variant: LuxeButtonVariant.goldShimmer,
                      onPressed: () {
                        widget.onAddToCart?.call({
                          ...widget.product,
                          'quantity': _quantity,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Producto añadido a tu ritual GlowStore'),
                            backgroundColor: LuxeColors.nude900,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
