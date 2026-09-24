// frontend/lib/services/saas/saas_reserva_interna_service.dart
// NODO-07 / SCR-11: Reserva Interna Service

import '../../models/saas/saas_agenda_models.dart';
import '../../models/saas/saas_reserva_interna_models.dart';
import '../../models/saas/service_offer_assignment_model.dart';
import '../api_service.dart';

class SaasReservaInternaException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  SaasReservaInternaException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode = 400,
  });

  @override
  String toString() => 'SaasReservaInternaException: [$statusCode/$code] $message';
}

class SaasReservaInternaService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;

  SaasReservaInternaService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post;

  /// GET /api/v1/saas/hub/services
  /// Lista las ofertas de servicio de la sede activa (NODO-02).
  Future<List<ServiceOfferModel>> getServiceOffers() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/services');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final List<dynamic> rawList = (data is Map<String, dynamic> && data['service_offers'] is List)
            ? data['service_offers'] as List<dynamic>
            : (response['service_offers'] is List ? response['service_offers'] as List<dynamic> : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => ServiceOfferModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is SaasReservaInternaException) rethrow;
      throw SaasReservaInternaException(
        message: _extractErrorMessage(e, 'Error al consultar catálogo de servicios.'),
        code: 'FETCH_SERVICES_FAILED',
      );
    }
  }

  /// GET /api/v1/saas/hub/staff
  /// Lista el personal activo de la sede.
  Future<List<StaffMemberOption>> getStaffMembers() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/staff');
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        final rawList = data['staff'] is List ? data['staff'] as List<dynamic> : [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => StaffMemberOption(
                  membershipId: item['membership_id']?.toString() ?? '',
                  name: (item['name'] ?? item['nombre'] ?? 'Profesional').toString(),
                ))
            .where((s) => s.membershipId.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      if (e is SaasReservaInternaException) rethrow;
      throw SaasReservaInternaException(
        message: _extractErrorMessage(e, 'Error al consultar personal de la sede.'),
        code: 'FETCH_STAFF_FAILED',
      );
    }
  }

  /// GET /api/v1/saas/hub/availability/projection
  /// Consulta la proyección determinista de slots libres (NODO-05).
  Future<SaasAvailabilityProjection> getAvailabilityProjection({
    required String serviceOfferId,
    required String targetDate,
    String? membershipId,
    String projectionMode = 'AGGREGATED',
    int stepMinutes = 15,
  }) async {
    if (serviceOfferId.trim().isEmpty) {
      throw SaasReservaInternaException(
        message: 'service_offer_id es requerido.',
        code: 'INVALID_SERVICE_OFFER_ID',
        statusCode: 400,
      );
    }
    if (targetDate.trim().isEmpty) {
      throw SaasReservaInternaException(
        message: 'target_date (YYYY-MM-DD) es requerido.',
        code: 'INVALID_TARGET_DATE',
        statusCode: 400,
      );
    }

    try {
      String path = '/api/v1/saas/hub/availability/projection'
          '?service_offer_id=${Uri.encodeComponent(serviceOfferId)}'
          '&target_date=${Uri.encodeComponent(targetDate)}'
          '&projection_mode=${Uri.encodeComponent(projectionMode)}'
          '&step_minutes=$stepMinutes';

      if (membershipId != null && membershipId.isNotEmpty) {
        path += '&membership_id=${Uri.encodeComponent(membershipId)}';
      }

      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return SaasAvailabilityProjection.fromJson(data);
      }
      throw SaasReservaInternaException(
        message: 'Respuesta inválida al consultar disponibilidad.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is SaasReservaInternaException) rethrow;
      throw SaasReservaInternaException(
        message: _extractErrorMessage(e, 'Error al consultar disponibilidad de horarios.'),
        code: 'FETCH_AVAILABILITY_FAILED',
      );
    }
  }

  /// POST /api/v1/saas/hub/appointments
  /// Crea transaccionalmente una cita interna en saas_appointments (NODO-06).
  Future<SaasAppointmentDetailModel> createAppointment(CreateAppointmentPayload payload) async {
    if (payload.serviceOfferId.trim().isEmpty) {
      throw SaasReservaInternaException(
        message: 'Oferta de servicio requerida.',
        code: 'INVALID_SERVICE_OFFER_ID',
        statusCode: 400,
      );
    }
    if (payload.membershipId.trim().isEmpty) {
      throw SaasReservaInternaException(
        message: 'Profesional requerido.',
        code: 'INVALID_MEMBERSHIP_ID',
        statusCode: 400,
      );
    }
    if (payload.scheduledAt.trim().isEmpty) {
      throw SaasReservaInternaException(
        message: 'Horario programado requerido.',
        code: 'INVALID_SCHEDULED_AT',
        statusCode: 400,
      );
    }

    // Validación XOR de cliente
    if (payload.customerUserId == null) {
      if (payload.guestName == null || payload.guestName!.trim().length < 2) {
        throw SaasReservaInternaException(
          message: 'El nombre del invitado debe tener al menos 2 caracteres.',
          code: 'INVALID_CLIENT_IDENTITY_MODE',
          statusCode: 400,
        );
      }
      if (payload.guestPhone == null || payload.guestPhone!.trim().length < 7) {
        throw SaasReservaInternaException(
          message: 'El teléfono del invitado debe tener al menos 7 caracteres.',
          code: 'INVALID_CLIENT_IDENTITY_MODE',
          statusCode: 400,
        );
      }
    }

    try {
      final response = await _apiPost(
        '/api/v1/saas/hub/appointments',
        payload.toJson(),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return SaasAppointmentDetailModel.fromJson(data);
      }
      throw SaasReservaInternaException(
        message: 'Respuesta inválida al crear cita.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is SaasReservaInternaException) rethrow;
      final raw = e.toString();
      if (raw.contains('409') || raw.contains('APPOINTMENT_OCCUPANCY_COLLISION') || raw.contains('overlaps with an existing active appointment')) {
        throw SaasReservaInternaException(
          message: 'El horario seleccionado acaba de ser ocupado por otra reserva.',
          code: 'APPOINTMENT_OCCUPANCY_COLLISION',
          statusCode: 409,
        );
      }
      throw SaasReservaInternaException(
        message: _extractErrorMessage(e, 'Error al crear la cita.'),
        code: 'CREATE_APPOINTMENT_FAILED',
      );
    }
  }

  String _extractErrorMessage(dynamic error, String fallback) {
    if (error is Exception) {
      final raw = error.toString();
      if (raw.contains('Exception: ')) {
        return raw.replaceAll('Exception: ', '').trim();
      }
      return raw;
    }
    return fallback;
  }
}
