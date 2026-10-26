// test/screens/salon_shell_test.dart
// E-03 (D-GL-027) — compuerta del shell del salón.
//
// Qué fija esta prueba: que existan exactamente los cinco destinos que pide el
// plan (Agenda, Caja, Equipo, Servicios, Más), que el shell arranque en Agenda y
// que Caja diga la verdad (no está construida) en vez de pintar cifras.
//
// `cargarDatos: false` es la costura de test: sin ella, montar el shell dispara
// peticiones HTTP reales desde las pestañas.

import 'package:beauty_app/screens/salon/salon_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SalonShell(cargarDatos: false)),
    );
    await tester.pump();
  }

  testWidgets('el shell expone los cinco destinos del plan', (tester) async {
    await montar(tester);

    final barra = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(barra.items.length, 5);
    expect(
      barra.items.map((i) => i.label).toList(),
      ['Agenda', 'Caja', 'Equipo', 'Servicios', 'Más'],
    );
  });

  testWidgets('arranca en Agenda y sin citas lo dice', (tester) async {
    await montar(tester);

    expect(find.text('Sin citas por ahora'), findsOneWidget);
  });

  testWidgets('Caja admite que no está construida, no inventa cifras', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Caja'));
    await tester.pump();

    expect(find.text('Caja todavía no está disponible'), findsOneWidget);
    // Cualquier importe formateado sería señal de datos inventados.
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('Más lleva al resumen previo y marca lo que no existe aún', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Más'));
    await tester.pump();

    expect(find.text('Resumen del salón'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('No incluido en esta etapa'), findsOneWidget);
  });
}
