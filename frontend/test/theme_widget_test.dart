import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/shared/theme.dart';

void main() {
  testWidgets('AppTheme widgets render with correct colors and decorations', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  Container(
                    key: const Key('primary_container'),
                    color: AppTheme.primary,
                  ),
                  Container(
                    key: const Key('background_container'),
                    color: AppTheme.background,
                  ),
                  Container(
                    key: const Key('shadow_container'),
                    decoration: BoxDecoration(
                      boxShadow: AppTheme.cardShadow,
                    ),
                  ),
                  TextField(
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icons.search,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Verify primary container color
    final primaryFinder = find.byKey(const Key('primary_container'));
    expect(primaryFinder, findsOneWidget);
    final Container primaryContainer = tester.widget(primaryFinder);
    expect(primaryContainer.color, AppTheme.primary);

    // Verify background container color
    final backgroundFinder = find.byKey(const Key('background_container'));
    expect(backgroundFinder, findsOneWidget);
    final Container backgroundContainer = tester.widget(backgroundFinder);
    expect(backgroundContainer.color, AppTheme.background);

    // Verify inputs decoration hint style
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final TextField textField = tester.widget(textFieldFinder);
    expect(textField.decoration?.hintText, 'Buscar...');
    expect(textField.decoration?.prefixIcon, isNotNull);
  });
}
