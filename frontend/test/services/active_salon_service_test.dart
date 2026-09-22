import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beauty_app/services/active_salon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveSalonService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ActiveSalonService.instance.init();
    });

    test('Normalización estricta de activeSalonId', () {
      expect(ActiveSalonService.normalizeSalonId(null), isNull);
      expect(ActiveSalonService.normalizeSalonId(''), isNull);
      expect(ActiveSalonService.normalizeSalonId('null'), isNull);
      expect(ActiveSalonService.normalizeSalonId('0'), isNull);
      expect(ActiveSalonService.normalizeSalonId('undefined'), isNull);
      expect(ActiveSalonService.normalizeSalonId(0), isNull);
      expect(ActiveSalonService.normalizeSalonId(-5), isNull);
      expect(ActiveSalonService.normalizeSalonId('invalid'), isNull);

      expect(ActiveSalonService.normalizeSalonId(101), equals(101));
      expect(ActiveSalonService.normalizeSalonId('101'), equals(101));
      expect(ActiveSalonService.normalizeSalonId(' 205 '), equals(205));
    });

    test('setActiveSalon persiste y notifica listeners', () async {
      int notifyCount = 0;
      ActiveSalonService.instance.addListener(() {
        notifyCount++;
      });

      await ActiveSalonService.instance.setActiveSalon(42);
      expect(ActiveSalonService.instance.activeSalonId, equals(42));
      expect(notifyCount, equals(1));

      await ActiveSalonService.instance.clear();
      expect(ActiveSalonService.instance.activeSalonId, isNull);
      expect(notifyCount, equals(2));
    });
  });
}
