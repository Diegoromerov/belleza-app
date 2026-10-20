// frontend/test/services/biometric_consent_state_test.dart
//
// Y-F1f — el cliente distingue «tiene permiso» de «tiene el permiso vigente».
//
// Antes, con un solo booleano, un usuario que autorizó con el texto 2.0 pasaba de
// largo a la cámara sin ver nunca la sección de la huella de la foto que añadió la 2.1.

import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/services/biometric_service.dart';

void main() {
  group('BiometricConsentState — permiso concedido con el texto vigente', () {
    test('autorizado con la versión actual puede medir', () {
      final estado = BiometricConsentState.fromJson({
        'allowed': true,
        'outdated': false,
        'version_terms': '2.1',
        'consent': {'version_terms': '2.1', 'granted': true},
      });

      expect(estado.known, isTrue);
      expect(estado.granted, isTrue);
      expect(estado.outdated, isFalse);
      expect(estado.canScan, isTrue);
      expect(estado.needsReconsent, isFalse);
      expect(estado.version, '2.1');
    });
  });

  group('BiometricConsentState — permiso de una versión anterior', () {
    test('autorizado con 2.0 necesita re-consentimiento y no puede medir', () {
      final estado = BiometricConsentState.fromJson({
        'allowed': true,
        'outdated': true,
        'consent': {'version_terms': '2.0', 'granted': true},
      });

      expect(estado.granted, isTrue);
      expect(estado.outdated, isTrue);
      expect(estado.canScan, isFalse);
      expect(estado.needsReconsent, isTrue);
      expect(estado.version, '2.0');
    });

    test('la versión vigente llega del backend cuando viene', () {
      final estado = BiometricConsentState.fromJson({
        'allowed': true,
        'outdated': true,
        'current_version': '2.1',
        'consent': {'version_terms': '2.0'},
      });

      expect(estado.currentVersion, '2.1');
    });
  });

  group('BiometricConsentState — casos límite', () {
    test('sin permiso: ni mide ni pide re-consentimiento (pide consentimiento)', () {
      final estado = BiometricConsentState.fromJson({
        'allowed': false,
        'outdated': false,
        'consent': null,
      });

      expect(estado.granted, isFalse);
      expect(estado.canScan, isFalse);
      expect(estado.needsReconsent, isFalse);
      expect(estado.version, isNull);
    });

    test('sin current_version usa la constante del cliente, no un texto vacío', () {
      final estado = BiometricConsentState.fromJson({
        'allowed': true,
        'outdated': true,
        'consent': {'version_terms': '2.0'},
      });

      expect(estado.currentVersion, BiometricService.consentVersion);
    });

    test('respuesta incompleta no se toma por permiso', () {
      final estado = BiometricConsentState.fromJson({});
      expect(estado.granted, isFalse);
      expect(estado.canScan, isFalse);
    });

    test('estado desconocido: se declara desconocido, no «sin permiso»', () {
      expect(BiometricConsentState.unknown.known, isFalse);
      expect(BiometricConsentState.unknown.granted, isFalse);
      expect(BiometricConsentState.unknown.canScan, isFalse);
    });
  });

  group('paridad con el backend', () {
    test('la versión del cliente es la vigente del servidor (2.1)', () {
      // La misma comprobación existe en backend/src/tests/cierreFases.test.js leyendo
      // el fuente Dart; aquí se fija para que un cambio de versión no pase inadvertido.
      expect(BiometricService.consentVersion, '2.1');
    });
  });
}
