// lib/core/models/service_model.dart
// Modelo tipado para servicios del prestador

import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

@freezed
abstract class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    required bool isActive,
    int? bookingsCount,
    double? rating,
    String? imageUrl,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) => _$ServiceModelFromJson(json);

  factory ServiceModel.fromBackendJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      bookingsCount: int.tryParse(json['bookings_count']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}

extension ServiceModelExt on ServiceModel {
  String get formattedPrice => '\$${price.toStringAsFixed(0)} COP';
  String get formattedDuration => '$durationMinutes min';
  String get categoryDisplay => category?.isNotEmpty == true ? category! : 'Sin categoría';
}