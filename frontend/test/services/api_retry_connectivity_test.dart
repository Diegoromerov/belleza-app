// test/services/api_retry_connectivity_test.dart
//
// FIX-FLUTTER-08 (P1) — Red de resiliencia de ApiService.
//
// Hallazgo del audit: api_service.dart tenía 50 timeouts fijos de 30s,
// 0 reintentos y ninguna detección de conectividad.
//
// Estos tests definen el comportamiento esperado ANTES de la implementación
// (TDD): clasificación de errores reintentables, backoff exponencial,
// agotamiento del presupuesto de reintentos y corte por falta de conexión.
//
// No se añaden dependencias: el sondeo de conectividad es inyectable, por lo
// que las pruebas son deterministas y no tocan la red.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_app/services/api_service.dart';
import 'package:beauty_app/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ConnectivityService.resetForTesting();
  });

  // ───────────────────────────────────────────────────────────────
  // Clasificación de errores
  // ───────────────────────────────────────────────────────────────
  group('ApiService.isRetryableError', () {
    test('marca como reintentables los errores 5xx del servidor', () {
      expect(ApiService.isRetryableError(Exception('500 Internal Server Error')),
          isTrue);
      expect(ApiService.isRetryableError(Exception('502 Bad Gateway')), isTrue);
      expect(ApiService.isRetryableError(Exception('503 Service Unavailable')),
          isTrue);
      expect(ApiService.isRetryableError(Exception('504 Gateway Timeout')),
          isTrue);
    });

    test('marca como reintentables los fallos de red y de timeout', () {
      expect(ApiService.isRetryableError(const SocketException('conn refused')),
          isTrue);
      expect(ApiService.isRetryableError(TimeoutException('timeout')), isTrue);
      expect(ApiService.isRetryableError(Exception('Connection refused')),
          isTrue);
      expect(ApiService.isRetryableError(Exception('SocketException: closed')),
          isTrue);
      expect(ApiService.isRetryableError(const OfflineException()), isTrue);
    });

    test('NO marca como reintentables los errores de cliente 4xx', () {
      expect(ApiService.isRetryableError(Exception('400 Bad Request')), isFalse);
      expect(ApiService.isRetryableError(Exception('401 Unauthorized')),
          isFalse);
      expect(ApiService.isRetryableError(Exception('403 Forbidden')), isFalse);
      expect(ApiService.isRetryableError(Exception('404 Not Found')), isFalse);
      expect(ApiService.isRetryableError(Exception('Error 422')),
          isFalse);
      expect(
          ApiService.isRetryableError(Exception('Validación fallida')), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Motor de reintentos con backoff exponencial
  // ───────────────────────────────────────────────────────────────
  group('ApiService.runWithRetry — backoff exponencial', () {
    test('reintenta un fallo transitorio y devuelve el resultado', () async {
      var calls = 0;
      final delays = <Duration>[];

      final result = await ApiService.runWithRetry<String>(
        () async {
          calls++;
          if (calls < 3) throw const SocketException('connection refused');
          return 'ok';
        },
        isConnected: () async => true,
        delay: (d) async => delays.add(d),
      );

      expect(result, 'ok');
      expect(calls, 3);
      expect(delays, <Duration>[
        ApiService.baseRetryDelay,
        ApiService.baseRetryDelay * 2,
      ]);
    });

    test('NO reintenta errores no reintentables (4xx) y los propaga', () async {
      var calls = 0;

      await expectLater(
        ApiService.runWithRetry<String>(
          () async {
            calls++;
            throw Exception('400 Bad Request');
          },
          isConnected: () async => true,
          delay: (_) async {},
        ),
        throwsA(predicate((e) => e.toString().contains('400'))),
      );

      expect(calls, 1, reason: 'un 4xx no debe reintentarse');
    });

    test('agota el presupuesto de reintentos y propaga el último error',
        () async {
      var calls = 0;
      final delays = <Duration>[];

      await expectLater(
        ApiService.runWithRetry<String>(
          () async {
            calls++;
            throw const SocketException('still down');
          },
          isConnected: () async => true,
          delay: (d) async => delays.add(d),
        ),
        throwsA(isA<SocketException>()),
      );

      expect(calls, ApiService.maxRetries + 1,
          reason: 'intento inicial + maxRetries reintentos');
      expect(delays, <Duration>[
        ApiService.baseRetryDelay,
        ApiService.baseRetryDelay * 2,
        ApiService.baseRetryDelay * 4,
      ]);
    });

    test('no ejecuta la petición cuando no hay conectividad', () async {
      var calls = 0;

      await expectLater(
        ApiService.runWithRetry<String>(
          () async {
            calls++;
            return 'nunca';
          },
          isConnected: () async => false,
          delay: (_) async {},
        ),
        throwsA(isA<OfflineException>()),
      );

      expect(calls, 0, reason: 'sin red no se debe golpear el endpoint');
    });

    test('reanuda la petición cuando vuelve la conectividad', () async {
      var calls = 0;
      var checks = 0;

      final result = await ApiService.runWithRetry<String>(
        () async {
          calls++;
          return 'reconectado';
        },
        isConnected: () async {
          checks++;
          return checks > 2; // offline en los primeros 2 sondeos
        },
        delay: (_) async {},
      );

      expect(result, 'reconectado');
      expect(calls, 1);
      expect(checks, 3);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Detección de conectividad (sin dependencias externas)
  // ───────────────────────────────────────────────────────────────
  group('ConnectivityService', () {
    test('reporta conectado cuando el sondeo tiene éxito', () async {
      ConnectivityService.probe = () async => true;

      expect(await ConnectivityService.check(), isTrue);
      expect(ConnectivityService.isConnected, isTrue);
    });

    test('reporta desconectado cuando el sondeo falla', () async {
      ConnectivityService.probe =
          () async => throw const SocketException('no route to host');

      expect(await ConnectivityService.check(), isFalse);
      expect(ConnectivityService.isConnected, isFalse);
    });

    test('reporta desconectado ante errores inesperados del sondeo', () async {
      ConnectivityService.probe = () async => throw StateError('boom');

      expect(await ConnectivityService.check(), isFalse);
      expect(ConnectivityService.isConnected, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Configuración centralizada (fin de los 50 timeouts mágicos)
  // ───────────────────────────────────────────────────────────────
  group('Configuración de resiliencia', () {
    test('centraliza timeout y política de reintentos', () {
      expect(ApiService.requestTimeout, const Duration(seconds: 30));
      expect(ApiService.maxRetries, 3);
      expect(ApiService.baseRetryDelay, lessThan(ApiService.requestTimeout));
      expect(ApiService.baseRetryDelay, greaterThan(Duration.zero));
    });

    test('POST falla rápido con OfflineException cuando no hay red', () async {
      ConnectivityService.probe = () async => false;

      await expectLater(
        ApiService.post('/api/bookings', <String, dynamic>{'x': 1}),
        throwsA(isA<OfflineException>()),
      );
    });

    test('GET falla rápido con OfflineException cuando no hay red', () async {
      ConnectivityService.probe = () async => false;

      await expectLater(
        ApiService.get('/api/providers'),
        throwsA(isA<OfflineException>()),
      );
    });
  });
}
