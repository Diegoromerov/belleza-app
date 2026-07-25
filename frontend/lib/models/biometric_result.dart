// frontend/lib/models/biometric_result.dart

class BiometricResult {
  final String? profileId;
  final FaceScores? face;
  final HandsDiagnosis? hands;
  final String? recommendation;
  final List<Product>? products;

  BiometricResult({
    this.profileId,
    this.face,
    this.hands,
    this.recommendation,
    this.products,
  });

  factory BiometricResult.fromJson(Map<String, dynamic> json) {
    final data = json['results'] is Map<String, dynamic>
        ? json['results'] as Map<String, dynamic>
        : json;

    return BiometricResult(
      profileId: json['profileId']?.toString() ?? data['profileId']?.toString(),
      face: data['face'] is Map<String, dynamic> ? FaceScores.fromJson(data['face']) : null,
      hands: data['hands'] is Map<String, dynamic> ? HandsDiagnosis.fromJson(data['hands']) : null,
      recommendation: (data['recommendation'] ?? json['recommendation'])?.toString(),
      products: data['products'] is List
          ? (data['products'] as List).whereType<Map<String, dynamic>>().map((p) => Product.fromJson(p)).toList()
          : null,
    );
  }
}

class FaceScores {
  final int hydration;
  final int wrinkles;
  final int spots;
  final int pores;
  final String subtono;
  final int bioAge;

  FaceScores({
    required this.hydration,
    required this.wrinkles,
    required this.spots,
    required this.pores,
    required this.subtono,
    required this.bioAge,
  });

  factory FaceScores.fromJson(Map<String, dynamic> json) {
    return FaceScores(
      hydration: (json['hydration'] is num) ? (json['hydration'] as num).toInt() : (int.tryParse(json['hydration']?.toString() ?? '') ?? 0),
      wrinkles: (json['wrinkles'] is num) ? (json['wrinkles'] as num).toInt() : (int.tryParse(json['wrinkles']?.toString() ?? '') ?? 0),
      spots: (json['spots'] is num) ? (json['spots'] as num).toInt() : (int.tryParse(json['spots']?.toString() ?? '') ?? 0),
      pores: (json['pores'] is num) ? (json['pores'] as num).toInt() : (int.tryParse(json['pores']?.toString() ?? '') ?? 0),
      subtono: json['subtono']?.toString() ?? 'neutro',
      bioAge: (json['bioAge'] is num) ? (json['bioAge'] as num).toInt() : (int.tryParse(json['bioAge']?.toString() ?? '') ?? 30),
    );
  }
}

class HandsDiagnosis {
  final String manchasSolares;
  final String sequedad;
  final String cuticulas;
  final String unas;
  final int edadAparente;

  HandsDiagnosis({
    required this.manchasSolares,
    required this.sequedad,
    required this.cuticulas,
    required this.unas,
    required this.edadAparente,
  });

  factory HandsDiagnosis.fromJson(Map<String, dynamic> json) {
    final rawEdad = json['edadAparente'] ?? json['edad_aparente'];
    return HandsDiagnosis(
      manchasSolares: (json['manchasSolares'] ?? json['manchas_solares'])?.toString() ?? 'leve',
      sequedad: json['sequedad']?.toString() ?? 'leve',
      cuticulas: json['cuticulas']?.toString() ?? 'sanas',
      unas: (json['unas'] ?? json['uñas'])?.toString() ?? 'sanas',
      edadAparente: (rawEdad is num) ? rawEdad.toInt() : (int.tryParse(rawEdad?.toString() ?? '') ?? 30),
    );
  }
}

class Product {
  final String name;
  final String brand;
  final String imageUrl;
  final String price;
  final bool compatible;

  Product({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.price,
    this.compatible = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] ?? 'Producto',
      brand: json['brand'] ?? 'Marca',
      imageUrl: json['image'] ?? '',
      price: json['price'] ?? '\$',
      compatible: json['compatible'] ?? false,
    );
  }
}

class ProductDetail {
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredients;
  final String categories;
  final String price;
  final bool compatible;
  final String compatibilityReason;

  ProductDetail({
    required this.barcode,
    required this.name,
    required this.brand,
    this.imageUrl = '',
    this.ingredients = '',
    this.categories = '',
    this.price = '',
    this.compatible = false,
    this.compatibilityReason = '',
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? 'Producto',
      brand: json['brand'] ?? 'Marca',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      ingredients: json['ingredients'] ?? '',
      categories: json['categories'] ?? '',
      price: json['price'] ?? '',
      compatible: json['compatible'] ?? false,
      compatibilityReason: json['compatibilityReason'] ?? '',
    );
  }
}
