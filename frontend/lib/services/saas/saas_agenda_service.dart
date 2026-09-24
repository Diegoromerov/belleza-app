// frontend/lib/services/saas/saas_agenda_service.dart
// NODO-07 / SCR-10: Saas Agenda Service

import '../../models/saas/saas_agenda_models.dart';
import '../api_service.dart';

class SaasAgendaException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  SaasAgendaException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode = 400,
  });

  @override
  String toString() => 'SaasAgendaException: [$statusCode/$code] $message';
}

class SaasAgendaService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPatch;

  SaasAgendaService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPatch,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPatch = apiPatch ?? ApiService.patch;

  /// GET /api/v1/saas/hub/appointments/agenda
  /// Consulta la proyección operativa diaria de citas y turnos de la sede activa.
  Future<SaasAgendaProjection> getAgendaProjection({
    required String targetDate,
    String? membershipId,
  }) async {
    if (targetDate.trim().isEmpty) {
      throw SaasAgendaException(
        message: 'target_date (YYYY-MM-DD) es requerido.',
        code: 'INVALID_TIME_FORMAT',
        statusCode: 400,
      );
    }

    try {
      String path = '/api/v1/saas/hub/appointments/agenda?target_date=${Uri.encodeComponent(targetDate)}';
      if (membershipId != null && membershipId.isNotEmpty) {
        path += '&membership_id=${Uri.encodeComponent(membershipId)}';
      }

      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return SaasAgendaProjection.fromJson(data);
      }
      throw SaasAgendaException(
        message: 'Respuesta inválida al consultar la agenda.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is SaasAgendaException) rethrow;
      throw SaasAgendaException(
        message: _extractErrorMessage(e, 'Error al consultar la agenda operativa.'),
        code: 'FETCH_AGENDA_FAILED',
      );
    }
  }

  /// GET /api/v1/saas/hub/appointments/:id
  /// Obtiene el detalle secundario completo de una cita individual.
  Future<SaasAppointmentDetailModel> getAppointmentDetail(String appointmentId) async {
    if (appointmentId.trim().isEmpty) {
      throw SaasAgendaException(
        message: 'ID de cita requerido.',
        code: 'INVALID_APPOINTMENT_ID',
        statusCode: 400,
      );
    }

    try {
      final response = await _apiGet('/api/v1/saas/hub/appointments/$appointmentId');
      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return SaasAppointmentDetailModel.fromJson(data);
      }
      throw SaasAgendaException(
        message: 'Respuesta inválida al consultar detalle de cita.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is SaasAgendaException) rethrow;
      throw SaasAgendaException(
        message: _extractErrorMessage(e, 'Error al consultar detalle de la cita.'),
        code: 'FETCH_DETAIL_FAILED',
      );
    }
  }

  /// PATCH /api/v1/saas/hub/appointments/:id/status
  /// Transiciona el estado operacional de una cita.
  Future<SaasAppointmentDetailModel> updateAppointmentStatus({
    required String appointmentId,
    required String targetStatus,
    String? cancellationReason,
  }) async {
    if (appointmentId.trim().isEmpty) {
      throw SaasAgendaException(
        message: 'ID de cita requerido.',
        code: 'INVALID_APPOINTMENT_ID',
        statusCode: 400,
      );
    }

    final payload = <String, dynamic>{
      'status': targetStatus,
    };
    if (cancellationReason != null && cancellationReason.trim().isNotEmpty) {
      payload['cancellation_reason'] = cancellationReason.trim();
    }

    try {
      final response = await _apiPatch(
        '/api/v1/saas/hub/appointments/$appointmentId/status',
        payload,
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return SaasAppointmentDetailModel.fromJson(data);
      }
      throw SaasAgendaException(
        message: 'Respuesta inválida al actualizar estado.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is SaasAgendaException) rethrow;
      throw SaasAgendaException(
        message: _extractErrorMessage(e, 'Error al actualizar estado de la cita.'),
        code: 'UPDATE_STATUS_FAILED',
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
