import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/ideas/aura_welcome_screen.dart';
import 'test_helpers.dart';

void main() {
  setUp(() {
    setupFlutterSecureStorageMock();
  });

  tearDown(() {
    resetFlutterSecureStorageMock();
  });

  testWidgets('AuraWelcomeScreen initializes without MissingPluginException', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuraWelcomeScreen(onStartRitual: null),
      ),
    );
    await tester.pump();
  });
}