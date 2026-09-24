// frontend/lib/services/saas/saas_customers_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/saas/customer_model.dart';
import '../api_service.dart';

/// SaasCustomerException
///
/// Excepción de dominio para capturar errores del subsistema Customer.
class SaasCustomerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final List<CustomerDuplicateCandidate>? candidates;

  SaasCustomerException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.candidates,
  });

  bool get isDuplicateWarning => errorCode == 'POSSIBLE_DUPLICATE_FOUND';

  @override
  String toString() =>
      'SaasCustomerException: $message ${errorCode != null ? '[$errorCode]' : ''} ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// SaasCustomersService
///
/// Servicio cliente para el dominio Customer / Client Directory (SCR-13).
/// Consume exclusivamente los 10 endpoints de /api/saas/customers/*.
class SaasCustomersService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPatch;
  final Future<dynamic> Function(String path, [Map<String, dynamic>? body]) _apiDelete;

  SaasCustomersService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPatch,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post,
        _apiPatch = apiPatch ?? ApiService.patch,
        _apiDelete = apiDelete ?? ApiService.delete;

  // 1. GET /api/saas/customers/search
  Future<List<SaasCustomerSummary>> searchCustomers(String query, {int limit = 10}) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return [];
    }
    try {
      final encodedQuery = Uri.encodeQueryComponent(trimmed);
      final response = await _apiGet('/api/saas/customers/search?q=$encodedQuery&limit=$limit');
      if (response is Map<String, dynamic>) {
        final rawList = response['data'] is List ? response['data'] as List : [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => SaasCustomerSummary.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e, 'Error al buscar clientes.');
    }
  }

  // 2. GET /api/saas/customers
  Future<CustomerListResult> listCustomers({
    String scope = 'establishment',
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      var path = '/api/saas/customers?scope=$scope&page=$page&limit=$limit';
      if (status != null && status.isNotEmpty && status != 'ALL') {
        path += '&status=${Uri.encodeQueryComponent(status)}';
      }
      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        return CustomerListResult.fromJson(response);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al listar clientes.');
    } catch (e) {
      throw _handleError(e, 'Error al listar clientes.');
    }
  }

  // 3. POST /api/saas/customers
  Future<SaasCustomerDetail> createCustomer({
    required String firstName,
    String? lastName,
    String? phone,
    String? email,
    String? birthDate,
    String? notes,
    String? localNotes,
    bool confirmDuplicate = false,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) 'last_name': lastName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (birthDate != null && birthDate.trim().isNotEmpty) 'birth_date': birthDate.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (localNotes != null && localNotes.trim().isNotEmpty) 'local_notes': localNotes.trim(),
      'confirm_duplicate': confirmDuplicate,
    };

    try {
      final response = await _apiPost('/api/saas/customers', body);
      if (response is Map<String, dynamic>) {
        return SaasCustomerDetail.fromJson(response);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al crear cliente.');
    } catch (e) {
      throw _handleError(e, 'Error al crear cliente.');
    }
  }

  // 4. GET /api/saas/customers/:id
  Future<SaasCustomerDetail> getCustomerById(String id) async {
    try {
      final response = await _apiGet('/api/saas/customers/$id');
      if (response is Map<String, dynamic>) {
        return SaasCustomerDetail.fromJson(response);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al consultar cliente.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar detalle del cliente.');
    }
  }

  // 5. PATCH /api/saas/customers/:id
  Future<SaasCustomerDetail> updateCustomer(
    String id, {
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? birthDate,
    String? notes,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'first_name': firstName.trim(),
      if (lastName != null) 'last_name': lastName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (email != null) 'email': email.trim(),
      if (birthDate != null) 'birth_date': birthDate.trim(),
      if (notes != null) 'notes': notes.trim(),
      if (status != null) 'status': status,
    };

    try {
      final response = await _apiPatch('/api/saas/customers/$id', body);
      if (response is Map<String, dynamic>) {
        return SaasCustomerDetail.fromJson(response);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al actualizar cliente.');
    } catch (e) {
      throw _handleError(e, 'Error al actualizar datos canónicos del cliente.');
    }
  }

  // 6. POST /api/saas/customers/:id/establishments
  Future<CustomerEstablishmentRelation> associateEstablishment(
    String id, {
    String? localNotes,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      if (localNotes != null) 'local_notes': localNotes.trim(),
      'is_active': isActive,
    };

    try {
      final response = await _apiPost('/api/saas/customers/$id/establishments', body);
      if (response is Map<String, dynamic>) {
        final relData = response['relation'] is Map<String, dynamic>
            ? response['relation'] as Map<String, dynamic>
            : response;
        return CustomerEstablishmentRelation.fromJson(relData);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al asociar cliente a la sede.');
    } catch (e) {
      throw _handleError(e, 'Error al asociar cliente a la sede.');
    }
  }

  // 7. PATCH /api/saas/customers/:id/establishments/current
  Future<CustomerEstablishmentRelation> updateEstablishmentRelation(
    String id, {
    String? localNotes,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (localNotes != null) 'local_notes': localNotes.trim(),
      if (isActive != null) 'is_active': isActive,
    };

    try {
      final response = await _apiPatch('/api/saas/customers/$id/establishments/current', body);
      if (response is Map<String, dynamic>) {
        final relData = response['relation'] is Map<String, dynamic>
            ? response['relation'] as Map<String, dynamic>
            : response;
        return CustomerEstablishmentRelation.fromJson(relData);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al actualizar relación local.');
    } catch (e) {
      throw _handleError(e, 'Error al actualizar notas o estado local del cliente.');
    }
  }

  // 8. POST /api/saas/customers/:id/link-user
  Future<Map<String, dynamic>> linkUser(String id, {required String userId}) async {
    final body = <String, dynamic>{'user_id': userId.trim()};
    try {
      final response = await _apiPost('/api/saas/customers/$id/link-user', body);
      if (response is Map<String, dynamic>) {
        return response;
      }
      throw SaasCustomerException(message: 'Respuesta inválida al vincular cuenta.');
    } catch (e) {
      throw _handleError(e, 'Error al vincular cuenta de usuario B2C.');
    }
  }

  // 9. POST /api/saas/customers/:id/unlink-user
  Future<Map<String, dynamic>> unlinkUser(String id) async {
    try {
      final response = await _apiPost('/api/saas/customers/$id/unlink-user', {});
      if (response is Map<String, dynamic>) {
        return response;
      }
      throw SaasCustomerException(message: 'Respuesta inválida al desvincular cuenta.');
    } catch (e) {
      throw _handleError(e, 'Error al desvincular cuenta de usuario B2C.');
    }
  }

  // 10. GET /api/saas/customers/:id/history
  Future<CustomerHistoryResult> getCustomerHistory(String id) async {
    try {
      final response = await _apiGet('/api/saas/customers/$id/history');
      if (response is Map<String, dynamic>) {
        return CustomerHistoryResult.fromJson(response);
      }
      throw SaasCustomerException(message: 'Respuesta inválida al consultar historial.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar historial del cliente.');
    }
  }

  SaasCustomerException _handleError(dynamic error, String defaultMsg) {
    if (error is SaasCustomerException) return error;

    final errStr = error.toString();
    // Intento de parsear si viene como JSON o Exception string
    if (errStr.contains('POSSIBLE_DUPLICATE_FOUND')) {
      return SaasCustomerException(
        message: 'Se encontraron posibles clientes duplicados con el mismo teléfono o correo.',
        statusCode: 409,
        errorCode: 'POSSIBLE_DUPLICATE_FOUND',
      );
    }

    if (errStr.contains('FORBIDDEN') || errStr.contains('403')) {
      return SaasCustomerException(
        message: 'No tienes permisos suficientes para realizar esta acción.',
        statusCode: 403,
        errorCode: 'FORBIDDEN_ROLE',
      );
    }

    if (errStr.contains('404') || errStr.contains('CUSTOMER_NOT_FOUND')) {
      return SaasCustomerException(
        message: 'El cliente solicitado no existe.',
        statusCode: 404,
        errorCode: 'CUSTOMER_NOT_FOUND',
      );
    }

    return SaasCustomerException(
      message: errStr.replaceFirst('Exception: ', '').trim().isEmpty
          ? defaultMsg
          : errStr.replaceFirst('Exception: ', '').trim(),
    );
  }
}
