// E-04 (D-GL-027): un plan sin TEAM_MANAGEMENT ve Equipo bloqueado, y con la
// capacidad lo ve abierto. Se inyectan las capacidades para no depender de red.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/salon/salon_shell.dart';
import 'package:beauty_app/widgets/locked_feature_card.dart';

Widget _app({required List<String> entitlements, String plan = 'FREEMIUM'}) {
  return MaterialApp(
    home: SalonShell(
      cargarDatos: false,
      entitlements: entitlements,
      plan: plan,
    ),
  );
}

void main() {
  testWidgets('sin TEAM_MANAGEMENT, Equipo muestra la tarjeta de bloqueo',
      (tester) async {
    await tester.pumpWidget(_app(entitlements: const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Equipo'));
    await tester.pumpAndSettle();

    expect(find.byType(LockedFeatureCard), findsOneWidget);
    expect(find.textContaining('TEAM_MANAGEMENT'), findsOneWidget);
    expect(find.textContaining('FREEMIUM'), findsOneWidget);
    // No debe aparecer el contenido real del equipo.
    expect(find.textContaining('Todavía no hay equipo'), findsNothing);
  });

  testWidgets('con TEAM_MANAGEMENT, Equipo se abre y no hay bloqueo',
      (tester) async {
    await tester.pumpWidget(
      _app(entitlements: const ['TEAM_MANAGEMENT'], plan: 'PRO'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Equipo'));
    await tester.pumpAndSettle();

    expect(find.byType(LockedFeatureCard), findsNothing);
    expect(find.textContaining('Todavía no hay equipo'), findsOneWidget);
  });
}
