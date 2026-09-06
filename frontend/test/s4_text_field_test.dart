import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/design/components/s4_text_field.dart';

void main() {
  testWidgets('S4TextField renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: S4TextField(
          label: 'Test',
          hint: 'Test hint',
        ),
      ),
    ));

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Test hint'), findsOneWidget);
  });
}