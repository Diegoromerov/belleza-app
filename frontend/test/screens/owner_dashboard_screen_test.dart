import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/owner_dashboard_metrics.dart';
import 'package:beauty_app/screens/owner/owner_dashboard_screen.dart';

void main() {
  group('Owner Dashboard Metrics & Widget Tests', () {
    test('OwnerDashboardMetrics.fromJson valida contrato estricto del backend', () {
      final fullJson = {
        'ingresos_brutos': 150000,
        'comision_plataforma': 15000,
        'impuestos_estado': 0,
        'ingresos_netos_negocio': 135000,
        'pago_neto_prestadores': 108000,
        'total_citas': 5,
        'sedes_compartidas': true,
        'prestadores_cross_tenant': true,
        'prestadores_externos': [{'provider_id': 3, 'nombre': 'Carlos'}],
        'advertencia': 'Atención: prestadores compartidos con otros salones',
      };

      final metrics = OwnerDashboardMetrics.fromJson(fullJson);

      expect(metrics.ingresosBrutos, equals(150000.0));
      expect(metrics.comisionPlataforma, equals(15000.0)); // singular contract
      expect(metrics.ingresosNetosNegocio, equals(135000.0)); // tomada del servidor
      expect(metrics.pagoNetoPrestadores, equals(108000.0));
      expect(metrics.prestadoresCrossTenant, isTrue);
      expect(metrics.advertencia, equals('Atención: prestadores compartidos con otros salones'));

      // Verificar que falta el campo comision_plataforma lanza ArgumentError
      final jsonInvalido = Map<String, dynamic>.from(fullJson)..remove('comision_plataforma');
      expect(() => OwnerDashboardMetrics.fromJson(jsonInvalido), throwsArgumentError);
    });

    testWidgets('Renderiza adecuadamente las tarjetas y el banner cross-tenant en OwnerDashboardScreen', (WidgetTester tester) async {
      final metricsJson = {
        'ingresos_brutos': 150000,
        'comision_plataforma': 15000,
        'impuestos_estado': 0,
        'ingresos_netos_negocio': 135000,
        'pago_neto_prestadores': 108000,
        'total_citas': 5,
        'sedes_compartidas': true,
        'prestadores_cross_tenant': true,
        'prestadores_externos': [{'provider_id': 3, 'nombre': 'Carlos'}],
        'advertencia': 'Atención: prestadores compartidos con otros salones',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerDashboardScreen(
            initialMetricsJson: metricsJson,
            initialSalones: const [
              {'id': 1, 'nombre_salon': 'Sede Principal'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Neto Negocio'), findsOneWidget);
      expect(find.text('\$135000'), findsOneWidget);

      expect(find.text('Neto Prestadores'), findsOneWidget);
      expect(find.text('\$108000'), findsOneWidget);

      expect(find.text('Comisión Plataforma'), findsOneWidget);
      expect(find.text('\$15000'), findsOneWidget);

      expect(find.text('ADVERTENCIA CROSS-TENANT'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);
    });

    testWidgets('Oculta el banner cross-tenant cuando prestadores_cross_tenant es false', (WidgetTester tester) async {
      final metricsJson = {
        'ingresos_brutos': 100000,
        'comision_plataforma': 10000,
        'impuestos_estado': 0,
        'ingresos_netos_negocio': 90000,
        'pago_neto_prestadores': 70000,
        'total_citas': 3,
        'sedes_compartidas': false,
        'prestadores_cross_tenant': false,
        'prestadores_externos': [],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerDashboardScreen(
            initialMetricsJson: metricsJson,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADVERTENCIA CROSS-TENANT'), findsNothing);
      expect(find.text('Neto Negocio'), findsOneWidget);
      expect(find.text('\$90000'), findsOneWidget);
    });
  });
}
