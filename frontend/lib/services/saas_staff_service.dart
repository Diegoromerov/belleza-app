// frontend/lib/services/saas_staff_service.dart
// GO-08.41 / GO-08.43: Staff Provisioning Frontend Service

import '../models/saas_staff_model.dart';
import 'api_service.dart';

/// Client service consuming all 10 REST endpoints for Staff Provisioning and Public Invitations.
class SaasStaffService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPatch;
  final Future<dynamic> Function(String path, [Map<String, dynamic>? body]) _apiDelete;

  SaasStaffService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPatch,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post,
        _apiPatch = apiPatch ?? ApiService.patch,
        _apiDelete = apiDelete ?? ApiService.delete;

  // 1. GET /api/saas/staff
  Future<StaffListResponse> listStaff({
    String? role,
    String? status,
    String? search,
  }) async {
    try {
      var path = '/api/saas/staff';
      final params = <String>[];
      if (role != null && role.isNotEmpty && role != 'ALL') {
        params.add('role=${Uri.encodeQueryComponent(role)}');
      }
      if (status != null && status.isNotEmpty && status != 'ALL') {
        params.add('status=${Uri.encodeQueryComponent(status)}');
      }
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      if (params.isNotEmpty) {
        path += '?${params.join('&')}';
      }

      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        return StaffListResponse.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inesperada al listar personal.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al listar colaboradores de la sede.');
    }
  }

  // 2. POST /api/saas/staff/invitations
  Future<StaffInvitationEmissionResponse> createInvitation({
    required String email,
    required String role,
    required String relationType,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'role': role.trim().toUpperCase(),
      'relation_type': relationType.trim().toUpperCase(),
    };

    try {
      final response = await _apiPost('/api/saas/staff/invitations', body);
      if (response is Map<String, dynamic>) {
        return StaffInvitationEmissionResponse.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al emitir invitación.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al emitir invitación.');
    }
  }

  // 3. GET /api/saas/staff/invitations
  Future<StaffInvitationListResponse> listInvitations({String? status}) async {
    try {
      var path = '/api/saas/staff/invitations';
      if (status != null && status.isNotEmpty) {
        path += '?status=${Uri.encodeQueryComponent(status)}';
      }
      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        return StaffInvitationListResponse.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inesperada al listar invitaciones.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al consultar invitaciones pendientes.');
    }
  }

  // 4. DELETE /api/saas/staff/invitations/:id
  Future<bool> revokeInvitation(String invitationId) async {
    try {
      final response = await _apiDelete('/api/saas/staff/invitations/$invitationId');
      if (response is Map<String, dynamic>) {
        return response['success'] == true || response['revoked_invitation_id'] != null;
      }
      return true;
    } catch (e) {
      throw _handleError(e, 'Error al cancelar la invitación.');
    }
  }

  // 5. POST /api/saas/staff/invitations/:id/resend
  Future<StaffInvitationEmissionResponse> resendInvitation(String invitationId) async {
    try {
      final response = await _apiPost('/api/saas/staff/invitations/$invitationId/resend', {});
      if (response is Map<String, dynamic>) {
        return StaffInvitationEmissionResponse.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al reenviar invitación.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al reenviar la invitación.');
    }
  }

  // 6. PATCH /api/saas/staff/:membershipId/role
  Future<StaffMember> updateStaffRole(String membershipId, String newRole) async {
    final body = {'role': newRole.trim().toUpperCase()};
    try {
      final response = await _apiPatch('/api/saas/staff/$membershipId/role', body);
      if (response is Map<String, dynamic> && response['member'] != null) {
        return StaffMember.fromJson(response['member'] as Map<String, dynamic>);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al actualizar rol.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al modificar rol del colaborador.');
    }
  }

  // 7. PATCH /api/saas/staff/:membershipId/status
  Future<StaffMember> updateStaffStatus(String membershipId, String newStatus) async {
    final body = {'status': newStatus.trim().toUpperCase()};
    try {
      final response = await _apiPatch('/api/saas/staff/$membershipId/status', body);
      if (response is Map<String, dynamic> && response['member'] != null) {
        return StaffMember.fromJson(response['member'] as Map<String, dynamic>);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al actualizar estado.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al modificar estado del colaborador.');
    }
  }

  // 8. PATCH /api/saas/staff/:membershipId/relation-type
  Future<StaffMember> updateStaffRelationType(String membershipId, String newRelationType) async {
    final body = {'relation_type': newRelationType.trim().toUpperCase()};
    try {
      final response = await _apiPatch('/api/saas/staff/$membershipId/relation-type', body);
      if (response is Map<String, dynamic> && response['member'] != null) {
        return StaffMember.fromJson(response['member'] as Map<String, dynamic>);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al actualizar tipo de relación.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al modificar relación contractual del colaborador.');
    }
  }

  // 9. GET /api/saas/public/invitations/:token
  Future<StaffInvitationInspection> getInvitationByToken(String token) async {
    try {
      final cleanToken = token.trim();
      final response = await _apiGet('/api/saas/public/invitations/$cleanToken');
      if (response is Map<String, dynamic>) {
        return StaffInvitationInspection.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al inspeccionar invitación.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al consultar la invitación.');
    }
  }

  // 10. POST /api/saas/public/invitations/:token/accept
  Future<StaffInvitationAcceptanceResponse> acceptInvitation(
    String token, {
    String? fullName,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }
    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password.trim();
    }

    try {
      final cleanToken = token.trim();
      final response = await _apiPost('/api/saas/public/invitations/$cleanToken/accept', body);
      if (response is Map<String, dynamic>) {
        return StaffInvitationAcceptanceResponse.fromJson(response);
      }
      throw SaasStaffException(
        code: 'INVALID_RESPONSE',
        message: 'Respuesta inválida al aceptar invitación.',
        statusCode: 500,
      );
    } catch (e) {
      throw _handleError(e, 'Error al procesar la aceptación de la invitación.');
    }
  }

  SaasStaffException _handleError(dynamic error, String defaultMsg) {
    if (error is SaasStaffException) return error;

    final errStr = error.toString();

    // Extract code if present in string like "Exception: CANNOT_ORPHAN_ESTABLISHMENT" or JSON
    for (final knownCode in [
      'UNAUTHORIZED_ROLE',
      'UNAUTHORIZED_ROLE_MUTATION',
      'SELF_ROLE_MUTATION_PROHIBITED',
      'SELF_STATUS_MUTATION_PROHIBITED',
      'CANNOT_ORPHAN_ESTABLISHMENT',
      'INVALID_STATE_TRANSITION',
      'INVITATION_ALREADY_PENDING',
      'USER_ALREADY_MEMBER',
      'INVITATION_EXPIRED',
      'INVITATION_REVOKED',
      'INVITATION_ALREADY_PROCESSED',
      'INVITATION_NOT_FOUND',
      'INVITATION_NOT_PENDING',
      'IDENTITY_MISMATCH',
      'TENANT_MISMATCH',
      'REGISTRATION_REQUIRED',
      'AUTHENTICATION_REQUIRED',
      'ACTIVE_CONTEXT_REQUIRED',
      'INVALID_TOKEN',
      'INVALID_ROLE',
      'INVALID_STATUS',
      'MEMBERSHIP_NOT_FOUND',
      'USER_NOT_FOUND',
    ]) {
      if (errStr.contains(knownCode)) {
        int status = 400;
        if (knownCode.contains('UNAUTHORIZED') || knownCode.contains('SELF_') || knownCode.contains('MISMATCH')) {
          status = 403;
        } else if (knownCode.contains('NOT_FOUND')) {
          status = 404;
        } else if (knownCode.contains('EXPIRED') || knownCode.contains('REVOKED')) {
          status = 410;
        } else if (knownCode.contains('ALREADY')) {
          status = 409;
        } else if (knownCode.contains('CANNOT_ORPHAN') || knownCode.contains('INVALID_STATE')) {
          status = 422;
        }

        return SaasStaffException(
          code: knownCode,
          message: SaasStaffException.localize(knownCode, defaultMsg: defaultMsg),
          statusCode: status,
        );
      }
    }

    return SaasStaffException(
      code: 'GENERIC_ERROR',
      message: errStr.replaceFirst('Exception: ', '').trim().isEmpty
          ? defaultMsg
          : errStr.replaceFirst('Exception: ', '').trim(),
      statusCode: 500,
    );
  }
}
