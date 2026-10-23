// test/superadmin/superadmin_screens_smoke_test.dart
/// Render de las pantallas de SuperAdmin con estado inyectado.
///
/// No hay mocks de datos de producto: los notifiers falsos solo evitan la llamada
/// HTTP y entregan el MISMO modelo que devuelve la API, para comprobar que la
/// pantalla no revienta y pinta lo que recibe.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_app/models/superadmin/superadmin_models.dart';
import 'package:beauty_app/providers/superadmin_providers.dart';
import 'package:beauty_app/screens/superadmin/plans_screen.dart';
import 'package:beauty_app/screens/superadmin/revenue_screen.dart';
import 'package:beauty_app/screens/superadmin/superadmin_screen.dart';
import 'package:beauty_app/screens/superadmin/tenants_screen.dart';
import 'package:beauty_app/screens/superadmin/usage_screen.dart';
import 'package:beauty_app/services/superadmin_api_service.dart';

// ── Fixtures con la forma real de la API ──────────────────────────────────────

final _tenantPage = TenantPage.fromJson({
  'tenants': [
    {
      'id': 't-1',
      'name': 'Salón Aurora',
      'plan': 'PRO',
      'owner': {'id': 'u-1', 'email': 'duena@aurora.co'},
      'subscription': {'status': 'active', 'plan': 'PRO', 'periodEnd': null},
      'teamSize': 3,
      'apiCallsThisMonth': 1240,
      'createdAt': '2026-01-10T00:00:00.000Z',
    },
    {
      'id': 't-2',
      'name': 'Spa Manos de Seda',
      'plan': 'FREE_TRIAL',
      'owner': {'id': 'u-2', 'email': 'hola@manosdeseda.co'},
      'subscription': null,
      'teamSize': 1,
      'apiCallsThisMonth': 0,
      'createdAt': '2026-03-02T00:00:00.000Z',
    },
  ],
  'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
});

final _dashboard = SuperAdminDashboard.fromJson({
  'summary': {
    'totalTenants': 2,
    'activeTenants': 1,
    'activeSubscriptions': 1,
    'mrrCOP': 249000,
    'arrCOP': 2988000,
    'churnRate30d': 0.5,
    'trialsActive': 1,
    'trialsEndingSoon': 0,
  },
  'planDistribution': [
    {'plan': 'PRO', 'count': 1},
    {'plan': 'FREE_TRIAL', 'count': 1},
  ],
  'topApiUsage': [],
});

final _revenue = RevenueSnapshot.fromJson({
  'mrrHistory': [
    {'month': '2026-08', 'payingTenants': 1, 'revenueCOP': 99000},
    {'month': '2026-09', 'payingTenants': 1, 'revenueCOP': 249000},
  ],
  'revenueByPlan': [
    {'plan': 'PRO', 'tenants': 1, 'revenueCOP': 249000},
  ],
  'pendingInvoices': {'count': 2, 'amountCOP': 498000},
});

final _usage = UsageSnapshot.fromJson({
  'aggregated': [
    {
      'feature': 'API_CALLS',
      'month': '2026-09',
      'totalCount': 5200,
      'activeTenants': 2,
      'avgPerTenant': 2600.0,
      'maxCount': 4000,
    },
  ],
  'exceededLimits': [
    {
      'tenantId': 't-1',
      'tenantName': 'Salón Aurora',
      'plan': 'BASIC',
      'feature': 'API_CALLS',
      'count': 1240,
      'limit': 1000,
      'overagePercent': 24,
    },
  ],
});

// ── Notifiers falsos: solo evitan la red ─────────────────────────────────────

class _FakeTenants extends TenantsNotifier {
  _FakeTenants() {
    state = SuperAdminState(data: _tenantPage);
  }

  @override
  Future<void> load({int? page, String? search, String? plan, bool clearPlan = false}) async {}

  @override
  Future<void> search(String value) async {}

  @override
  Future<void> filterByPlan(String? plan) async {}

  @override
  Future<void> nextPage() async {}

  @override
  Future<void> previousPage() async {}
}

class _FakeDashboard extends DashboardNotifier {
  _FakeDashboard({SuperAdminState<SuperAdminDashboard>? initial}) {
    state = initial ?? SuperAdminState(data: _dashboard);
  }

  @override
  Future<void> load() async {}
}

class _FakeRevenue extends RevenueNotifier {
  _FakeRevenue() {
    state = SuperAdminState(data: _revenue);
  }

  @override
  Future<void> load() async {}
}

class _FakeUsage extends UsageOverviewNotifier {
  _FakeUsage() {
    state = SuperAdminState(data: _usage);
  }

  @override
  Future<void> load() async {}
}

Widget _host(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(1600, 3200);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('TenantsScreen pinta la lista y la paginación', (tester) async {
    await tester.pumpWidget(_host(
      const TenantsScreen(),
      overrides: [tenantsProvider.overrideWith((ref) => _FakeTenants())],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Salón Aurora'), findsOneWidget);
    expect(find.text('duena@aurora.co'), findsOneWidget);
    expect(find.text('2 TENANTS · PÁGINA 1 DE 1'), findsOneWidget);
    expect(find.text('PRO'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TenantsScreen distingue un tenant sin suscripción', (tester) async {
    await tester.pumpWidget(_host(
      const TenantsScreen(),
      overrides: [tenantsProvider.overrideWith((ref) => _FakeTenants())],
    ));
    await tester.pumpAndSettle();

    expect(find.text('SIN SUSCRIPCIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RevenueScreen muestra ingresos y pendientes', (tester) async {
    await tester.pumpWidget(_host(
      const RevenueScreen(),
      overrides: [revenueProvider.overrideWith((ref) => _FakeRevenue())],
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('\$ 249.000'), findsWidgets);
    expect(find.text('2026-09'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UsageScreen muestra el exceso de límite', (tester) async {
    await tester.pumpWidget(_host(
      const UsageScreen(),
      overrides: [usageOverviewProvider.overrideWith((ref) => _FakeUsage())],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Salón Aurora'), findsOneWidget);
    expect(find.text('+24%'), findsOneWidget);
    expect(find.text('1240 / 1000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlansScreen reparte tenants por plan con su precio', (tester) async {
    await tester.pumpWidget(_host(
      const PlansScreen(),
      overrides: [dashboardProvider.overrideWith((ref) => _FakeDashboard())],
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('\$ 249.000'), findsWidgets);
    expect(find.text('1 tenants'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SuperAdminScreen monta el rail y no pide nada al usuario', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [dashboardProvider.overrideWith((ref) => _FakeDashboard())],
      child: const MaterialApp(home: SuperAdminScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('CONSOLA'), findsOneWidget);
    expect(find.text('Tenants'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SuperAdminScreen bloquea a quien no es SuperAdmin (403)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(
          (ref) => _FakeDashboard(
            initial: SuperAdminState(
                error: const SuperAdminForbidden(), isLoading: false),
          ),
        ),
      ],
      child: const MaterialApp(home: SuperAdminScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.textContaining('requiere rol SuperAdmin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
