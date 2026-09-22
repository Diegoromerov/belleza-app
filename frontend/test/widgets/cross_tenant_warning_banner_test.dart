import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/widgets/owner/cross_tenant_warning_banner.dart';

void main() {
  group('CrossTenantWarningBanner Widget Tests', () {
    testWidgets('Muestra el banner cuando isCrossTenant es true con advertencia y colaboradores', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrossTenantWarningBanner(
              isCrossTenant: true,
              advertencia: 'Atención: prestadores externos detectados',
              prestadoresExternos: [
                {'nombre': 'Carlos Pérez', 'provider_id': 10},
                {'nombre': 'Ana Gómez', 'provider_id': 12},
              ],
            ),
          ),
        ),
      );

      expect(find.text('ADVERTENCIA CROSS-TENANT'), findsOneWidget);
      expect(find.text('Atención: prestadores externos detectados'), findsOneWidget);
      expect(find.text('Carlos Pérez'), findsOneWidget);
      expect(find.text('Ana Gómez'), findsOneWidget);
    });

    testWidgets('Oculta el banner cuando isCrossTenant es false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrossTenantWarningBanner(
              isCrossTenant: false,
              advertencia: 'No debería mostrarse',
            ),
          ),
        ),
      );

      expect(find.text('ADVERTENCIA CROSS-TENANT'), findsNothing);
      expect(find.text('No debería mostrarse'), findsNothing);
    });
  });
}
