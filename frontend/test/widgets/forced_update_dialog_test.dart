// frontend/test/widgets/forced_update_dialog_test.dart
//
// FIX-FLUTTER-06 (P1): el diálogo de actualización forzada debe ser realmente
// BLOQUEANTE (no descartable por tap fuera ni por botón atrás) y el gate de
// arranque solo debe dispararlo cuando la política lo exige.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_app/services/app_update_service.dart';
import 'package:beauty_app/widgets/forced_update_dialog.dart';
import 'package:beauty_app/widgets/app_update_gate.dart';

void main() {
  const forcedDecision = AppUpdateDecision(
    status: AppUpdateStatus.forcedUpdate,
    currentVersion: '1.0.0',
    minimumVersion: '2.0.0',
    latestVersion: '2.1.0',
  );

  Future<void> abrirDialogo(WidgetTester tester, {VoidCallback? onUpdate}) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showForcedUpdateDialog(
                context,
                decision: forcedDecision,
                onUpdate: onUpdate,
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  }

  group('showForcedUpdateDialog — bloqueo real', () {
    testWidgets('muestra la versión instalada, la mínima y el CTA', (tester) async {
      await abrirDialogo(tester);

      expect(find.byType(ForcedUpdateDialog), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsWidgets);
      expect(find.textContaining('2.0.0'), findsWidgets);
      expect(find.text('Actualizar ahora'), findsOneWidget);
    });

    testWidgets('NO se descarta tocando fuera del diálogo (barrier)', (tester) async {
      await abrirDialogo(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(ForcedUpdateDialog), findsOneWidget);
      expect(find.text('Actualizar ahora'), findsOneWidget);
    });

    testWidgets('NO se descarta con el botón atrás del sistema', (tester) async {
      await abrirDialogo(tester);

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForcedUpdateDialog), findsOneWidget);
    });

    testWidgets('el CTA invoca el callback de actualización inyectado', (tester) async {
      var llamadas = 0;
      await abrirDialogo(tester, onUpdate: () => llamadas++);

      await tester.tap(find.text('Actualizar ahora'));
      await tester.pumpAndSettle();

      expect(llamadas, 1);
    });
  });

  group('AppUpdateGate — chequeo en arranque', () {
    testWidgets('bloquea mostrando el diálogo cuando hay update forzado',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AppUpdateGate(
          check: () async => forcedDecision,
          child: const Scaffold(body: Center(child: Text('HOME'))),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ForcedUpdateDialog), findsOneWidget);
    });

    testWidgets('no molesta al usuario cuando la app está al día', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AppUpdateGate(
          check: () async => const AppUpdateDecision.alDia(currentVersion: '1.0.0'),
          child: const Scaffold(body: Center(child: Text('HOME'))),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ForcedUpdateDialog), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('fail-open: si el chequeo lanza, la app sigue usable',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AppUpdateGate(
          check: () async => throw Exception('sin red'),
          child: const Scaffold(body: Center(child: Text('HOME'))),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ForcedUpdateDialog), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
