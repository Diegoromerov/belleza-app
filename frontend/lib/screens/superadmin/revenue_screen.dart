// lib/screens/superadmin/revenue_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beauty_app/models/superadmin/superadmin_models.dart';
import 'package:beauty_app/providers/superadmin_providers.dart';
import 'superadmin_ui.dart';

/// Ingresos de la plataforma: MRR por mes, reparto por plan y facturas pendientes.
/// Fuente: `GET /api/superadmin/revenue`.
class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(revenueProvider);

    if (state.isForbidden) return const SaForbidden();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.isLoading && state.data == null && state.error == null) {
        ref.read(revenueProvider.notifier).load();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaHeader(
          title: 'Ingresos',
          subtitle: 'MRR histórico, reparto por plan y cobros pendientes.',
          trailing: IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.read(revenueProvider.notifier).load(),
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading) const SaLoading(),
        if (state.error != null && !state.isForbidden)
          SaErrorState(
              error: state.error!, onRetry: () => ref.read(revenueProvider.notifier).load()),
        if (state.data != null) _body(state.data!),
      ],
    );
  }

  Widget _body(RevenueSnapshot snap) {
    final last = snap.mrrHistory.isNotEmpty ? snap.mrrHistory.last : null;
    final totalPlanRevenue =
        snap.revenueByPlan.fold<double>(0, (acc, p) => acc + p.revenueCop);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SaKpi(
              label: 'Ingreso del último mes',
              value: formatCop(last?.revenueCop ?? 0),
              note: last == null ? 'Sin historial' : '${last.month} · ${last.payingTenants} pagando',
            ),
            SaKpi(
              label: 'Facturas pendientes',
              value: '${snap.pendingCount}',
              note: formatCop(snap.pendingAmountCop),
              valueColor: snap.pendingCount > 0 ? SaColors.warn : null,
            ),
            SaKpi(
              label: 'Ingreso acumulado por plan',
              value: formatCop(totalPlanRevenue),
              note: '${snap.revenueByPlan.length} planes con cobros',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SaPanel(
          title: 'MRR por mes',
          child: snap.mrrHistory.isEmpty
              ? const SaEmptyState(message: 'Sin historial de ingresos todavía.')
              : Column(
                  children: [
                    for (final p in snap.mrrHistory) _monthRow(p, snap),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SaPanel(
          title: 'Reparto por plan',
          child: snap.revenueByPlan.isEmpty
              ? const SaEmptyState(message: 'Ningún plan registra cobros.')
              : Column(
                  children: [
                    for (final p in snap.revenueByPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: SaColors.line)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(p.plan.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11.5, fontWeight: FontWeight.w600,
                                      color: SaColors.ink)),
                            ),
                            Expanded(
                              child: Text('${p.tenants} tenants',
                                  style: const TextStyle(fontSize: 11, color: SaColors.muted)),
                            ),
                            Text(formatCop(p.revenueCop),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: SaColors.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _monthRow(MrrPoint p, RevenueSnapshot snap) {
    final max = snap.mrrHistory
        .map((e) => e.revenueCop)
        .fold<double>(1, (a, b) => b > a ? b : a);
    final ratio = max == 0 ? 0.0 : (p.revenueCop / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(p.month,
              style: const TextStyle(fontSize: 11.5, color: SaColors.ink))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: SaColors.line,
                valueColor: const AlwaysStoppedAnimation(SaColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(formatCop(p.revenueCop),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: SaColors.ink)),
          ),
        ],
      ),
    );
  }
}
