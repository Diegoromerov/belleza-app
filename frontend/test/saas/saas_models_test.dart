// test/saas/saas_models_test.dart
// Verifica el mapeo de los modelos SaaS contra las formas REALES que devuelve
// el backend (/api/saas/billing, /usage, /api-keys, /team) y que los precios y
// límites del catálogo coincidan con usageMeteringService / invoiceService.
import 'package:beauty_app/models/saas/saas_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaasPlanTier — catálogo real', () {
    test('precios COP coinciden con invoiceService.getPlanPrice (en centavos)', () {
      expect(SaasPlanTier.freeTrial.priceCents, 0);
      expect(SaasPlanTier.freemium.priceCents, 0);
      expect(SaasPlanTier.basic.priceCents, 9900000); // 99.000 COP
      expect(SaasPlanTier.pro.priceCents, 24900000); // 249.000 COP
      expect(SaasPlanTier.enterprise.priceCents, 59900000); // 599.000 COP
    });

    test('formattedPrice usa separador de miles y COP/mes', () {
      expect(SaasPlanTier.basic.formattedPrice, '\$99.000 COP/mes');
      expect(SaasPlanTier.pro.formattedPrice, '\$249.000 COP/mes');
      expect(SaasPlanTier.freeTrial.formattedPrice, 'Gratis');
    });

    test('límites espejo de PLAN_LIMITS', () {
      expect(SaasPlanTier.freeTrial.limits['TEAM_SEATS'], 3);
      expect(SaasPlanTier.freeTrial.limits['API_CALLS'], 1000);
      expect(SaasPlanTier.freemium.limits['TEAM_SEATS'], 1);
      expect(SaasPlanTier.basic.limits['ONLINE_BOOKING'], 200);
      expect(SaasPlanTier.pro.limits['TEAM_SEATS'], 20);
      expect(SaasPlanTier.pro.limits['ONLINE_BOOKING'], isNull); // ilimitado
      expect(SaasPlanTier.enterprise.limits['API_CALLS'], isNull);
    });

    test('solo BASIC/PRO/ENTERPRISE pasan por checkout', () {
      expect(SaasPlanTier.freeTrial.isPurchasable, isFalse);
      expect(SaasPlanTier.freemium.isPurchasable, isFalse);
      expect(SaasPlanTier.basic.isPurchasable, isTrue);
      expect(SaasPlanTier.enterprise.isPurchasable, isTrue);
    });
  });

  group('Subscription.fromJson — shape backend', () {
    test('parsea plan/periodStart/periodEnd en camelCase', () {
      final sub = Subscription.fromJson({
        'id': 'sub_1',
        'plan': 'PRO',
        'status': 'active',
        'periodStart': '2026-10-01T00:00:00.000Z',
        'periodEnd': '2026-11-01T00:00:00.000Z',
        'cancelAtPeriodEnd': false,
        'currency': 'COP',
      });
      expect(sub.tier, SaasPlanTier.pro);
      expect(sub.status, SubscriptionStatus.active);
      expect(sub.isActive, isTrue);
      expect(sub.cancelAtPeriodEnd, isFalse);
      expect(sub.currentPeriodEnd.month, 11);
    });

    test('sin trial no reporta días de prueba', () {
      final sub = Subscription.fromJson({'plan': 'BASIC', 'status': 'ACTIVE'});
      expect(sub.trialDaysLeft, 0);
      expect(sub.isOnTrial, isFalse);
    });
  });

  group('Invoice.fromJson — totales en pesos', () {
    test('total en pesos se convierte a centavos y se formatea', () {
      final inv = Invoice.fromJson({
        'id': 'inv-1',
        'number': 'FV-2026-001',
        'status': 'PAID',
        'currency': 'COP',
        'total': 249000,
        'amountPaid': 249000,
        'createdAt': '2026-10-05T10:00:00.000Z',
      });
      expect(inv.amountCents, 24900000);
      expect(inv.amountPaidCents, 24900000);
      expect(inv.amountDueCents, 0);
      expect(inv.formattedAmount, '\$249.000 COP');
      expect(inv.status, InvoiceStatus.paid);
    });

    test('status OPEN no se confunde con pagada', () {
      final inv = Invoice.fromJson({'status': 'OPEN', 'total': 99000});
      expect(inv.status, InvoiceStatus.open);
    });
  });

  group('UsageSummary.fromJson — shape backend', () {
    Map<String, dynamic> payload() => {
          'plan': 'PRO',
          'period': {'start': '2026-10-01', 'end': '2026-10-31'},
          'usage': [
            {'feature': 'API_CALLS', 'used': 4200, 'limit': 100000, 'remaining': 95800, 'percentage': 4, 'status': 'ok'},
            {'feature': 'ONLINE_BOOKING', 'used': 12, 'limit': 'unlimited', 'remaining': null, 'percentage': 0, 'status': 'ok'},
            {'feature': 'TEAM_SEATS', 'used': 4, 'limit': 20, 'remaining': 16, 'percentage': 20, 'status': 'ok'},
          ],
        };

    test('expone las métricas por feature', () {
      final s = UsageSummary.fromJson(payload());
      expect(s.metrics.length, 3);
      expect(s.apiCallsThisMonth, 4200);
      expect(s.bookingsThisMonth, 12);
      expect(s.staffCount, 4);
      expect(s.periodEnd.day, 31);
    });

    test('"unlimited" se traduce a límite 0 y progreso 0', () {
      final s = UsageSummary.fromJson(payload());
      final bookings = s.getMetric(UsageMetricType.bookings)!;
      expect(bookings.limit, 0);
      expect(bookings.progress, 0.0);
      expect(bookings.isNearLimit, isFalse);
    });

    test('sin consumo no inventa métricas', () {
      final s = UsageSummary.fromJson({'plan': 'BASIC'});
      expect(s.metrics, isEmpty);
      expect(s.staffCount, 0);
      expect(s.alerts, isEmpty);
    });
  });

  group('ApiKey.fromJson — prefijo y key cruda', () {
    test('lista: camelCase keyPrefix, sin key completa', () {
      final k = ApiKey.fromJson({
        'id': 'k1',
        'name': 'CRM',
        'keyPrefix': 'gsk_live_ab...',
        'scopes': ['read', 'write'],
        'createdAt': '2026-10-01T00:00:00.000Z',
        'isActive': true,
      });
      expect(k.prefix, 'gsk_live_ab...');
      expect(k.rawKey, isNull);
      expect(k.key, k.displayKey);
      expect(k.scopes, [ApiKeyScope.read, ApiKeyScope.write]);
      expect(k.isRevoked, isFalse);
    });

    test('creación: la key completa queda en rawKey', () {
      final k = ApiKey.fromJson({
        'id': 'k2',
        'name': 'POS',
        'key': 'gsk_live_abcdef123456',
        'keyPrefix': 'gsk_live_ab...',
        'scopes': ['admin'],
        'createdAt': '2026-10-01T00:00:00.000Z',
      });
      expect(k.rawKey, 'gsk_live_abcdef123456');
      expect(k.key, 'gsk_live_abcdef123456');
      expect(k.scopes, [ApiKeyScope.admin]);
    });

    test('revocada por revokedAt', () {
      final k = ApiKey.fromJson({'id': 'k3', 'isActive': false, 'revokedAt': '2026-10-02T00:00:00.000Z'});
      expect(k.isRevoked, isTrue);
    });

    test('CreateApiKeyRequest envía expiresInDays en camelCase', () {
      final json = const CreateApiKeyRequest(
        name: 'CRM',
        scopes: [ApiKeyScope.read],
        expiresInDays: 90,
      ).toJson();
      expect(json['expiresInDays'], 90);
      expect(json.containsKey('expires_in_days'), isFalse);
      expect(json['scopes'], ['read']);
    });
  });

  group('TeamMember.fromJson — status del backend', () {
    test('ACTIVE se mapea a aceptado y OWNER a propietario', () {
      final m = TeamMember.fromJson({
        'id': 'm1',
        'user_id': 7,
        'email': 'dueno@salon.com',
        'full_name': 'Dueño Salón',
        'role': 'OWNER',
        'status': 'ACTIVE',
      });
      expect(m.invitationStatus, InvitationStatus.accepted);
      expect(m.role, MembershipRole.owner);
      expect(m.isOwner, isTrue);
      expect(m.isActive, isTrue);
      expect(m.fullName, 'Dueño Salón');
    });

    test('PENDING se mapea a invitación pendiente', () {
      final m = TeamMember.fromJson({'id': 'm2', 'role': 'MEMBER', 'status': 'PENDING'});
      expect(m.invitationStatus, InvitationStatus.pending);
      expect(m.isPending, isTrue);
      expect(m.role, MembershipRole.staff);
      expect(m.role.code, 'MEMBER'); // el backend no acepta 'STAFF'
    });
  });

  group('UsageAlert — severidad derivada', () {
    test('por encima del 100% es crítica, por debajo es aviso', () {
      UsageAlert alert(int current, int limit) => UsageAlert(
            id: 'a',
            businessProfileId: 'b',
            metricType: UsageMetricType.apiCalls,
            threshold: 0.8,
            currentValue: current,
            limitValue: limit,
            triggeredAt: DateTime(2026, 10, 1),
            acknowledged: false,
          );
      expect(alert(120, 100).severity, 'critical');
      expect(alert(85, 100).severity, 'warning');
      expect(alert(85, 100).percentageUsed, 85);
      expect(alert(5, 0).percentageUsed, 0);
    });
  });
}
