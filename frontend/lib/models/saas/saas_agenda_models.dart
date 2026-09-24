// frontend/lib/models/saas/saas_agenda_models.dart
// NODO-07 / SCR-10: Agenda Operativa Models & DTOs

import 'package:flutter/material.dart';

/// Estados canónicos de cita en NODO-06
enum SaasAppointmentStatus {
  scheduled,
  confirmed,
  checkedIn,
  inService,
  completed,
  cancelled,
  noShow;

  static SaasAppointmentStatus fromString(String? val) {
    if (val == null) return SaasAppointmentStatus.scheduled;
    switch (val.toUpperCase().trim()) {
      case 'SCHEDULED':
        return SaasAppointmentStatus.scheduled;
      case 'CONFIRMED':
        return SaasAppointmentStatus.confirmed;
      case 'CHECKED_IN':
        return SaasAppointmentStatus.checkedIn;
      case 'IN_SERVICE':
        return SaasAppointmentStatus.inService;
      case 'COMPLETED':
        return SaasAppointmentStatus.completed;
      case 'CANCELLED':
        return SaasAppointmentStatus.cancelled;
      case 'NO_SHOW':
        return SaasAppointmentStatus.noShow;
      default:
        return SaasAppointmentStatus.scheduled;
    }
  }

  String toBackendString() {
    switch (this) {
      case SaasAppointmentStatus.scheduled:
        return 'SCHEDULED';
      case SaasAppointmentStatus.confirmed:
        return 'CONFIRMED';
      case SaasAppointmentStatus.checkedIn:
        return 'CHECKED_IN';
      case SaasAppointmentStatus.inService:
        return 'IN_SERVICE';
      case SaasAppointmentStatus.completed:
        return 'COMPLETED';
      case SaasAppointmentStatus.cancelled:
        return 'CANCELLED';
      case SaasAppointmentStatus.noShow:
        return 'NO_SHOW';
    }
  }

  String get label {
    switch (this) {
      case SaasAppointmentStatus.scheduled:
        return 'Agendada';
      case SaasAppointmentStatus.confirmed:
        return 'Confirmada';
      case SaasAppointmentStatus.checkedIn:
        return 'En Recepción';
      case SaasAppointmentStatus.inService:
        return 'En Atención';
      case SaasAppointmentStatus.completed:
        return 'Finalizada';
      case SaasAppointmentStatus.cancelled:
        return 'Cancelada';
      case SaasAppointmentStatus.noShow:
        return 'No Asistió';
    }
  }

  Color get color {
    switch (this) {
      case SaasAppointmentStatus.scheduled:
        return const Color(0xFF1976D2); // Azul
      case SaasAppointmentStatus.confirmed:
        return const Color(0xFF388E3C); // Verde esmeralda
      case SaasAppointmentStatus.checkedIn:
        return const Color(0xFFF57C00); // Ámbar / Naranja
      case SaasAppointmentStatus.inService:
        return const Color(0xFF7B1FA2); // Púrpura activo
      case SaasAppointmentStatus.completed:
        return const Color(0xFF455A64); // Gris azulado
      case SaasAppointmentStatus.cancelled:
        return const Color(0xFFD32F2F); // Rojo
      case SaasAppointmentStatus.noShow:
        return const Color(0xFFE64A19); // Naranja oscuro
    }
  }

  bool get isTerminal =>
      this == SaasAppointmentStatus.completed ||
      this == SaasAppointmentStatus.cancelled ||
      this == SaasAppointmentStatus.noShow;

  List<SaasAppointmentStatus> get allowedTransitions {
    switch (this) {
      case SaasAppointmentStatus.scheduled:
        return [
          SaasAppointmentStatus.confirmed,
          SaasAppointmentStatus.checkedIn,
          SaasAppointmentStatus.cancelled,
          SaasAppointmentStatus.noShow,
        ];
      case SaasAppointmentStatus.confirmed:
        return [
          SaasAppointmentStatus.checkedIn,
          SaasAppointmentStatus.cancelled,
          SaasAppointmentStatus.noShow,
        ];
      case SaasAppointmentStatus.checkedIn:
        return [
          SaasAppointmentStatus.inService,
          SaasAppointmentStatus.cancelled,
        ];
      case SaasAppointmentStatus.inService:
        return [
          SaasAppointmentStatus.completed,
          SaasAppointmentStatus.cancelled,
        ];
      case SaasAppointmentStatus.completed:
      case SaasAppointmentStatus.cancelled:
      case SaasAppointmentStatus.noShow:
        return [];
    }
  }
}

class SaasAgendaShift {
  final String startTime;
  final String endTime;

  const SaasAgendaShift({
    required this.startTime,
    required this.endTime,
  });

