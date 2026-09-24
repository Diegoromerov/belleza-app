// frontend/lib/services/hub_salon_service.dart
import 'package:flutter/foundation.dart';
import '../models/saas/hub_salon_model.dart';
import 'api_service.dart';

/// HubSalonException
///
/// Excepción de dominio para capturar fallos en las consultas del Hub Salón.
class HubSalonException implements Exception {
  final String message;
  final int? statusCode;

  HubSalonException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'HubSalonException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// HubSalonService
///
/// Servicio cliente para consultar el resumen operativo y el directorio de personal
/// del establecimiento activo en el runtime SaaS.
///
/// INVARIANTES ARQUITECTÓNICAS (NODO-07 FASE 4):
/// 1. Solo lectura pura: Jamás muta ActiveContextHolder durante sus consultas.
/// 2. Transporte contextual: Utiliza ApiService para inyectar x-active-membership-id.
/// 3. Cero persistencia: No almacena los datos en disco ni memoria persistente.
/// 4. Aislamiento de recursos: Trata summary y staff como recursos independientes
///    para permitir estados de éxito parcial (partial_success).
class HubSalonService {
  final Future<dynamic> Function(String path) _apiGet;

  HubSalonService({Future<dynamic> Function(String path)? apiGet})
      : _apiGet = apiGet ?? ApiService.get;

  /// Obtiene el resumen operacional de la sede activa.
  /// Endpoint: `GET /api/v1/saas/hub/summary`
  Future<HubSummaryResponse> getSummary() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/summary');
      if (response is Map<String, dynamic>) {
        return HubSummaryResponse.fromJson(response);
      }
      throw HubSalonException(
        message: 'Formato de respuesta inválido en Hub Summary',
      );
    } catch (e) {
      if (e is HubSalonException) rethrow;
      throw HubSalonException(
        message: 'Error al consultar resumen de sede: ${e.toString()}',
      );
    }
  }

  /// Obtiene el listado de personal activo de la sede.
  /// Endpoint: `GET /api/v1/saas/hub/staff`
  Future<HubStaffResponse> getStaff() async {
    try {
      final response = await _apiGet('/api/v1/saas/hub/staff');
      if (response is Map<String, dynamic>) {
        return HubStaffResponse.fromJson(response);
      }
      throw HubSalonException(
        message: 'Formato de respuesta inválido en Hub Staff',
      );
    } catch (e) {
      if (e is HubSalonException) rethrow;
      throw HubSalonException(
        message: 'Error al consultar personal de sede: ${e.toString()}',
      );
    }
  }

  /// Carga concurrente protegida del Cockpit.
  /// Si el resumen falla, lanza la excepción.
  /// Si el resumen tiene éxito pero el personal falla, retorna `HubCockpitData` con `staffError` (partial_success).
  Future<HubCockpitData> getCockpitData() async {
    final summaryFuture = getSummary();
    final staffFuture = getStaff();

    // 1. Esperar el resumen operacional (recurso crítico)
    final summary = await summaryFuture;

    // 2. Intentar resolver el personal sin abortar el summary si falla
    HubStaffResponse? staff;
    String? staffError;

    try {
      staff = await staffFuture;
    } catch (e) {
      staffError = e.toString();
      if (kDebugMode) {
        print('⚠️ HubSalonService: Falló la consulta de staff pero el summary es válido: $e');
      }
    }

    return HubCockpitData(
      summary: summary,
      staff: staff,
      staffError: staffError,
    );
  }
}
