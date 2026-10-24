// test/saas/saas_screens_smoke_test.dart
// Render headless de las pantallas SaaS con providers falsos (sin red).
// Prueba que las pantallas construyen, muestran sus secciones y no lanzan.
import 'package:beauty_app/models/saas/saas_models.dart';
import 'package:beauty_app/providers/saas_providers.dart';
import 'package:beauty_app/screens/saas/api_keys_screen.dart';
import 'package:beauty_app/screens/saas/billing_screen.dart';
import 'package:beauty_app/screens/saas/usage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _profile = SaasBusinessProfile(
  id: 'salon-1',
  ownerId: '1',
  name: 'Salón Glow',
  slug: 'salon-glow',
  timezone: 'America/Bogota',
  currency: 'COP',
  currentPlan: SaasPlanTier.pro,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 10, 1),
  isActive: true,
);

final _subscription = Subscription(
  id: 'sub-1',
  businessProfileId: 'salon-1',
  stripeSubscriptionId: 'sub_1',
  stripeCustomerId: 'cus_1',
  planTier: SaasPlanTier.pro,
  status: SubscriptionStatus.active,
  currentPeriodStart: DateTime(2026, 10, 1),
  currentPeriodEnd: DateTime(2026, 11, 1),
  cancelAtPeriodEnd: false,
  quantity: 1,
);

final _usage = UsageSummary(
  metrics: [
    UsageMetric(
      type: UsageMetricType.apiCalls,
      current: 4200,
      limit: 100000,
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
    ),
    UsageMetric(
      type: UsageMetricType.staff,
      current: 4,
      limit: 20,
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
    ),
  ],
  alerts: [
    UsageAlert(
      id: 'a1',
      businessProfileId: 'salon-1',
      metricType: UsageMetricType.apiCalls,
      threshold: 0.8,
      currentValue: 95000,
      limitValue: 100000,
      triggeredAt: DateTime(2026, 10, 20),
      acknowledged: false,
    ),
  ],
  periodStart: DateTime(2026, 10, 1),
  periodEnd: DateTime(2026, 10, 31),
);

class _FakeProfile extends BusinessProfileNotifier {
  @override
  Future<void> load() async {
    state = BusinessProfileState(
      profile: _profile,
      membership: Membership(
        id: 'm1',
        userId: '1',
        businessProfileId: _profile.id,
        role: MembershipRole.owner,
        joinedAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
    );
  }
}

class _FakeBilling extends BillingNotifier {
  @override
  Future<void> load(String businessProfileId) async {
    state = BillingState(
      subscription: _subscription,
      invoices: [
        Invoice(
          id: 'inv-1',
          businessProfileId: 'salon-1',
          stripeInvoiceId: 'in_1',
          number: 'FV-2026-001',
          status: InvoiceStatus.paid,
          amountCents: 24900000,
          amountPaidCents: 24900000,
          amountDueCents: 0,
          currency: 'COP',
          issuedAt: DateTime(2026, 10, 5),
        ),
      ],
      paymentMethods: const [
        {'id': 'pm_1', 'card': {'brand': 'visa', 'last4': '4242', 'expMonth': 12, 'expYear': 2029}},
      ],
    );
  }
}

class _FakeUsage extends UsageNotifier {
  @override
  Future<void> load(String businessProfileId) async {
    state = UsageState(summary: _usage);
  }
}

class _FakeKeys extends ApiKeysNotifier {
  @override
  Future<void> load(String businessProfileId) async {
    state = ApiKeysState(
      keys: [
        ApiKey(
          id: 'k1',
          businessProfileId: 'salon-1',
          name: 'Integración CRM',
          keyPrefix: 'gsk_live_ab...',
          scopes: const [ApiKeyScope.read, ApiKeyScope.write],
          rateLimit: 60,
          createdAt: DateTime(2026, 10, 1),
          isActive: true,
        ),
      ],
    );
  }
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      businessProfileProvider.overrideWith((ref) => _FakeProfile()),
      billingProvider.overrideWith((ref) => _FakeBilling()),
      usageProvider.overrideWith((ref) => _FakeUsage()),
      apiKeysProvider.overrideWith((ref) => _FakeKeys()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  // Viewport alto para que el ListView construya todas las secciones
  // (con la altura por defecto las de abajo quedan fuera del árbol).
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('BillingScreen renderiza plan, facturas y métodos de pago', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(_wrap(const BillingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Facturación y Plan'), findsOneWidget);
    expect(find.textContaining('Plan Profesional'), findsOneWidget);
    expect(find.text('Historial de Facturas'), findsOneWidget);
    expect(find.textContaining('FV-2026-001'), findsOneWidget);
    expect(find.text('Métodos de Pago'), findsOneWidget);
    expect(find.textContaining('VISA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UsageScreen renderiza KPIs, alertas y límites del plan', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(_wrap(const UsageScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Uso y Métricas'), findsOneWidget);
    expect(find.text('Llamadas API'), findsWidgets); // KPI + alerta + tabla + eje
    expect(find.text('Alertas de Uso'), findsOneWidget);
    expect(find.textContaining('Límites del Plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ApiKeysScreen lista la key con sus scopes', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(_wrap(const ApiKeysScreen()));
    await tester.pumpAndSettle();

    expect(find.text('API Keys'), findsOneWidget);
    expect(find.text('Integración CRM'), findsOneWidget);
    expect(find.text('read'), findsOneWidget);
    expect(find.text('write'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
