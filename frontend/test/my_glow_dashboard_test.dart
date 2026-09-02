// frontend/test/my_glow_dashboard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/profile/my_glow_dashboard_screen.dart';

void main() {
  testWidgets('MyGlowDashboardScreen initial render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyGlowDashboardScreen(),
      ),
    );

    // Initial state should show loading indicator or title
    expect(find.text('MY GLOW — MI EVOLUCIÓN'), findsOneWidget);
  });
}
