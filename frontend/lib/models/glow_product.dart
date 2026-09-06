class GlowProduct {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? category;

  const GlowProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.category,
  });
}
