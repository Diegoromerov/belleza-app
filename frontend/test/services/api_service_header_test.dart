import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beauty_app/services/active_salon_service.dart';
import 'package:beauty_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Header Injection & SwitchSalon Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ActiveSalonService.instance.init();
    });

    test('Inyecta la cabecera x-active-salon-id si hay sede activa válida', () async {
      await ActiveSalonService.instance.setActiveSalon(105);

      final headers = await ApiService.getAuthHeaders();
      expect(headers['x-active-salon-id'], equals('105'));
    });

    test('Omite la cabecera x-active-salon-id si activeSalonId es nulo o normalizado a nulo', () async {
      await ActiveSalonService.instance.clear();
      final headers1 = await ApiService.getAuthHeaders();
      expect(headers1.containsKey('x-active-salon-id'), isFalse);

      await ActiveSalonService.instance.setActiveSalon(0);
      final headers2 = await ApiService.getAuthHeaders();
      expect(headers2.containsKey('x-active-salon-id'), isFalse);
    });

    group('switchSalon Store Protection Tests (4 Casos sobre applySwitchSalonResponse)', () {
      test('Caso 1: Respuesta sin active_salon_id NO altera el store', () async {
        await ActiveSalonService.instance.setActiveSalon(10);

        final res = await ActiveSalonService.applySwitchSalonResponse({'success': true, 'message': 'Ok sin id'});
        expect(res, isFalse);
        expect(ActiveSalonService.instance.activeSalonId, equals(10));
      });

      test('Caso 2: Respuesta con success: false NO altera el store aun con active_salon_id válido', () async {
        await ActiveSalonService.instance.setActiveSalon(15);

        final res = await ActiveSalonService.applySwitchSalonResponse({'success': false, 'active_salon_id': 42});
        expect(res, isFalse);
        expect(ActiveSalonService.instance.activeSalonId, equals(15));
      });

      test('Caso 3: active_salon_id inválido (0, null, \'\', -1, \'invalid\') NO altera el store', () async {
        await ActiveSalonService.instance.setActiveSalon(20);

        final invalidIds = [0, 'null', '', 'invalid', -1];
        for (final raw in invalidIds) {
          final res = await ActiveSalonService.applySwitchSalonResponse({'success': true, 'active_salon_id': raw});
          expect(res, isFalse);
        }

        expect(ActiveSalonService.instance.activeSalonId, equals(20));
      });

      test('Caso 4: active_salon_id válido (42) con success: true actualiza el store y notifica listeners', () async {
        await ActiveSalonService.instance.clear();
        int notificationCount = 0;
        ActiveSalonService.instance.addListener(() => notificationCount++);

        final res = await ActiveSalonService.applySwitchSalonResponse({'success': true, 'active_salon_id': 42});

        expect(res, isTrue);
        expect(ActiveSalonService.instance.activeSalonId, equals(42));
        expect(notificationCount, equals(1));
      });
    });
  });
}
