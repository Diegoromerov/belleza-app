// frontend/test/permission_rationale_service_test.dart
//
// FIX-FLUTTER-02 — P1: Android Permisos Sin Description.
// Cobertura del rationale EN UI: mensaje de justificación por permiso y
// diálogo mostrado al usuario ANTES de solicitar el permiso al SO.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:beauty_app/services/permission_rationale_service.dart';

void main() {
  group('PermissionRationaleService (FIX-FLUTTER-02)', () {
    test('reasonFor explica por qué se necesita cada permiso', () {
      for (final p in <Permission>[
        Permission.location,
        Permission.microphone,
      ]) {
        final reason = PermissionRationaleService.reasonFor(p);
        expect(reason.trim(), isNotEmpty,
            reason: 'El rationale para $p está vacío');
      }
    });

    testWidgets('showRationaleDialog presenta el texto y acepta continuar',
        (tester) async {
      bool? decision;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                decision = await PermissionRationaleService.showRationaleDialog(
                  ctx,
                  Permission.location,
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('ubicación', findRichText: true),
        findsWidgets,
        reason: 'El diálogo no explica el uso de la ubicación',
      );

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(decision, isTrue);
    });

    testWidgets('showRationaleDialog respeta la cancelación del usuario',
        (tester) async {
      bool? decision;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                decision = await PermissionRationaleService.showRationaleDialog(
                  ctx,
                  Permission.microphone,
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(decision, isFalse);
    });
  });
}
