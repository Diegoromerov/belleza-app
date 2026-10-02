// frontend/test/services/crash_reporting_service_test.dart
//
// FIX-FLUTTER-07 (P1) — Contrato de comportamiento del crash reporting.
//
// Ejercita el CrashReportingService REAL con un http.Client inyectado
// (package:http/testing MockClient), sin red y sin mockear el servicio bajo
// prueba. Verifica el hallazgo: antes el crash sólo se encolaba localmente
// (flush a los 10s / umbral 10) y sin identificador de correlación, por lo
// que era imposible cruzar un crash de cliente con los logs del backend
// (que sí emiten traceId vía backend/src/middleware/traceId.js).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beauty_app/services/crash_reporting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> captured;

  CrashReportingService buildService({http.Client? client}) {
    return CrashReportingService(
      client: client ??
          MockClient((request) async {
            captured.add(request);
            return http.Response('{"message":"ok"}', 200);
          }),
      baseUrl: 'http://test.local',
      headerProvider: () async => <String, String>{'Content-Type': 'application/json'},
      correlationIdFactory: () => 'corr-fixed-0001',
      sessionIdFactory: () => 'sess-fixed-0001',
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    captured = <http.Request>[];
  });

  group('CrashReportingService', () {
    test('entrega el crash inmediatamente: un único evento, sin umbral de 10 '
        'ni espera del timer de 10s', () async {
      final service = buildService();
      final stopwatch = Stopwatch()..start();

      await service.reportAsyncError(StateError('boom'), StackTrace.current);
      stopwatch.stop();

      expect(captured.length, equals(1),
          reason: 'Un crash debe enviarse solo, no esperar batch de 10 eventos');
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)),
          reason: 'No debe esperar el timer de flush de 10s');
      expect(captured.single.url.path, equals('/api/analytics/events'));
      expect(captured.single.method, equals('POST'));
    });

    test('incluye X-Trace-Id == correlation_id para correlacionar con el backend',
        () async {
      final service = buildService();

      await service.reportAsyncError(StateError('boom'), StackTrace.current);

      final request = captured.single;
      final traceEntry = request.headers.entries.firstWhere(
        (entry) => entry.key.toLowerCase() == 'x-trace-id',
        orElse: () => const MapEntry<String, String>('', ''),
      );
      expect(traceEntry.value, isNotEmpty,
          reason: 'El backend correlaciona vía header X-Trace-Id');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final event = (body['events'] as List).first as Map<String, dynamic>;
      final metadata = event['metadata'] as Map<String, dynamic>;

      expect(metadata['correlation_id'], equals('corr-fixed-0001'));
      expect(traceEntry.value, equals(metadata['correlation_id']),
          reason: 'El header enviado al backend debe ser el mismo correlation_id');
    });

    test('el payload lleva tipo de crash, error, stack y session_id', () async {
      final service = buildService();

      await service.reportFlutterError(FlutterErrorDetails(
        exception: ArgumentError('widget roto'),
        stack: StackTrace.current,
      ));

      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      final event = (body['events'] as List).first as Map<String, dynamic>;
      final metadata = event['metadata'] as Map<String, dynamic>;

      expect(event['event_type'], equals('APP_CRASH_FLUTTER'));
      expect(metadata['session_id'], equals('sess-fixed-0001'));
      expect(metadata['correlation_id'], equals('corr-fixed-0001'));
      expect(metadata['error'], contains('widget roto'));
      expect(metadata['stack'], isNotEmpty);
      expect(metadata['platform'], isNotEmpty);
    });

    test('persiste el crash ante fallo de red y lo reenvía tras reinicio '
        'conservando el correlation_id original', () async {
      final failing = buildService(
        client: MockClient((request) async {
          captured.add(request);
          return http.Response('{"message":"down"}', 503);
        }),
      );

      await failing.reportAsyncError(StateError('offline'), StackTrace.current);
      expect(captured.length, equals(1), reason: 'primer intento de envío');

      // Simula reinicio de la app: nueva instancia sobre el mismo storage.
      final recovering = buildService();
      await recovering.init();

      expect(captured.length, equals(2),
          reason: 'El crash persistido debe reintentarse al iniciar');
      final retried = jsonDecode(captured.last.body) as Map<String, dynamic>;
      final event = (retried['events'] as List).first as Map<String, dynamic>;
      expect((event['metadata'] as Map<String, dynamic>)['correlation_id'],
          equals('corr-fixed-0001'),
          reason: 'El correlation_id debe sobrevivir al reinicio');
    });

    test('un crash operativo se reporta aunque la telemetría esté desactivada '
        '(no es un evento de producto)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'telemetry_enabled': false,
      });
      final service = buildService();

      await service.reportAsyncError(StateError('boom'), StackTrace.current);

      expect(captured.length, equals(1));
      expect(captured.every((r) => r.url.path == '/api/analytics/events'), isTrue,
          reason: 'No debe consultar preferencias de telemetría para decidir');
    });
  });
}
