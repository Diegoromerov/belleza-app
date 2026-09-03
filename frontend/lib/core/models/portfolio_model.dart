// lib/core/models/portfolio_model.dart
// Modelo tipado para portafolio del prestador

import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_model.freezed.dart';
part 'portfolio_model.g.dart';

@freezed
abstract class PortfolioItem with _$PortfolioItem {
  const factory PortfolioItem({
    required String id,
    required String imageUrl,
    required String title,
    required String category,
    DateTime? createdAt,
    int? likesCount,
  }) = _PortfolioItem;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) => _$PortfolioItemFromJson(json);

  factory PortfolioItem.fromBackendJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Cabello',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
    );
  }
}

extension PortfolioItemExt on PortfolioItem {
  String get normalizedImageUrl {
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('data:')) return imageUrl;
    // Para URLs relativas del backend
    return imageUrl;
  }
}