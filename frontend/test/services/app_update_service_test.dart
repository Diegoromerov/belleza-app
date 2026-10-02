// frontend/test/services/app_update_service_test.dart
//
// FIX-FLUTTER-06 (P1): la app no declaraba versión mínima soportada ni ejecutaba
// ningún chequeo de actualización forzada. Estos tests fijan el contrato:
//   1. La versión actual de la app debe declararse y coincidir con pubspec.yaml:4.
//   2. El backend expone `minimum_app_version` / `latest_app_version` en /api/health.
//   3. La app decide: al día / actualización opcional / actualización FORZADA.
//   4. El chequeo es fail-open: ante error de red o política inválida NUNCA bloquea.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:beauty_app/services/app_update_service.dart';

void main() {
  group('AppVersion — parseo y comparación semántica', () {
    test('parsea "1.0.0+1" en major/minor/patch y conserva el build number', () {
      final v = AppUpdateService.parseVersion('1.0.0+1');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 0);
      expect(v.patch, 0);
      expect(v.build, 1);
      expect(v.isPrerelease, isFalse);
    });

    test('parsea versiones cortas y basura sin lanzar', () {
      expect(AppUpdateService.parseVersion('1.2')?.minor, 2);
      expect(AppUpdateService.parseVersion('  2.3.4  ')?.patch, 4);
      expect(AppUpdateService.parseVersion(''), isNull);
      expect(AppUpdateService.parseVersion(null), isNull);
      expect(AppUpdateService.parseVersion('abc'), isNull);
      expect(AppUpdateService.parseVersion('v1.0.0'), isNotNull); // tolera prefijo v
    });

    test('compara numéricamente (1.10.0 > 1.9.9) y no por texto', () {
      expect(AppUpdateService.compareVersions('1.0.0', '1.0.1'), -1);
      expect(AppUpdateService.compareVersions('1.9.9', '1.10.0'), -1);
      expect(AppUpdateService.compareVersions('2.0.0', '1.99.99'), 1);
      expect(AppUpdateService.compareVersions('1.0.0+9', '1.0.0'), 0);
    });

    test('una prerelease es menor que su release', () {
      expect(AppUpdateService.compareVersions('1.2.0-beta.1', '1.2.0'), -1);
    });
  });

  group('AppUpdateService.evaluate — política de actualización', () {
    test('FUERZA la actualización cuando la versión instalada < mínima', () {
      final d = AppUpdateService.evaluate(
        currentVersion: '1.0.0',
        minimumVersion: '1.2.0',
        latestVersion: '1.3.0',
      );
      expect(d.status, AppUpdateStatus.forcedUpdate);
      expect(d.isForced, isTrue);
      expect(d.minimumVersion, '1.2.0');
    });

    test('NO fuerza cuando la instalada es exactamente la mínima', () {
      final d = AppUpdateService.evaluate(
        currentVersion: '1.2.0',
        minimumVersion: '1.2.0',
        latestVersion: '1.2.0',
      );
      expect(d.status, AppUpdateStatus.upToDate);
      expect(d.isForced, isFalse);
    });

    test('marca actualización OPCIONAL cuando supera la mínima pero no es la última', () {
      final d = AppUpdateService.evaluate(
        currentVersion: '1.1.0',
        minimumVersion: '1.0.0',
        latestVersion: '1.2.0',
      );
      expect(d.status, AppUpdateStatus.optionalUpdate);
      expect(d.isForced, isFalse);
      expect(d.isOptional, isTrue);
    });

    test('no fuerza con una versión instalada MÁS NUEVA que la mínima', () {
      final d = AppUpdateService.evaluate(
        currentVersion: '2.0.0',
        minimumVersion: '1.5.0',
        latestVersion: '1.5.0',
      );
      expect(d.status, AppUpdateStatus.upToDate);
    });

    test('fail-open: sin minimum_version declarada NUNCA bloquea', () {
      for (final minima in <String?>[null, '', '   ']) {
        final d = AppUpdateService.evaluate(
          currentVersion: '0.0.1',
          minimumVersion: minima,
        );
        expect(d.status, AppUpdateStatus.upToDate, reason: 'mínima=$minima');
      }
    });

    test('fail-open: política ilegible (no semántica) NUNCA bloquea', () {
      final d = AppUpdateService.evaluate(
        currentVersion: '1.0.0',
        minimumVersion: 'una-version-random',
        latestVersion: 'tampoco-valida',
      );
      expect(d.status, AppUpdateStatus.upToDate);
      expect(d.isForced, isFalse);
    });

    test('fail-open: versión instalada ilegible NUNCA bloquea', () {
      final d = AppUpdateService.evaluate(
        currentVersion: 'desconocida',
        minimumVersion: '1.0.0',
      );
      expect(d.status, AppUpdateStatus.upToDate);
    });

    test('expone una URL de tienda https válida para el CTA del bloqueo', () {
      expect(AppUpdateService.storeUrl.startsWith('https://'), isTrue);
      expect(Uri.tryParse(AppUpdateService.storeUrl), isNotNull);
    });
  });

  group('AppUpdateService — la versión declarada coincide con pubspec.yaml', () {
    test('currentVersion == version de pubspec.yaml (sin build number)', () {
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue,
          reason: 'flutter test debe correr desde la raíz del paquete');
      final line = pubspec
          .readAsLinesSync()
          .firstWhere((l) => l.trimLeft().startsWith('version:'));
      final raw = line.split(':')[1].trim(); // 1.0.0+1
      final expected = raw.split('+').first; // 1.0.0

      expect(AppUpdateService.currentVersion, expected,
          reason: 'AppUpdateService.currentVersion debe seguir a pubspec.yaml:4');
    });
  });

  group('AppUpdateService.check — contra GET /api/health', () {
    Future<http.Response> health(Map<String, dynamic> body) async =>
        http.Response(jsonEncode(body), 200,
            headers: {'content-type': 'application/json'});

    test('fuerza el update leyendo minimum_app_version de /api/health', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/api/health');
        return health({
          'status': 'OK',
          'minimum_app_version': '9.9.9',
          'latest_app_version': '9.9.9',
        });
      });

      final d = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: client,
          currentVersion: '1.0.0');

      expect(d.status, AppUpdateStatus.forcedUpdate);
      expect(d.minimumVersion, '9.9.9');
    });

    test('pasa sin bloqueo cuando la app instalada es la actual', () async {
      final client = MockClient((_) async => health({
            'status': 'OK',
            'minimum_app_version': '1.0.0',
            'latest_app_version': '1.0.0',
          }));

      final d = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: client,
          currentVersion: '1.0.0');

      expect(d.status, AppUpdateStatus.upToDate);
    });

    test('fail-open si /api/health no trae política de versión', () async {
      final client = MockClient((_) async => health({'status': 'OK'}));
      final d = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: client,
          currentVersion: '1.0.0');
      expect(d.status, AppUpdateStatus.upToDate);
    });

    test('fail-open si el endpoint no responde (error de red)', () async {
      final client = MockClient((_) async => throw const SocketException('offline'));
      final d = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: client,
          currentVersion: '1.0.0');
      expect(d.status, AppUpdateStatus.upToDate);
    });

    test('fail-open si el endpoint responde 500 o cuerpo no-JSON', () async {
      final c500 = MockClient((_) async => http.Response('boom', 500));
      final d500 = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: c500,
          currentVersion: '1.0.0');
      expect(d500.status, AppUpdateStatus.upToDate);

      final cHtml =
          MockClient((_) async => http.Response('<html>oops</html>', 200));
      final dHtml = await AppUpdateService.check(
          baseUrl: 'https://api.example.com',
          client: cHtml,
          currentVersion: '1.0.0');
      expect(dHtml.status, AppUpdateStatus.upToDate);
    });
  });
}
