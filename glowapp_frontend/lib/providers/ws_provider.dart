import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowapp_frontend/services/ws_service.dart';

/// Provider that creates and holds a singleton instance of [WsService].
/// The service automatically connects when first accessed.
final wsProvider = Provider<WsService>((ref) {
  final service = WsService();
  // Connect immediately; the service handles duplicate calls.
  service.connect();
  // Return the service so UI can listen to its stream.
  return service;
});
