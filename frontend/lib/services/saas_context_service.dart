// frontend/lib/services/saas_context_service.dart
import '../models/saas/available_context_model.dart';
import 'api_service.dart';

/// SaaSContextService
///
/// Servicio cliente para consultar la resolución de contextos SaaS disponibles.
///
/// INVARIANTES ARQUITECTÓNICAS (NODO-07 FASE 3):
/// 1. Solo lectura pura: Jamás muta ActiveContextHolder durante la consulta.
/// 2. Cero persistencia: No almacena la respuesta en SecureStorage ni SharedPreferences.
/// 3. Cero navegación: No realiza push/pop de rutas.
/// 4. Cero autorización: No interpreta roles ni concede permisos en cliente.
class SaaSContextService {
  /// Consulta los contextos disponibles para la identidad autenticada.
  static Future<AvailableContextResponse> fetchAvailableContexts() async {
    final response = await ApiService.get('/api/v1/saas/context/available');
    if (response is Map<String, dynamic>) {
      return AvailableContextResponse.fromJson(response);
    }
    throw Exception('Formato de respuesta inválido en Available Context');
  }
}
