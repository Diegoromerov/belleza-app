// lib/providers/superadmin_providers.dart
/// PROVIDERS DEL DASHBOARD SUPERADMIN (Riverpod)
/// Mismo patrón que `saas_providers.dart`: StateNotifier con estado inmutable
/// {data, error, isLoading}. Sin datos mock: si la API falla, el estado lleva el error
/// y la pantalla lo muestra.
library superadmin_providers;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/superadmin/superadmin_models.dart';
import '../services/superadmin_api_service.dart';

@immutable
class SuperAdminState<T> {
  final T? data;
  final Object? error;
  final bool isLoading;

  const SuperAdminState({this.data, this.error, this.isLoading = false});

  SuperAdminState<T> loading() => SuperAdminState<T>(data: data, isLoading: true);
  SuperAdminState<T> success(T value) => SuperAdminState<T>(data: value);
  SuperAdminState<T> failure(Object e) => SuperAdminState<T>(data: data, error: e);

  bool get isForbidden => error is SuperAdminForbidden;
}

// ════════════════════════════════════════════════════════════════
// DASHBOARD
// ════════════════════════════════════════════════════════════════

class DashboardNotifier extends StateNotifier<SuperAdminState<SuperAdminDashboard>> {
  DashboardNotifier() : super(const SuperAdminState());

  Future<void> load() async {
    state = state.loading();
    try {
      state = state.success(await SuperAdminApiService.getDashboard());
    } catch (e) {
      state = state.failure(e);
    }
  }
}

// ════════════════════════════════════════════════════════════════
// TENANTS
// ════════════════════════════════════════════════════════════════

class TenantsNotifier extends StateNotifier<SuperAdminState<TenantPage>> {
  TenantsNotifier() : super(const SuperAdminState());

  int _page = 1;
  String _search = '';
  String? _planFilter;

  int get page => _page;
  String get searchTerm => _search;
  String? get planFilter => _planFilter;

  Future<void> load({int? page, String? search, String? plan, bool clearPlan = false}) async {
    _page = page ?? _page;
    if (search != null) _search = search;
    if (clearPlan) {
      _planFilter = null;
    } else if (plan != null) {
      _planFilter = plan;
    }

    state = state.loading();
    try {
      final result = await SuperAdminApiService.getTenants(
        page: _page,
        search: _search,
        plan: _planFilter,
      );
      state = state.success(result);
    } catch (e) {
      state = state.failure(e);
    }
  }

  Future<void> search(String value) => load(page: 1, search: value);

  Future<void> filterByPlan(String? plan) =>
      plan == null ? load(page: 1, clearPlan: true) : load(page: 1, plan: plan);

  Future<void> nextPage() async {
    final total = state.data?.totalPages ?? 1;
    if (_page >= total) return;
    await load(page: _page + 1);
  }

  Future<void> previousPage() async {
    if (_page <= 1) return;
    await load(page: _page - 1);
  }

  /// Cambia el plan y recarga la página actual: el estado del backend manda.
  Future<String?> changePlan(String tenantId, String plan, {String? reason}) async {
    try {
      final message = await SuperAdminApiService.changePlan(tenantId, plan, reason: reason);
      await load();
      return message;
    } catch (e) {
      state = state.failure(e);
      return null;
    }
  }

  Future<String?> suspend(String tenantId, {bool suspend = true, String? reason}) async {
    try {
      final message = await SuperAdminApiService.suspendTenant(tenantId,
          suspend: suspend, reason: reason);
      await load();
      return message;
    } catch (e) {
      state = state.failure(e);
      return null;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// INGRESOS
// ════════════════════════════════════════════════════════════════

class RevenueNotifier extends StateNotifier<SuperAdminState<RevenueSnapshot>> {
  RevenueNotifier() : super(const SuperAdminState());

  Future<void> load() async {
    state = state.loading();
    try {
      state = state.success(await SuperAdminApiService.getRevenue());
    } catch (e) {
      state = state.failure(e);
    }
  }
}

// ════════════════════════════════════════════════════════════════
// USO
// ════════════════════════════════════════════════════════════════

class UsageOverviewNotifier extends StateNotifier<SuperAdminState<UsageSnapshot>> {
  UsageOverviewNotifier() : super(const SuperAdminState());

  Future<void> load() async {
    state = state.loading();
    try {
      state = state.success(await SuperAdminApiService.getUsage());
    } catch (e) {
      state = state.failure(e);
    }
  }
}

// ════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, SuperAdminState<SuperAdminDashboard>>(
        (ref) => DashboardNotifier());

final tenantsProvider =
    StateNotifierProvider<TenantsNotifier, SuperAdminState<TenantPage>>(
        (ref) => TenantsNotifier());

final revenueProvider =
    StateNotifierProvider<RevenueNotifier, SuperAdminState<RevenueSnapshot>>(
        (ref) => RevenueNotifier());

final usageOverviewProvider =
    StateNotifierProvider<UsageOverviewNotifier, SuperAdminState<UsageSnapshot>>(
        (ref) => UsageOverviewNotifier());
