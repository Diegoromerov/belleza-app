// lib/screens/superadmin/plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beauty_app/models/superadmin/superadmin_models.dart';
import 'package:beauty_app/providers/superadmin_providers.dart';
import 'superadmin_ui.dart';

/// Catálogo de planes con su precio y cuántos tenants hay en cada uno.
/// Los precios son los mismos que cobra `saasBillingRoutes` (COP/mes).
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  /// Precio mensual por plan, alineado con el backend.
  static const Map<String, int> monthlyPriceCop = {
    'FREE_TRIAL': 0,
    'FREEMIUM': 0,
    'BASIC': 99000,
    'PRO': 249000,
    'ENTERPRISE': 599000,
  };

  static const Map<String, String> planPurpose = {
    'FREE_TRIAL': 'Prueba con límites reducidos',
    'FREEMIUM': 'Uso gratuito permanente',
    'BASIC': 'Salón que arranca',
    'PRO': 'Salón en crecimiento',
    'ENTERPRISE': 'Multi-sede y API',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    if (state.isForbidden) return const SaForbidden();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.isLoading && state.data == null && state.error == null) {
        ref.read(dashboardProvider.notifier).load();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaHeader(
          title: 'Planes',
          subtitle: 'Qué se cobra y cómo se reparten los tenants.',
          trailing: IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.read(dashboardProvider.notifier).load(),
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading) const SaLoading(),
        if (state.error != null && !state.isForbidden)
          SaErrorState(
              error: state.error!, onRetry: () => ref.read(dashboardProvider.notifier).load()),
        if (state.data != null) _body(state.data!),
      ],
    );
  }

  Widget _body(SuperAdminDashboard dash) {
    final counts = {for (final p in dash.planDistribution) p.plan: p.count};
    final total = dash.summary.totalTenants;
    final mrr = dash.summary.mrrCop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SaKpi(label: 'Tenants', value: '$total'),
            SaKpi(label: 'MRR actual', value: formatCop(mrr)),
            SaKpi(
              label: 'Ticket medio',
              value: formatCop(dash.summary.activeTenants == 0
                  ? 0
                  : mrr / dash.summary.activeTenants),
              note: 'sobre ${dash.summary.activeTenants} cuentas de pago',
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final plan in kSuperAdminPlans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SaPanel(
              title: plan,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(planPurpose[plan] ?? '',
                            style: const TextStyle(fontSize: 11.5, color: SaColors.muted)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                monthlyPriceCop[plan] == 0
                                    ? 'Sin costo'
                                    : '${formatCop(monthlyPriceCop[plan]!)} / mes',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: SaColors.ink),
                              ),
                            ),
                            Text('${counts[plan] ?? 0} tenants',
                                style: const TextStyle(fontSize: 11.5, color: SaColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : (counts[plan] ?? 0) / total,
                            minHeight: 6,
                            backgroundColor: SaColors.line,
                            valueColor: const AlwaysStoppedAnimation(SaColors.gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    total == 0
                        ? '—'
                        : '${(((counts[plan] ?? 0) / total) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: SaColors.muted),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'El cambio de plan se aplica desde la pantalla de Tenants y queda registrado en auditoría.',
          style: TextStyle(fontSize: 11, color: SaColors.muted),
        ),
      ],
    );
  }
}
