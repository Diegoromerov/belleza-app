// frontend/test/services/crash_reporting_wiring_test.dart
//
// FIX-FLUTTER-07 (P1) — Guarda estática de wiring.
//
// Hallazgo reproducido: main.dart:74-129 sólo hacía logging local vía
// AnalyticsService().logEvent (evento encolado, se descarta si el usuario
// desactiva telemetría, sin X-Trace-Id) => ceguera en producción.
//
// Esta guarda falla mientras no exista un CrashReportingService con
// correlación backend (X-Trace-Id / correlation_id) cableado en main.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readLib(String relative) {
  final candidates = <String>[
    relative,
    'frontend/$relative',
    '../$relative',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      // CRLF-safe: el repo usa core.autocrlf=true en Windows.
      return file.readAsStringSync().replaceAll('\r\n', '\n');
    }
  }
  throw StateError(
      'No se encontró "$relative" (cwd=${Directory.current.path}). '
      'La integración de crash reporting NO existe todavía.');
}

void main() {
  group('FIX-FLUTTER-07 — crash reporting con correlación backend', () {
    test('existe CrashReportingService con correlación (X-Trace-Id / correlation_id)',
        () {
      final source = _readLib('lib/services/crash_reporting_service.dart');
      expect(source, contains('class CrashReportingService'));
      expect(source, contains('X-Trace-Id'));
      expect(source, contains('correlation_id'));
    });

    test('main.dart delega los handlers de crash en CrashReportingService', () {
      final main = _readLib('lib/main.dart');
      expect(main, contains('services/crash_reporting_service.dart'));
      expect(main, contains('CrashReportingService'));
      expect(main, contains('reportFlutterError'));
      expect(main, contains('reportAsyncError'));
    });

    test('el bloque de crash de main.dart ya no encola sólo en AnalyticsService',
        () {
      final main = _readLib('lib/main.dart');
      final start = main.indexOf('FlutterError.onError');
      final end = main.indexOf('runZonedGuarded');
      expect(start, greaterThan(-1), reason: 'FlutterError.onError debe existir');
      expect(end, greaterThan(start), reason: 'runZonedGuarded debe existir');
      final crashBlock = main.substring(start, end);
      expect(
        crashBlock,
        isNot(contains('AnalyticsService().logEvent')),
        reason: 'Un crash no debe depender del batching/opt-out de AnalyticsService',
      );
    });
  });
}
