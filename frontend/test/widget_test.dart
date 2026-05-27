import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/main.dart';

void main() {
  testWidgets('BeautyApp carga correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const BeautyApp());
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
