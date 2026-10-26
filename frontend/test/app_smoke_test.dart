import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:beauty_app/main.dart' as app;

void main() {
  testWidgets('App shows mainScaffold', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    final scaffoldFinder = find.byKey(const ValueKey('mainScaffold'));
    expect(scaffoldFinder, findsOneWidget);
  });
}
