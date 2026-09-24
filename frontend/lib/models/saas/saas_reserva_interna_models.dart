// frontend/lib/models/saas/saas_reserva_interna_models.dart
// NODO-07 / SCR-11: Reserva Interna Models & DTOs

import 'package:flutter/foundation.dart';

@immutable
class SaasAvailabilitySlot {
  final String startTime; // "09:00"
  final String endTime;   // "09:45"
  final List<String> availableMemberships;

  const SaasAvailabilitySlot({
    required this.startTime,
    required this.endTime,
    required this.availableMemberships,
  });

  factory SaasAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return SaasAvailabilitySlot(
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      availableMemberships: (json['available_memberships'] as List<dynamic>? ?? [])
          .map((m) => m.toString())
          .toList(),
    );
  }
}

@immutable
class SaasAvailabilityProjection {
  final String establishmentId;
  final String serviceOfferId;
  final String targetDate;
  final int serviceDurationMinutes;
  final int stepMinutes;
  final String projectionMode;
  final List<SaasAvailabilitySlot> slots;

  const SaasAvailabilityProjection({
    required this.establishmentId,
    required this.serviceOfferId,
    required this.targetDate,
    required this.serviceDurationMinutes,
    required this.stepMinutes,
    required this.projectionMode,
    required this.slots,
  });

  factory SaasAvailabilityProjection.fromJson(Map<String, dynamic> json) {
    return SaasAvailabilityProjection(
      establishmentId: json['establishment_id']?.toString() ?? '',
      serviceOfferId: json['service_offer_id']?.toString() ?? '',
      targetDate: json['target_date']?.toString() ?? '',
      serviceDurationMinutes: json['service_duration_minutes'] is int
          ? json['service_duration_minutes'] as int
          : int.tryParse(json['service_duration_minutes']?.toString() ?? '0') ?? 0,
      stepMinutes: json['step_minutes'] is int
          ? json['step_minutes'] as int
          : int.tryParse(json['step_minutes']?.toString() ?? '15') ?? 15,
      projectionMode: json['projection_mode']?.toString() ?? 'AGGREGATED',
      slots: (json['slots'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => SaasAvailabilitySlot.fromJson(s))
          .toList(),
    );
  }
}

class CreateAppointmentPayload {
  final String serviceOfferId;
  final String membershipId;
  final String scheduledAt;
  final int? customerUserId;
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;

  CreateAppointmentPayload({
    required this.serviceOfferId,
    required this.membershipId,
    required this.scheduledAt,
    this.customerUserId,
    this.guestName,
    this.guestPhone,
    this.guestEmail,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'service_offer_id': serviceOfferId,
      'membership_id': membershipId,
      'scheduled_at': scheduledAt,
    };
    if (customerUserId != null) {
      map['customer_user_id'] = customerUserId;
    } else {
      map['guest_name'] = guestName;
      map['guest_phone'] = guestPhone;
      if (guestEmail != null && guestEmail!.trim().isNotEmpty) {
        map['guest_email'] = guestEmail!.trim();
      }
    }
    return map;
  }
}

class StaffMemberOption {
  final String membershipId;
  final String name;

  const StaffMemberOption({
    required this.membershipId,
    required this.name,
  });
}
