// Test estático de seguridad — FIX-FLUTTER-03 (P1)
//
// Hallazgo: el JWT se persistía en SharedPreferences, que en Flutter Web mapea a
// `window.localStorage` EN TEXTO PLANO. Además, cuando `flutter_secure_storage`
// lanzaba en web, `AuthService.getToken()` y `ApiService._getToken()` caían a un
// fallback leyendo el token desde SharedPreferences. Cualquier XSS podía
// exfiltrar la sesión con `window.localStorage.getItem('token')`.
//
// Esta guarda escanea el código fuente (dart:io) y falla si vuelve a aparecer el
// patrón `prefs.setString('token', ...)` / `prefs.getString('token')`, o si el
// token deja de leerse exclusivamente desde SecureStorageService.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Localiza la raíz del paquete Flutter subiendo desde el cwd.
String _packageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}

/// `prefs.setString('token', ...)`, `prefs.getString('token')`, etc.
final RegExp _prefsTokenRegex =
    RegExp(r"""prefs?\s*\.\s*(?:set|get)String\s*\(\s*['"]token['"]""");

/// Lee el token desde flutter_secure_storage (directo o vía servicio).
final RegExp _secureReadTokenRegex =
    RegExp(r"""\.read\(\s*(?:key\s*:\s*)?['"]token['"]""");

List<String> _scanLibForPrefsToken() {
  final root = _packageRoot();
  final libDir = Directory('$root/lib');
  final violations = <String>[];
  if (!libDir.existsSync()) return violations;
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (_prefsTokenRegex.hasMatch(lines[i])) {
        final rel = entity.path.replaceAll(root, '').replaceAll(r'\', '/');
        violations.add('$rel:${i + 1}: ${lines[i].trim()}');
      }
    }
  }
  return violations;
}

void main() {
  group('FIX-FLUTTER-03 · El JWT nunca se persiste en SharedPreferences/localStorage', () {
    test('Ningún archivo de lib/ escribe o lee el token vía SharedPreferences',
        () {
      final violations = _scanLibForPrefsToken();
      expect(
        violations,
        isEmpty,
        reason: 'El token JWT NO debe tocarse en SharedPreferences (localStorage '
            'en web, legible por XSS). Violaciones:\n${violations.join('\n')}',
      );
    });

    test('auth_service.dart lee el token únicamente desde SecureStorageService',
        () {
      final root = _packageRoot();
      final src = File('$root/lib/services/auth_service.dart').readAsStringSync();
      expect(src.contains('SecureStorageService()'), isTrue,
          reason: 'auth_service debe usar SecureStorageService');
      expect(_secureReadTokenRegex.hasMatch(src), isTrue,
          reason: 'auth_service debe leer el token con .read(\'token\')');
    });

    test('api_service.dart lee el token desde SecureStorageService (sin fallback)',
        () {
      final root = _packageRoot();
      final src = File('$root/lib/services/api_service.dart').readAsStringSync();
      expect(src.contains('SecureStorageService()'), isTrue,
          reason: 'api_service debe unificar la lectura del token en '
              'SecureStorageService (única fuente con config web)');
      expect(_secureReadTokenRegex.hasMatch(src), isTrue);
    });

    test('No sobrevive ningún fallback explícito a SharedPreferences para el token',
        () {
      final root = _packageRoot();
      final src = File('$root/lib/services/auth_service.dart').readAsStringSync();
      expect(src.contains("prefs.getString('token')"), isFalse,
          reason: 'fallback inseguro eliminado');
      expect(src.contains("prefs.setString('token'"), isFalse,
          reason: 'persistencia en texto plano eliminada');
    });
  });
}
