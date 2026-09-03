// lib/core/models/provider_profile_model.dart
// Modelo tipado para perfil del prestador

import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider_profile_model.freezed.dart';
part 'provider_profile_model.g.dart';

@freezed
abstract class ProviderProfile with _$ProviderProfile {
  const factory ProviderProfile({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
    String? coverUrl,
    String? businessName,
    String? description,
    String? specialty,
    required String verificationStatus,
    required bool isActive,
    required double ratingAvg,
    required int ratingCount,
    required int activeStartHour,
    required int activeEndHour,
    required Map<String, dynamic> weeklySchedule,
    required double coverageRadius,
    required int experienceYears,
    String? bankName,
    String? accountNumber,
    String? accountType,
    required String withdrawalModel,
    DateTime? nextWithdrawalDate,
  }) = _ProviderProfile;

  factory ProviderProfile.fromJson(Map<String, dynamic> json) => _$ProviderProfileFromJson(json);

  factory ProviderProfile.fromBackendJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      businessName: json['business_name']?.toString(),
      description: json['description']?.toString(),
      specialty: json['specialty']?.toString(),
      verificationStatus: (json['estatus_verificacion']?.toString() ?? 'PENDIENTE').toUpperCase(),
      isActive: json['is_active'] as bool? ?? true,
      ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0,
      ratingCount: int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
      activeStartHour: int.tryParse(json['active_start_hour']?.toString() ?? '6') ?? 6,
      activeEndHour: int.tryParse(json['active_end_hour']?.toString() ?? '20') ?? 20,
      weeklySchedule: Map<String, dynamic>.from(json['weekly_schedule'] ?? {}),
      coverageRadius: double.tryParse(json['coverage_radius']?.toString() ?? '10') ?? 10,
      experienceYears: int.tryParse(json['experience_years']?.toString() ?? '3') ?? 3,
      bankName: json['bank_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      accountType: json['account_type']?.toString(),
      withdrawalModel: (json['withdrawal_model']?.toString() ?? 'DEMANDA').toUpperCase(),
      nextWithdrawalDate: json['next_withdrawal_date'] != null
          ? DateTime.tryParse(json['next_withdrawal_date'].toString())
          : null,
    );
  }
}

extension ProviderProfileExt on ProviderProfile {
  bool get isVerified => verificationStatus == 'APROBADO';
  bool get isPending => verificationStatus == 'PENDIENTE';
  bool get isRejected => verificationStatus == 'RECHAZADO';

  String get displayName => businessName?.isNotEmpty == true ? businessName! : fullName;
  String get initials => displayName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
}