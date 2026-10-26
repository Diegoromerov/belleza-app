// E-05 (D-GL-027) — Caja: lo que se muestra sale de los datos, no de una suma
// hecha en el cliente. Sin movimientos, la pantalla lo dice.
import 'package:beauty_app/screens/salon/caja_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _resumen({
  num ingresos = 150000,
  num gastos = 50000,
  num neto = 100000,
  String alcance = 'SALON',
  bool puedeRegistrar = true,
}) =>
    {
      'success': true,
      'ingresos': ingresos,
      'gastos': gastos,
      'neto': neto,
      'movimientos': 2,
      'alcance': alcance,
      'mi_rol': alcance == 'SALON' ? 'DUEÑO' : 'EMPLEADO',
      'puede_registrar': puedeRegistrar,
    };

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  test('el formato COP usa punto de miles y no inventa decimales', () {
    expect(formatearCop(1234567), r'$1.234.567');
    expect(formatearCop(0), r'$0');
    expect(formatearCop(-50000, conSigno: true), '−\$50.000');
    expect(formatearCop(80000, conSigno: true), '+\$80.000');
  });

  testWidgets('muestra los totales de la API y la lista de movimientos',
      (tester) async {
    await tester.pumpWidget(_app(CajaScreen(
      salonId: 1,
      cargarDatos: false,
      resumenInicial: _resumen(),
      movimientosIniciales: const [
        {
          'tipo': 'INGRESO', 'concepto': 'SERVICIO', 'monto': 150000,
          'metodo_pago': 'EFECTIVO', 'constancia_ref': 'CJ-1-20261026-AB12',
          'fecha_movimiento': '2026-10-26T15:00:00Z',
        },
        {
          'tipo': 'GASTO', 'concepto': 'INSUMO', 'monto': 50000,
          'metodo_pago': 'TARJETA', 'constancia_ref': 'CJ-1-20261026-CD34',
          'fecha_movimiento': '2026-10-26T16:00:00Z',
        },
      ],
    )));

    expect(find.text('Caja del salón'), findsOneWidget);
    expect(find.text(r'$150.000'), findsOneWidget);
    expect(find.text(r'$50.000'), findsOneWidget);
    expect(find.text(r'$100.000'), findsOneWidget);
    expect(find.textContaining('SERVICIO'), findsOneWidget);
    expect(find.textContaining('INSUMO'), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
  });

  testWidgets('sin movimientos lo dice en vez de pintar ceros con vida',
      (tester) async {
    await tester.pumpWidget(_app(CajaScreen(
      salonId: 1,
      cargarDatos: false,
      resumenInicial: _resumen(ingresos: 0, gastos: 0, neto: 0),
    )));

    expect(find.textContaining('Aún no hay movimientos en este periodo'),
        findsOneWidget);
  });

  testWidgets('un colaborador ve lo suyo y no puede registrar', (tester) async {
    await tester.pumpWidget(_app(CajaScreen(
      salonId: 1,
      cargarDatos: false,
      resumenInicial: _resumen(
        ingresos: 20000, gastos: 0, neto: 20000,
        alcance: 'PROPIO', puedeRegistrar: false,
      ),
    )));

    expect(find.text('Mis movimientos'), findsOneWidget);
    expect(find.textContaining('Ves sólo los movimientos a tu nombre'),
        findsOneWidget);
    expect(find.text('Registrar'), findsNothing);
  });

  testWidgets('declara que la constancia no es factura electrónica',
      (tester) async {
    await tester.pumpWidget(_app(CajaScreen(
      salonId: 1,
      cargarDatos: false,
      resumenInicial: _resumen(),
    )));

    expect(find.textContaining('No son facturas electrónicas'), findsOneWidget);
  });
}
