// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceModelImpl _$$ServiceModelImplFromJson(Map<String, dynamic> json) =>
    _$ServiceModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      description: json['description'] as String?,
      category: json['category'] as String?,
      isActive: json['isActive'] as bool,
      bookingsCount: (json['bookingsCount'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$ServiceModelImplToJson(_$ServiceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'durationMinutes': instance.durationMinutes,
      'description': instance.description,
      'category': instance.category,
      'isActive': instance.isActive,
      'bookingsCount': instance.bookingsCount,
      'rating': instance.rating,
      'imageUrl': instance.imageUrl,
    };
