import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/shared/calculations.dart';

void main() {
  group('Calculations Unit Tests', () {
    test('calculateTotalWithTip calculates correct total', () {
      final total = Calculations.calculateTotalWithTip(100.0, 15.0);
      expect(total, 115.0);
    });

    test('calculateTipAmount calculates correct tip', () {
      final tip5 = Calculations.calculateTipAmount(200.0, 5.0);
      expect(tip5, 10.0);

      final tip10 = Calculations.calculateTipAmount(200.0, 10.0);
      expect(tip10, 20.0);

      final tip15 = Calculations.calculateTipAmount(200.0, 15.0);
      expect(tip15, 30.0);
    });

    test('calculatePlatformFee calculates correct platform fee', () {
      final fee = Calculations.calculatePlatformFee(150.0, 12.0); // 12% fee
      expect(fee, 18.0);
    });

    test('calculateProviderEarnings calculates correct net earnings', () {
      // 100 total, 10 tip, 10% platform fee on total (fee = 10)
      // earnings = 100 - 10 (fee) + 10 (tip) = 100
      final earnings = Calculations.calculateProviderEarnings(100.0, 10.0, 10.0);
      expect(earnings, 100.0);
    });
  });
}
