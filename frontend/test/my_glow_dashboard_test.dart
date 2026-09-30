// frontend/test/my_glow_dashboard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/profile/my_glow_dashboard_screen.dart';

void main() {
  testWidgets('MyGlowDashboardScreen initial render smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MyGlowDashboardScreen(),
      ),
    );

    // Debe renderizar el título del dashboard y la tarjeta activa del Glow Cycle
    expect(find.text('MI TABLERO GLOW CONCIERGE'), findsOneWidget);
    expect(find.text('GLOW CYCLE ACTIVO'), findsOneWidget);
    expect(find.text('+15 pts Delta'), findsOneWidget);
  });
}
