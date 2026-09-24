// frontend/lib/services/saas/service_offer_assignment_service.dart
import 'package:flutter/foundation.dart';
import '../../models/saas/hub_salon_model.dart';
import '../../models/saas/service_offer_assignment_model.dart';
import '../api_service.dart';

/// ServiceOfferAssignmentException
///
/// Excepción de dominio para capturar fallos en operaciones de NODO-02.
class ServiceOfferAssignmentException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ServiceOfferAssignmentException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() =>
      'ServiceOfferAssignmentException: $message ${errorCode != null ? '[$errorCode]' : ''} ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// ServiceOfferAssignmentService
///
/// Servicio cliente para la gestión de Ofertas de Servicio y Asignaciones operativas (NODO-02 / SCR-08).
///
/// INVARIANTES ARQUITECTÓNICAS:
/// 1. Solo opera a través de ApiService inyectando x-active-membership-id vía ActiveContextHolder.
/// 2. Cero persistencia local de estado de sesión.
/// 3. Separación estricta entre Actor Authority y Target Eligibility.
/// 4. Desasignación pura (DELETE no destruye entidades padre).
class ServiceOfferAssignmentService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPut;
  final Future<dynamic> Function(String path, [Map<String, dynamic>? body]) _apiDelete;

  ServiceOfferAssignmentService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPut,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post,
        _apiPut = apiPut ?? ApiService.put,
        _apiDelete = apiDelete ?? ApiService.delete;

  // ==========================================
  // SERVICE OFFERS (OFERTAS DE SERVICIO)
  // ==========================================

  /// Lista todas las ofertas de servicio de la sede activa.
  /// Endpoint: GET /api/v1/saas/hub/services
  Future<List<ServiceOfferModel>> listServiceOffers() async {
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
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al listar ofertas de servicio.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al consultar ofertas de servicio.'),
      );
    }
  }

  /// Obtiene una oferta de servicio específica por ID.
  /// Endpoint: GET /api/v1/saas/hub/services/:id
  Future<ServiceOfferModel> getServiceOfferById(String id) async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/services/$id');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final offerData = (data is Map<String, dynamic> && data['service_offer'] is Map<String, dynamic>)
            ? data['service_offer'] as Map<String, dynamic>
            : (response['service_offer'] is Map<String, dynamic> ? response['service_offer'] as Map<String, dynamic> : null);

        if (offerData != null) {
          return ServiceOfferModel.fromJson(offerData);
        }
      }
      throw ServiceOfferAssignmentException(
        message: 'Oferta de servicio no encontrada.',
        statusCode: 404,
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al obtener la oferta de servicio.'),
      );
    }
  }

  /// Crea una nueva oferta de servicio en la sede activa.
  /// Endpoint: POST /api/v1/saas/hub/services
  Future<ServiceOfferModel> createServiceOffer(ServiceOfferFormData formData) async {
    final validationError = formData.validate();
    if (validationError != null) {
      throw ServiceOfferAssignmentException(
        message: validationError,
        statusCode: 400,
        errorCode: 'INVALID_PAYLOAD',
      );
    }

    try {
      final response = await _apiPost('/api/v1/saas/hub/services', formData.toJson());
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final offerData = (data is Map<String, dynamic> && data['service_offer'] is Map<String, dynamic>)
            ? data['service_offer'] as Map<String, dynamic>
            : (response['service_offer'] is Map<String, dynamic> ? response['service_offer'] as Map<String, dynamic> : null);

        if (offerData != null) {
          return ServiceOfferModel.fromJson(offerData);
        }
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al crear oferta de servicio.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al crear la oferta de servicio.'),
      );
    }
  }

  /// Actualiza los atributos mutables de una oferta de servicio.
  /// Endpoint: PUT /api/v1/saas/hub/services/:id
  Future<ServiceOfferModel> updateServiceOffer(String id, ServiceOfferFormData formData) async {
    final validationError = formData.validate();
    if (validationError != null) {
      throw ServiceOfferAssignmentException(
        message: validationError,
        statusCode: 400,
        errorCode: 'INVALID_PAYLOAD',
      );
    }

    try {
      final response = await _apiPut('/api/v1/saas/hub/services/$id', formData.toJson());
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final offerData = (data is Map<String, dynamic> && data['service_offer'] is Map<String, dynamic>)
            ? data['service_offer'] as Map<String, dynamic>
            : (response['service_offer'] is Map<String, dynamic> ? response['service_offer'] as Map<String, dynamic> : null);

        if (offerData != null) {
          return ServiceOfferModel.fromJson(offerData);
        }
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al actualizar oferta de servicio.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al actualizar la oferta de servicio.'),
      );
    }
  }

  // ==========================================
  // SERVICE ASSIGNMENTS (ASIGNACIONES)
  // ==========================================

  /// Lista todas las asignaciones de la sede activa.
  /// Endpoint: GET /api/v1/saas/hub/assignments
  Future<List<ServiceAssignmentModel>> listAssignments() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/assignments');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final List<dynamic> rawList = (data is Map<String, dynamic> && data['assignments'] is List)
            ? data['assignments'] as List<dynamic>
            : (response['assignments'] is List ? response['assignments'] as List<dynamic> : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => ServiceAssignmentModel.fromJson(item))
            .toList();
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al listar asignaciones.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al consultar asignaciones.'),
      );
    }
  }

  /// Lista las asignaciones asociadas a una oferta específica.
  /// Endpoint: GET /api/v1/saas/hub/assignments/offer/:service_offer_id
  Future<List<ServiceAssignmentModel>> getAssignmentsByOffer(String serviceOfferId) async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/assignments/offer/$serviceOfferId');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final List<dynamic> rawList = (data is Map<String, dynamic> && data['assignments'] is List)
            ? data['assignments'] as List<dynamic>
            : (response['assignments'] is List ? response['assignments'] as List<dynamic> : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => ServiceAssignmentModel.fromJson(item))
            .toList();
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al consultar asignaciones de la oferta.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al consultar asignaciones de la oferta.'),
      );
    }
  }

  /// Lista las asignaciones asociadas a un colaborador específico.
  /// Endpoint: GET /api/v1/saas/hub/assignments/staff/:membership_id
  Future<List<ServiceAssignmentModel>> getAssignmentsByStaff(String membershipId) async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/assignments/staff/$membershipId');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final List<dynamic> rawList = (data is Map<String, dynamic> && data['assignments'] is List)
            ? data['assignments'] as List<dynamic>
            : (response['assignments'] is List ? response['assignments'] as List<dynamic> : []);

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => ServiceAssignmentModel.fromJson(item))
            .toList();
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al consultar asignaciones del colaborador.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al consultar asignaciones del colaborador.'),
      );
    }
  }

  /// Crea una nueva asignación operativa entre oferta y colaborador elegible.
  /// Endpoint: POST /api/v1/saas/hub/assignments
  Future<ServiceAssignmentModel> createAssignment(ServiceAssignmentFormData formData) async {
    final validationError = formData.validate();
    if (validationError != null) {
      throw ServiceOfferAssignmentException(
        message: validationError,
        statusCode: 400,
        errorCode: 'INVALID_PAYLOAD',
      );
    }

    try {
      final response = await _apiPost('/api/v1/saas/hub/assignments', formData.toJson());
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final assignData = (data is Map<String, dynamic> && data['assignment'] is Map<String, dynamic>)
            ? data['assignment'] as Map<String, dynamic>
            : (response['assignment'] is Map<String, dynamic> ? response['assignment'] as Map<String, dynamic> : null);

        if (assignData != null) {
          return ServiceAssignmentModel.fromJson(assignData);
        }
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al crear asignación.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      final msg = e.toString();
      if (msg.contains('ASSIGNMENT_ALREADY_EXISTS') || msg.contains('409') || msg.contains('ya existe')) {
        throw ServiceOfferAssignmentException(
          message: 'Este colaborador ya se encuentra asignado a esta oferta de servicio.',
          statusCode: 409,
          errorCode: 'ASSIGNMENT_ALREADY_EXISTS',
        );
      }
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al crear la asignación.'),
      );
    }
  }

  /// Desasignación pura: Elimina la relación operativa sin borrar la oferta ni la membresía.
  /// Endpoint: DELETE /api/v1/saas/hub/assignments/:id
  Future<bool> deleteAssignment(String assignmentId) async {
    if (assignmentId.trim().isEmpty) {
      throw ServiceOfferAssignmentException(
        message: 'Identificador de asignación inválido.',
        statusCode: 400,
      );
    }

    try {
      final response = await _apiDelete('/api/v1/saas/hub/assignments/$assignmentId');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        final unassigned = (data is Map<String, dynamic> && data['unassigned'] == true) ||
            response['unassigned'] == true ||
            response['status'] == 'success';
        if (unassigned) {
          return true;
        }
      }
      return true;
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al eliminar la asignación.'),
      );
    }
  }

  // ==========================================
  // TARGET DISCOVERY & OVERVIEW
  // ==========================================

  /// Consulta el personal de la sede y filtra miembros con estado ACTIVE y rol operativo elegible.
  /// Roles elegibles: PROFESSIONAL, OWNER, MANAGER.
  /// Excluye estrictamente: RECEPTIONIST y estados suspendidos/inactivos.
  /// Endpoint: GET /api/v1/saas/hub/staff
  Future<List<HubStaffMember>> getEligibleStaff() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/staff');
      if (response is Map<String, dynamic>) {
        final staffResponse = HubStaffResponse.fromJson(
          response['data'] is Map<String, dynamic>
              ? response['data'] as Map<String, dynamic>
              : response,
        );

        const eligibleRoles = {'PROFESSIONAL', 'OWNER', 'MANAGER'};
        return staffResponse.members
            .where((m) => m.status.toUpperCase() == 'ACTIVE' && eligibleRoles.contains(m.role.toUpperCase()))
            .toList();
      }
      throw ServiceOfferAssignmentException(
        message: 'Respuesta inválida al consultar personal.',
      );
    } catch (e) {
      if (e is ServiceOfferAssignmentException) rethrow;
      throw ServiceOfferAssignmentException(
        message: _extractErrorMessage(e, 'Error al consultar personal elegible.'),
      );
    }
  }

  /// Carga combinada de ofertas, asignaciones y personal elegible para el estado completo de SCR-08.
  Future<List<ServiceOfferWithAssignments>> loadAggregatedOverview() async {
    final offersFuture = listServiceOffers();
    final assignmentsFuture = listAssignments();
    final staffFuture = getEligibleStaff();

    final offers = await offersFuture;
    final assignments = await assignmentsFuture;
    final staff = await staffFuture;

    final staffMap = {for (final m in staff) m.membershipId: m};

    return offers.map((offer) {
      final offerAssignments = assignments
          .where((a) => a.serviceOfferId == offer.id)
          .toList();

      final assignedStaffList = offerAssignments
          .map((a) => staffMap[a.membershipId])
          .whereType<HubStaffMember>()
          .toList();

      return ServiceOfferWithAssignments(
        offer: offer,
        assignments: offerAssignments,
        assignedStaff: assignedStaffList,
      );
    }).toList();
  }

  String _extractErrorMessage(dynamic e, String defaultMessage) {
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str.isNotEmpty ? str : defaultMessage;
  }
}
