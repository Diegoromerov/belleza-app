import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/booking_screen.dart';
import 'package:beauty_app/shared/theme.dart';
import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupFlutterSecureStorageMock();
  });

  tearDownAll(() {
    resetFlutterSecureStorageMock();
  });

  testWidgets('la cabecera del calendario no desborda a 390 dp (RenderFlex overflow check)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
        ),
        home: Scaffold(
          body: BookingScreen(
            providerId: 'prov-123',
            services: const [
              {
                'id': 'srv-1',
                'name': 'Corte y Cepillado Profesional',
                'price': 45000,
                'duration': 45,
                'category': 'Cabello'
              }
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Aserción estricta: ninguna excepción de renderizado u overflow en layout a 390 dp
    expect(tester.takeException(), isNull);
  });
}
