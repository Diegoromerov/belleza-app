// frontend/lib/services/saas/crear_desde_cero_service.dart
import '../../models/saas/crear_desde_cero_model.dart';
import '../active_context_holder.dart';
import '../api_service.dart';

class CrearDesdeCeroException implements Exception {
  final String code;
  final String message;

  const CrearDesdeCeroException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'CrearDesdeCeroException($code): $message';
}

/// Servicio cliente para el aprovisionamiento inicial y compilación del Context Package (SCR-06).
///
/// Axioma de Transitoriedad:
/// Este servicio es 100% transitorio en memoria. No persiste datos en almacenamiento local,
/// no muta [ActiveContextHolder] ni altera entidades de base de datos.
class CrearDesdeCeroService {
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;
  final ActiveContextHolder _contextHolder;

  CrearDesdeCeroService({
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
    ActiveContextHolder? contextHolder,
  })  : _apiPost = apiPost ?? ApiService.post,
        _contextHolder = contextHolder ?? ActiveContextHolder();

  /// Compila y envía el Context Package transitorio hacia el backend.
  ///
  /// Endpoint: `POST /api/v1/saas/hub/onboarding/bootstrap`
  /// Requiere: `Authorization: Bearer <JWT>` y `x-active-membership-id: <UUID>`
  Future<ContextPackageResponse> bootstrapInitialSetup(
    CrearDesdeCeroBootstrapRequest request,
  ) async {
    final membershipId = _contextHolder.activeMembershipId;
    if (membershipId == null || membershipId.isEmpty) {
      throw const CrearDesdeCeroException(
        code: 'ACTIVE_CONTEXT_MISSING',
        message: 'No hay un contexto de sede activo para realizar el aprovisionamiento.',
      );
    }

    try {
      final response = await _apiPost(
        '/api/v1/saas/hub/onboarding/bootstrap',
        request.toJson(),
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error') && response['status'] != 'success') {
          final errCode = response['error']?.toString() ?? 'BOOTSTRAP_ERROR';
          final errMsg = response['message']?.toString() ?? 'Error al compilar el Context Package.';
          throw CrearDesdeCeroException(code: errCode, message: errMsg);
        }
        return ContextPackageResponse.fromJson(response);
      } else {
        throw const CrearDesdeCeroException(
          code: 'INVALID_RESPONSE_FORMAT',
          message: 'Formato de respuesta no válido desde el backend.',
        );
      }
    } on CrearDesdeCeroException {
      rethrow;
    } catch (e) {
      final str = e.toString();
      if (str.contains('INSUFFICIENT_PROVISIONING_ROLE')) {
        throw const CrearDesdeCeroException(
          code: 'INSUFFICIENT_PROVISIONING_ROLE',
          message: 'Acceso denegado. Crear Desde Cero requiere rol OWNER o MANAGER.',
        );
      }
      if (str.contains('MEMBERSHIP_NOT_ACTIVE')) {
        throw const CrearDesdeCeroException(
          code: 'MEMBERSHIP_NOT_ACTIVE',
          message: 'Membresía no activa. Se requiere estado ACTIVE.',
        );
      }
      if (str.contains('IDENTITY_NOT_FOUND')) {
        throw const CrearDesdeCeroException(
          code: 'IDENTITY_NOT_FOUND',
          message: 'No autorizado. Token de identidad requerido.',
        );
      }
      if (str.contains('ESTABLISHMENT_NOT_FOUND')) {
        throw const CrearDesdeCeroException(
          code: 'ESTABLISHMENT_NOT_FOUND',
          message: 'Establecimiento no encontrado.',
        );
      }
      throw CrearDesdeCeroException(
        code: 'CONNECTION_ERROR',
        message: 'Error de comunicación al compilar el Context Package: $e',
      );
    }
  }
}
