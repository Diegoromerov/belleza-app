// lib/core/models/booking_model.dart
// Modelo tipado para reservas/citas del prestador

import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

@freezed
abstract class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String clientName,
    required String clientId,
    required String serviceName,
    required String serviceId,
    required String status,
    required DateTime scheduledAt,
    required String serviceAddress,
    required double totalAmount,
    double? providerNetAmount,
    double? platformCommission,
    double? stateTax,
    String? wompiReference,
    String? nequiAccount,
    String? payoutStatus,
    int? rating,
    String? clientAvatar,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

  // Helper para crear desde JSON del backend (snake_case)
  factory Booking.fromBackendJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Cliente',
      clientId: json['client_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? 'Servicio',
      serviceId: json['service_id']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ?? DateTime.now(),
      serviceAddress: json['service_address']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      providerNetAmount: double.tryParse(json['pago_neto_prestador']?.toString() ?? json['provider_net_amount']?.toString() ?? ''),
      platformCommission: double.tryParse(json['comision_plataforma']?.toString() ?? json['platform_commission']?.toString() ?? ''),
      stateTax: double.tryParse(json['impuestos_estado']?.toString() ?? json['state_tax']?.toString() ?? ''),
      wompiReference: json['wompi_reference']?.toString(),
      nequiAccount: json['numero_cuenta_nequi']?.toString(),
      payoutStatus: json['payout_status']?.toString(),
      rating: json['rating'] != null ? int.tryParse(json['rating'].toString()) : null,
      clientAvatar: json['client_avatar_url']?.toString(),
    );
  }
}

// Extension para helpers de estado
extension BookingStatusExt on Booking {
  String get statusUpper => status.toUpperCase();

  bool get isPending => statusUpper == 'PENDING' || statusUpper == 'PENDIENTE_PAGO';
  bool get isConfirmed => statusUpper == 'CONFIRMED' || statusUpper == 'CONFIRMADA';
  bool get isInProgress => statusUpper == 'EN_PROGRESO';
  bool get isWaitingOtp => statusUpper == 'ESPERANDO_OTP' || statusUpper == 'FINALIZADA_PRESTADOR';
  bool get isCompleted => statusUpper == 'COMPLETED' || statusUpper == 'COMPLETADA';
  bool get isCancelled => statusUpper == 'CANCELLED' || statusUpper == 'CANCELADA';
  bool get isDisputed => statusUpper == 'EN_DISPUTA';

  bool get isActive => isConfirmed || isInProgress || isWaitingOtp;
  bool get isFinal => isCompleted || isCancelled || isDisputed;
  bool get canStart => isConfirmed;
  bool get canComplete => isInProgress;
  bool get canVerifyOtp => isWaitingOtp;
  bool get canChat => isConfirmed || isInProgress || isWaitingOtp || isCompleted;
  bool get canViewRoute => isConfirmed || isInProgress;
  bool get canViewPayout => isCompleted;
}