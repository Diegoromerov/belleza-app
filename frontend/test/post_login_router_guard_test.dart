// frontend/test/post_login_router_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/services/auth_service.dart';
import 'package:beauty_app/services/active_context_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('T08-A — Post-Login Router Guard Tests', () {
    test('1. Null o payload sin usuario retorna /login', () async {
      final dest1 = await AuthService.resolvePostLoginDestination(null);
      expect(dest1, equals('/login'));

      final dest2 = await AuthService.resolvePostLoginDestination({});
      expect(dest2, equals('/login'));
    });

    test('2. onboarding_completo: false retorna siempre /onboarding', () async {
      final payload = {
        'token': 'mock-jwt-token',
        'user': {
          'id': 123,
          'full_name': 'Test User',
          'role': 'salon',
          'onboarding_completo': false,
        }
      };

      final dest = await AuthService.resolvePostLoginDestination(payload);
      expect(dest, equals('/onboarding'));
      expect(ActiveContextHolder().hasActiveContext, isFalse);
    });

    test('3. onboarding_completo: true sin contextos SaaS y role: provider retorna /provider', () async {
      final payload = {
        'token': 'mock-jwt-token',
        'user': {
          'id': 456,
          'full_name': 'Provider User',
          'role': 'provider',
          'onboarding_completo': true,
        }
      };

      final dest = await AuthService.resolvePostLoginDestination(payload);
      expect(dest, equals('/provider'));
    });

    test('4. onboarding_completo: true sin contextos SaaS y role: cliente retorna /home', () async {
      final payload = {
        'token': 'mock-jwt-token',
        'user': {
          'id': 789,
          'full_name': 'Client User',
          'role': 'cliente',
          'onboarding_completo': true,
        }
      };

      final dest = await AuthService.resolvePostLoginDestination(payload);
      expect(dest, equals('/home'));
    });

    test('5. T08-B: onboarding_completo: true y role: salon retorna siempre /saas/hub', () async {
      final payload = {
        'token': 'mock-jwt-token',
        'user': {
          'id': 999,
          'full_name': 'Salon Owner User',
          'role': 'salon',
          'onboarding_completo': true,
        }
      };

      final dest = await AuthService.resolvePostLoginDestination(payload);
      expect(dest, equals('/saas/hub'));
    });
  });
}