  factory SaasAgendaShift.fromJson(Map<String, dynamic> json) {
    return SaasAgendaShift(
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}

class SaasAgendaAppointment {
  final String id;
  final String startTime;
  final String endTime;
  final String serviceName;
  final String clientName;
  final SaasAppointmentStatus status;

  const SaasAgendaAppointment({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.serviceName,
    required this.clientName,
    required this.status,
  });

  factory SaasAgendaAppointment.fromJson(Map<String, dynamic> json) {
    return SaasAgendaAppointment(
      id: json['id']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      status: SaasAppointmentStatus.fromString(json['status']?.toString()),
    );
  }
}

class SaasAgendaMarketplaceBooking {
  final int id;
  final String startTime;
  final String endTime;
  final String status;

  const SaasAgendaMarketplaceBooking({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory SaasAgendaMarketplaceBooking.fromJson(Map<String, dynamic> json) {
    return SaasAgendaMarketplaceBooking(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class SaasAgendaProfessional {
  final String membershipId;
  final int userId;
  final String name;
  final List<SaasAgendaShift> shifts;
  final List<SaasAgendaAppointment> appointments;
  final List<SaasAgendaMarketplaceBooking> marketplaceBookings;

  const SaasAgendaProfessional({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.shifts,
    required this.appointments,
    required this.marketplaceBookings,
  });

  factory SaasAgendaProfessional.fromJson(Map<String, dynamic> json) {
    return SaasAgendaProfessional(
      membershipId: json['membership_id']?.toString() ?? '',
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      shifts: (json['shifts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => SaasAgendaShift.fromJson(s))
          .toList(),
      appointments: (json['appointments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => SaasAgendaAppointment.fromJson(a))
          .toList(),
      marketplaceBookings: (json['marketplace_bookings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((b) => SaasAgendaMarketplaceBooking.fromJson(b))
          .toList(),
    );
  }
}

class SaasAgendaProjection {
  final String establishmentId;
  final String targetDate;
  final String timezone;
  final List<SaasAgendaProfessional> professionals;

  const SaasAgendaProjection({
    required this.establishmentId,
    required this.targetDate,
    required this.timezone,
    required this.professionals,
  });

  factory SaasAgendaProjection.fromJson(Map<String, dynamic> json) {
    return SaasAgendaProjection(
      establishmentId: json['establishment_id']?.toString() ?? '',
      targetDate: json['target_date']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'America/Bogota',
      professionals: (json['professionals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((p) => SaasAgendaProfessional.fromJson(p))
          .toList(),
    );
  }
}

class SaasAppointmentDetailModel {
  final String id;
  final int tenantId;
  final String establishmentId;
  final String serviceOfferId;
  final String membershipId;
  final String clientMode;
  final int? customerUserId;
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;
  final String scheduledAt;
  final String endTime;
  final String serviceNameSnapshot;
  final int durationMinutesSnapshot;
  final double priceSnapshot;
  final SaasAppointmentStatus status;
  final String? cancellationReason;
  final String createdAt;
  final String updatedAt;

  const SaasAppointmentDetailModel({
    required this.id,
    required this.tenantId,
    required this.establishmentId,
    required this.serviceOfferId,
    required this.membershipId,
    required this.clientMode,
    this.customerUserId,
    this.guestName,
    this.guestPhone,
    this.guestEmail,
    required this.scheduledAt,
    required this.endTime,
    required this.serviceNameSnapshot,
    required this.durationMinutesSnapshot,
    required this.priceSnapshot,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaasAppointmentDetailModel.fromJson(Map<String, dynamic> json) {
    return SaasAppointmentDetailModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id'] is int
          ? json['tenant_id'] as int
          : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      establishmentId: json['establishment_id']?.toString() ?? '',
      serviceOfferId: json['service_offer_id']?.toString() ?? '',
      membershipId: json['membership_id']?.toString() ?? '',
      clientMode: json['client_mode']?.toString() ?? 'GUEST',
      customerUserId: json['customer_user_id'] is int
          ? json['customer_user_id'] as int
          : int.tryParse(json['customer_user_id']?.toString() ?? ''),
      guestName: json['guest_name']?.toString(),
      guestPhone: json['guest_phone']?.toString(),
      guestEmail: json['guest_email']?.toString(),
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      serviceNameSnapshot: json['service_name_snapshot']?.toString() ?? '',
      durationMinutesSnapshot: json['duration_minutes_snapshot'] is int
          ? json['duration_minutes_snapshot'] as int
          : int.tryParse(json['duration_minutes_snapshot']?.toString() ?? '0') ?? 0,
      priceSnapshot: json['price_snapshot'] is num
          ? (json['price_snapshot'] as num).toDouble()
          : double.tryParse(json['price_snapshot']?.toString() ?? '0.0') ?? 0.0,
      status: SaasAppointmentStatus.fromString(json['status']?.toString()),
      cancellationReason: json['cancellation_reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
