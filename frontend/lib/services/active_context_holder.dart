// frontend/lib/services/active_context_holder.dart
import 'package:flutter/foundation.dart';

/// ActiveContextHolder
///
/// Gestiona en memoria (RAM) el `membership_id` activo para el runtime SaaS.
///
/// INVARIANTES ARQUITECTÓNICAS (NODO-07 FASE 1):
/// 1. Cero persistencia: NO almacena en SharedPreferences ni FlutterSecureStorage.
/// 2. Cero identificadores sintéticos: Prohibido active_salon_id, active_tenant_id, etc.
/// 3. Cero auto-selección o auto-restauración de contextos previos.
/// 4. Notificación reactiva: Implementa [ChangeNotifier] para que la UI o los
///    servicios puedan suscribirse y reaccionar a cambios explícitos de contexto.
class ActiveContextHolder extends ChangeNotifier {
  static final ActiveContextHolder _instance = ActiveContextHolder._internal();
  factory ActiveContextHolder() => _instance;
  ActiveContextHolder._internal();

  String? _activeMembershipId;

  /// Retorna el `membership_id` activo en memoria, o `null` si no hay contexto seleccionado.
  String? get activeMembershipId => _activeMembershipId;

  /// Retorna `true` si existe un contexto activo válido en memoria.
  bool get hasActiveContext =>
      _activeMembershipId != null && _activeMembershipId!.isNotEmpty;

  /// Establece explícitamente el `membership_id` activo y notifica a los oyentes.
  void setActiveMembershipId(String membershipId) {
    final trimmed = membershipId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('membership_id no puede ser vacío');
    }
    _activeMembershipId = trimmed;
    notifyListeners();
  }

  /// Limpia el contexto activo de la memoria y notifica a los oyentes.
  void clear() {
    _activeMembershipId = null;
    notifyListeners();
  }

  /// Método para reiniciar el estado en pruebas unitarias.
  @visibleForTesting
  void resetForTesting() {
    _activeMembershipId = null;
  }
}
