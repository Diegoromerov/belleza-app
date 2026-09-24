// frontend/test/saas_client_infrastructure_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_token_for_tests';
  const testMembershipId = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
  const secondMembershipId = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';

  setUp(() {
    ActiveContextHolder().resetForTesting();
    ApiService.testToken = testToken;
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
    ApiService.testToken = null;
  });

  group('NODO-07 FASE 1 — ActiveContextHolder Unit Tests', () {
    test('A. ActiveContextHolder inicialmente vacío', () {
      final holder = ActiveContextHolder();
      expect(holder.activeMembershipId, isNull);
      expect(holder.hasActiveContext, isFalse);
    });

    test('B. Set explícito de membership_id', () {
      final holder = ActiveContextHolder();
      holder.setActiveMembershipId(testMembershipId);
      expect(holder.activeMembershipId, equals(testMembershipId));
      expect(holder.hasActiveContext, isTrue);
    });

    test('C. Get devuelve membership_id correcto', () {
      final holder = ActiveContextHolder();
      holder.setActiveMembershipId(testMembershipId);
      final retrieved = holder.activeMembershipId;
      expect(retrieved, equals(testMembershipId));
    });

    test('D. Clear elimina contexto', () {
      final holder = ActiveContextHolder();
      holder.setActiveMembershipId(testMembershipId);
      expect(holder.hasActiveContext, isTrue);

      holder.clear();
      expect(holder.activeMembershipId, isNull);
      expect(holder.hasActiveContext, isFalse);
    });

    test('E. Cambio explícito de membership funciona y notifica listeners', () {
      final holder = ActiveContextHolder();
      int notificationCount = 0;
      holder.addListener(() {
        notificationCount++;
      });

      holder.setActiveMembershipId(testMembershipId);
      expect(notificationCount, equals(1));
      expect(holder.activeMembershipId, equals(testMembershipId));

      holder.setActiveMembershipId(secondMembershipId);
      expect(notificationCount, equals(2));
      expect(holder.activeMembershipId, equals(secondMembershipId));

      holder.clear();
      expect(notificationCount, equals(3));
      expect(holder.activeMembershipId, isNull);
    });

    test('K. Validación de input inválido/vacío en setActiveMembershipId lanza ArgumentError', () {
      final holder = ActiveContextHolder();
      expect(() => holder.setActiveMembershipId(''), throwsArgumentError);
      expect(() => holder.setActiveMembershipId('   '), throwsArgumentError);
    });

    test('J. No existe persistencia de Active Context (en memoria/RAM pura)', () {
      final holder1 = ActiveContextHolder();
      holder1.setActiveMembershipId(testMembershipId);
      expect(holder1.activeMembershipId, equals(testMembershipId));

      // Reset en memoria
      holder1.resetForTesting();
      expect(holder1.activeMembershipId, isNull);
      expect(holder1.hasActiveContext, isFalse);
    });
  });

  group('NODO-07 FASE 1 — ApiService HTTP Contextual Headers Tests', () {
    test('F. Request B2C NO recibe x-active-membership-id incluso si hay contexto en memoria', () async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final headersWithoutPath = await ApiService.getAuthHeaders();
      expect(headersWithoutPath.containsKey('x-active-membership-id'), isFalse);
      expect(headersWithoutPath['Authorization'], equals('Bearer $testToken'));

      final headersB2C = await ApiService.getAuthHeaders('/api/bookings/client');
      expect(headersB2C.containsKey('x-active-membership-id'), isFalse);
      expect(headersB2C['Authorization'], equals('Bearer $testToken'));

      final headersProviders = await ApiService.getAuthHeaders('/api/providers');
      expect(headersProviders.containsKey('x-active-membership-id'), isFalse);
    });

    test('G. Request SaaS con contexto recibe x-active-membership-id correcto', () async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final headersSaaS = await ApiService.getAuthHeaders('/api/v1/saas/hub/summary');
      expect(headersSaaS['x-active-membership-id'], equals(testMembershipId));
      expect(headersSaaS['Authorization'], equals('Bearer $testToken'));
      expect(headersSaaS['Content-Type'], equals('application/json'));
    });

    test('H. Request SaaS sin contexto NO inventa membership_id', () async {
      ActiveContextHolder().clear();

      final headersSaaS = await ApiService.getAuthHeaders('/api/v1/saas/hub/summary');
      expect(headersSaaS.containsKey('x-active-membership-id'), isFalse);
      expect(headersSaaS['Authorization'], equals('Bearer $testToken'));
    });

    test('I. Authorization Bearer permanece intacto en B2C y SaaS', () async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final b2cHeaders = await ApiService.getAuthHeaders('/api/bookings');
      final saasHeaders = await ApiService.getAuthHeaders('/api/v1/saas/hub/staff');

      expect(b2cHeaders['Authorization'], equals('Bearer $testToken'));
      expect(saasHeaders['Authorization'], equals('Bearer $testToken'));
    });
  });
}
