// frontend/lib/services/saas/staff_schedule_service.dart
// NODO-03A UI / SCR-09: Staff Operational Availability & Schedule Service

import 'package:flutter/foundation.dart';
import '../../models/saas/staff_schedule_model.dart';
import '../api_service.dart';
import '../active_context_holder.dart';

class StaffScheduleException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  StaffScheduleException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode = 400,
  });

  @override
  String toString() => 'StaffScheduleException: [$statusCode/$code] $message';
}

class StaffScheduleService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPut;
  final Future<dynamic> Function(String path, [Map<String, dynamic>? body]) _apiDelete;

  StaffScheduleService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPut,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPut = apiPut ?? ApiService.put,
        _apiDelete = apiDelete ?? ApiService.delete;

  /// OP-03: GET /api/v1/saas/hub/staff/schedules
  /// Retorna la matriz de disponibilidad operativa de todo el personal en el establecimiento activo.
  Future<List<StaffScheduleItemModel>> listStaffSchedules() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/staff/schedules');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final List<dynamic> rawList = data is List
            ? data
            : (data is Map<String, dynamic> && data['schedules'] is List
                ? data['schedules'] as List<dynamic>
                : (response['schedules'] is List ? response['schedules'] as List<dynamic> : []));

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => StaffScheduleItemModel.fromJson(item))
            .toList();
      } else if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((item) => StaffScheduleItemModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is StaffScheduleException) rethrow;
      throw StaffScheduleException(
        message: _extractErrorMessage(e, 'Error al consultar horarios del personal.'),
        code: 'FETCH_FAILED',
      );
    }
  }

  /// OP-02: GET /api/v1/saas/hub/staff/:membership_id/schedule
  /// Retorna el detalle del horario semanal de un colaborador y su out_of_operating_hours_warning.
  Future<StaffScheduleDetailModel> getStaffSchedule(String membershipId) async {
    if (membershipId.trim().isEmpty) {
      throw StaffScheduleException(
        message: 'Identificador de membresía no válido.',
        code: 'INVALID_MEMBERSHIP_ID',
        statusCode: 400,
      );
    }

    try {
      final response = await _apiGet('/api/v1/saas/hub/staff/$membershipId/schedule');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final detailData = data is Map<String, dynamic> ? data : response;
        return StaffScheduleDetailModel.fromJson(detailData);
      }
      throw StaffScheduleException(
        message: 'Respuesta inválida al obtener horario del colaborador.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is StaffScheduleException) rethrow;
      throw StaffScheduleException(
        message: _extractErrorMessage(e, 'Error al consultar horario individual.'),
        code: 'FETCH_DETAIL_FAILED',
      );
    }
  }

  /// OP-01: PUT /api/v1/saas/hub/staff/:membership_id/schedule
  /// Reemplazo atómico y completo del horario semanal del colaborador.
  Future<StaffScheduleDetailModel> setStaffSchedule(
    String membershipId,
    WeeklyScheduleModel weeklySchedule,
  ) async {
    if (membershipId.trim().isEmpty) {
      throw StaffScheduleException(
        message: 'Identificador de membresía no válido.',
        code: 'INVALID_MEMBERSHIP_ID',
        statusCode: 400,
      );
    }

    final payload = {
      'weekly_schedule': weeklySchedule.toJson(),
    };

    try {
      final response = await _apiPut('/api/v1/saas/hub/staff/$membershipId/schedule', payload);
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final detailData = data is Map<String, dynamic> ? data : response;
        return StaffScheduleDetailModel.fromJson(detailData);
      }
      throw StaffScheduleException(
        message: 'Respuesta inválida al guardar horario semanal.',
        code: 'INVALID_RESPONSE',
        statusCode: 400,
      );
    } catch (e) {
      if (e is StaffScheduleException) rethrow;
      final msg = e.toString();
      if (msg.contains('FORBIDDEN_SELF_MANAGEMENT_ONLY') || msg.contains('403')) {
        throw StaffScheduleException(
          message: 'Un colaborador con rol PROFESSIONAL solo puede gestionar su propia disponibilidad operativa.',
          code: 'FORBIDDEN_SELF_MANAGEMENT_ONLY',
          statusCode: 403,
        );
      }
      throw StaffScheduleException(
        message: _extractErrorMessage(e, 'Error al guardar horario semanal.'),
        code: 'SAVE_FAILED',
      );
    }
  }

  /// OP-04: DELETE /api/v1/saas/hub/staff/:membership_id/schedule
  /// Reset total del horario semanal del colaborador a NOT_CONFIGURED / vacío.
  Future<bool> deleteStaffSchedule(String membershipId) async {
    if (membershipId.trim().isEmpty) {
      throw StaffScheduleException(
        message: 'Identificador de membresía no válido.',
        code: 'INVALID_MEMBERSHIP_ID',
        statusCode: 400,
      );
    }

    try {
      final response = await _apiDelete('/api/v1/saas/hub/staff/$membershipId/schedule');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final deleted = (data is Map<String, dynamic> && data['schedule_state'] == 'NOT_CONFIGURED') ||
            response['success'] == true ||
            response['status'] == 'success';
        return deleted || true;
      }
      return true;
    } catch (e) {
      if (e is StaffScheduleException) rethrow;
      final msg = e.toString();
      if (msg.contains('FORBIDDEN_ROLE') || msg.contains('403')) {
        throw StaffScheduleException(
          message: 'Solo los roles OWNER o MANAGER pueden eliminar la disponibilidad de un colaborador.',
          code: 'FORBIDDEN_ROLE',
          statusCode: 403,
        );
      }
      throw StaffScheduleException(
        message: _extractErrorMessage(e, 'Error al eliminar horario semanal.'),
        code: 'DELETE_FAILED',
      );
    }
  }

  String _extractErrorMessage(dynamic e, String defaultMessage) {
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str.isNotEmpty ? str : defaultMessage;
  }
}
