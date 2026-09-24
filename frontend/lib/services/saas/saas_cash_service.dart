// frontend/lib/services/saas/saas_cash_service.dart
// GO-08.53: SaaS Cash Drawer HTTP Client Service

import '../../models/saas/saas_cash_model.dart';
import '../api_service.dart';

/// SaasCashService
///
/// Servicio cliente para el dominio Cash Drawer (SCR-16).
/// Consume exclusivamente los endpoints de /api/saas/cash/*.
class SaasCashService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;

  SaasCashService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post;

  // 1. GET /api/saas/cash/current
  Future<SaasCashStatusResponse> getCurrentStatus() async {
    try {
      final response = await _apiGet('/api/saas/cash/current');
      if (response is Map<String, dynamic>) {
        return SaasCashStatusResponse.fromJson(response);
      }
      throw SaasCashException(message: 'Respuesta inválida al consultar estado de caja.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar estado actual de caja.');
    }
  }

  // 2. POST /api/saas/cash/open
  Future<SaasCashSession> openSession({
    required double openingBalance,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'opening_balance': openingBalance,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/cash/open', body);
      if (response is Map<String, dynamic>) {
        final sessionMap = response['session'] is Map<String, dynamic>
            ? response['session'] as Map<String, dynamic>
            : response;
        return SaasCashSession.fromJson(sessionMap);
      }
      throw SaasCashException(message: 'Respuesta inválida al abrir turno de caja.');
    } catch (e) {
      throw _handleError(e, 'Error al abrir turno de caja.');
    }
  }

  // 3. POST /api/saas/cash/movements (CASH_IN)
  Future<SaasCashMovement> addCashIn({
    required String sessionId,
    required String category,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'movement_type': 'CASH_IN',
      'category': category,
      'amount': amount,
      'reason': reason,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/cash/movements', body);
      if (response is Map<String, dynamic>) {
        final movMap = response['movement'] is Map<String, dynamic>
            ? response['movement'] as Map<String, dynamic>
            : response;
        return SaasCashMovement.fromJson(movMap);
      }
      throw SaasCashException(message: 'Respuesta inválida al registrar ingreso de caja.');
    } catch (e) {
      throw _handleError(e, 'Error al registrar ingreso manual de caja.');
    }
  }

  // 4. POST /api/saas/cash/movements (CASH_OUT)
  Future<SaasCashMovement> addCashOut({
    required String sessionId,
    required String category,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'movement_type': 'CASH_OUT',
      'category': category,
      'amount': amount,
      'reason': reason,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/cash/movements', body);
      if (response is Map<String, dynamic>) {
        final movMap = response['movement'] is Map<String, dynamic>
            ? response['movement'] as Map<String, dynamic>
            : response;
        return SaasCashMovement.fromJson(movMap);
      }
      throw SaasCashException(message: 'Respuesta inválida al registrar egreso de caja.');
    } catch (e) {
      throw _handleError(e, 'Error al registrar egreso manual de caja.');
    }
  }

  // 5. POST /api/saas/cash/close
  Future<SaasCashReconciliation> closeSession({
    required String sessionId,
    required double countedCash,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'counted_cash': countedCash,
      if (notes != null && notes.trim().isNotEmpty) 'closing_notes': notes.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/cash/close', body);
      if (response is Map<String, dynamic>) {
        final recMap = response['reconciliation'] is Map<String, dynamic>
            ? response['reconciliation'] as Map<String, dynamic>
            : response;
        return SaasCashReconciliation.fromJson(recMap);
      }
      throw SaasCashException(message: 'Respuesta inválida al cerrar turno de caja.');
    } catch (e) {
      throw _handleError(e, 'Error al cerrar turno de caja.');
    }
  }

  // 6. GET /api/saas/cash/history
  Future<SaasCashHistoryResponse> getHistory({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = <String>[
        'page=$page',
        'limit=$limit',
        if (fromDate != null) 'from_date=$fromDate',
        if (toDate != null) 'to_date=$toDate',
      ].join('&');

      final response = await _apiGet('/api/saas/cash/history?$params');
      if (response is Map<String, dynamic>) {
        return SaasCashHistoryResponse.fromJson(response);
      }
      throw SaasCashException(message: 'Respuesta inválida al consultar histórico de turnos.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar histórico de caja.');
    }
  }

  // 7. GET /api/saas/cash/sessions/:id
  Future<SaasCashSessionDetail> getSessionDetail(String sessionId) async {
    try {
      final response = await _apiGet('/api/saas/cash/sessions/$sessionId');
      if (response is Map<String, dynamic>) {
        return SaasCashSessionDetail.fromJson(response);
      }
      throw SaasCashException(message: 'Respuesta inválida al consultar detalle de sesión.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar detalle del turno de caja.');
    }
  }

  SaasCashException _handleError(dynamic error, String defaultMsg) {
    if (error is SaasCashException) return error;

    final errStr = error.toString();
    if (errStr.contains('CASH_DRAWER_ALREADY_OPEN') || errStr.contains('409')) {
      return SaasCashException(
        message: 'Ya existe un turno de caja abierto para esta sede.',
        statusCode: 409,
        errorCode: 'CASH_DRAWER_ALREADY_OPEN',
      );
    }

    if (errStr.contains('INSUFFICIENT_DRAWER_FUNDS')) {
      return SaasCashException(
        message: 'Fondos insuficientes en caja para realizar el retiro solicitado.',
        statusCode: 422,
        errorCode: 'INSUFFICIENT_DRAWER_FUNDS',
      );
    }

    if (errStr.contains('CASH_DRAWER_NOT_OPEN')) {
      return SaasCashException(
        message: 'No hay un turno de caja abierto.',
        statusCode: 422,
        errorCode: 'CASH_DRAWER_NOT_OPEN',
      );
    }

    if (errStr.contains('FORBIDDEN') || errStr.contains('403')) {
      return SaasCashException(
        message: 'Acceso denegado. Rol no tiene permisos para operar caja.',
        statusCode: 403,
        errorCode: 'FORBIDDEN_ROLE',
      );
    }

    if (errStr.contains('404') || errStr.contains('SESSION_NOT_FOUND')) {
      return SaasCashException(
        message: 'La sesión de caja solicitada no fue encontrada.',
        statusCode: 404,
        errorCode: 'SESSION_NOT_FOUND',
      );
    }

    return SaasCashException(
      message: errStr.replaceFirst('Exception: ', '').trim().isEmpty
          ? defaultMsg
          : errStr.replaceFirst('Exception: ', '').trim(),
    );
  }
}
