// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: json['id'] as String,
      clientName: json['clientName'] as String,
      clientId: json['clientId'] as String,
      serviceName: json['serviceName'] as String,
      serviceId: json['serviceId'] as String,
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      serviceAddress: json['serviceAddress'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      providerNetAmount: (json['providerNetAmount'] as num?)?.toDouble(),
      platformCommission: (json['platformCommission'] as num?)?.toDouble(),
      stateTax: (json['stateTax'] as num?)?.toDouble(),
      wompiReference: json['wompiReference'] as String?,
      nequiAccount: json['nequiAccount'] as String?,
      payoutStatus: json['payoutStatus'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      clientAvatar: json['clientAvatar'] as String?,
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientName': instance.clientName,
      'clientId': instance.clientId,
      'serviceName': instance.serviceName,
      'serviceId': instance.serviceId,
      'status': instance.status,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
      'serviceAddress': instance.serviceAddress,
      'totalAmount': instance.totalAmount,
      'providerNetAmount': instance.providerNetAmount,
      'platformCommission': instance.platformCommission,
      'stateTax': instance.stateTax,
      'wompiReference': instance.wompiReference,
      'nequiAccount': instance.nequiAccount,
      'payoutStatus': instance.payoutStatus,
      'rating': instance.rating,
      'clientAvatar': instance.clientAvatar,
    };
