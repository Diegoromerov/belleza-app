// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortfolioItemImpl _$$PortfolioItemImplFromJson(Map<String, dynamic> json) =>
    _$PortfolioItemImpl(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      likesCount: (json['likesCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PortfolioItemImplToJson(_$PortfolioItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'title': instance.title,
      'category': instance.category,
      'createdAt': instance.createdAt?.toIso8601String(),
      'likesCount': instance.likesCount,
    };
