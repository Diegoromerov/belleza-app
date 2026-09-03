// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProviderProfileImpl _$$ProviderProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ProviderProfileImpl(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      businessName: json['businessName'] as String?,
      description: json['description'] as String?,
      specialty: json['specialty'] as String?,
      verificationStatus: json['verificationStatus'] as String,
      isActive: json['isActive'] as bool,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
      ratingCount: (json['ratingCount'] as num).toInt(),
      activeStartHour: (json['activeStartHour'] as num).toInt(),
      activeEndHour: (json['activeEndHour'] as num).toInt(),
      weeklySchedule: json['weeklySchedule'] as Map<String, dynamic>,
      coverageRadius: (json['coverageRadius'] as num).toDouble(),
      experienceYears: (json['experienceYears'] as num).toInt(),
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountType: json['accountType'] as String?,
      withdrawalModel: json['withdrawalModel'] as String,
      nextWithdrawalDate: json['nextWithdrawalDate'] == null
          ? null
          : DateTime.parse(json['nextWithdrawalDate'] as String),
    );

Map<String, dynamic> _$$ProviderProfileImplToJson(
        _$ProviderProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'coverUrl': instance.coverUrl,
      'businessName': instance.businessName,
      'description': instance.description,
      'specialty': instance.specialty,
      'verificationStatus': instance.verificationStatus,
      'isActive': instance.isActive,
      'ratingAvg': instance.ratingAvg,
      'ratingCount': instance.ratingCount,
      'activeStartHour': instance.activeStartHour,
      'activeEndHour': instance.activeEndHour,
      'weeklySchedule': instance.weeklySchedule,
      'coverageRadius': instance.coverageRadius,
      'experienceYears': instance.experienceYears,
      'bankName': instance.bankName,
      'accountNumber': instance.accountNumber,
      'accountType': instance.accountType,
      'withdrawalModel': instance.withdrawalModel,
      'nextWithdrawalDate': instance.nextWithdrawalDate?.toIso8601String(),
    };
