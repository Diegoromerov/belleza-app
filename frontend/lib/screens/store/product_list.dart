// lib/screens/store/product_list.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../widgets/store/product_card.dart';
import 'product_detail.dart';

class ProductListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>)? onAddToCart;

  const ProductListScreen({
    super.key,
    required this.products,
    this.onAddToCart,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategory = 'Todos';

  List<String> get _categories => ['Todos', 'Cabello', 'Uñas', 'Maquillaje', 'Estética', 'Skincare'];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      if (_selectedCategory == 'Todos') return true;
      final cat = (p['tag_especialidad'] ?? p['categoria'] ?? '').toString();
      return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'GLOWSTORE LUXE',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // FILTRO DE CATEGORÍAS EN CHIPS LUXE
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      selectedColor: LuxeColors.gold871,
                      backgroundColor: LuxeColors.nude100,
                      labelStyle: TextStyle(
                        color: isSelected ? LuxeColors.nude900 : LuxeColors.nude700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? LuxeColors.gold871 : LuxeColors.nude200,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // GRID DE PRODUCTOS CON ESPACIADO LUXE (LuxeSpacing.lg = 10.5px)
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay productos en esta categoría',
                        style: LuxeTypography.bodyMd,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: LuxeSpacing.lg,
                        mainAxisSpacing: LuxeSpacing.lg,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  onAddToCart: widget.onAddToCart,
                                ),
                              ),
                            );
                          },
                          onAddToCart: () => widget.onAddToCart?.call(product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
