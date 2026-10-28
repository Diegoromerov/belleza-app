// lib/screens/superadmin/usage_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beauty_app/models/superadmin/superadmin_models.dart';
import 'package:beauty_app/providers/superadmin_providers.dart';
import 'superadmin_ui.dart';

/// Consumo agregado entre tenants y quién superó su límite.
/// Fuente: `GET /api/superadmin/usage`.
class UsageScreen extends ConsumerWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageOverviewProvider);

    if (state.isForbidden) return const SaForbidden();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.isLoading && state.data == null && state.error == null) {
        ref.read(usageOverviewProvider.notifier).load();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaHeader(
          title: 'Uso de la plataforma',
          subtitle: 'Consumo por feature, tenants activos y límites excedidos.',
          trailing: IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.read(usageOverviewProvider.notifier).load(),
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading) const SaLoading(),
        if (state.error != null && !state.isForbidden)
          SaErrorState(
              error: state.error!, onRetry: () => ref.read(usageOverviewProvider.notifier).load()),
        if (state.data != null) _body(state.data!),
      ],
    );
  }

  Widget _body(UsageSnapshot snap) {
    final totalCount = snap.aggregated.fold<int>(0, (a, b) => a + b.totalCount);
    final features = snap.aggregated.map((e) => e.feature).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SaKpi(
              label: 'Eventos del mes',
              value: '$totalCount',
              note: '${snap.aggregated.length} registros de uso',
            ),
            SaKpi(
              label: 'Features medidas',
              value: '$features',
              note: 'agregadas de todos los tenants',
            ),
            SaKpi(
              label: 'Límites excedidos',
              value: '${snap.exceededLimits.length}',
              note: snap.exceededLimits.isEmpty
                  ? 'ningún tenant por encima'
                  : 'requieren revisión comercial',
              valueColor: snap.exceededLimits.isEmpty ? null : SaColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SaPanel(
          title: 'Consumo agregado',
          child: snap.aggregated.isEmpty
              ? const SaEmptyState(
                  message: 'Sin métricas de uso registradas para este período.')
              : Column(
                  children: [
                    for (final a in snap.aggregated)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: SaColors.line)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(a.feature,
                                  style: const TextStyle(
                                      fontSize: 11.5, fontWeight: FontWeight.w600,
                                      color: SaColors.ink)),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(a.month,
                                  style: const TextStyle(fontSize: 10.5, color: SaColors.muted)),
                            ),
                            Expanded(
                              child: Text(
                                  '${a.totalCount} total · ${a.activeTenants} tenants · media ${a.avgPerTenant.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11, color: SaColors.muted)),
                            ),
                            Text('máx ${a.maxCount}',
                                style: const TextStyle(fontSize: 11, color: SaColors.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SaPanel(
          title: 'Tenants por encima de su límite',
          child: snap.exceededLimits.isEmpty
              ? const SaEmptyState(message: 'Ningún tenant ha superado su límite este mes.')
              : Column(
                  children: [
                    for (final e in snap.exceededLimits)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: SaColors.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.tenantName,
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: SaColors.ink)),
                                  Text('${e.plan} · ${e.feature}',
                                      style: const TextStyle(
                                          fontSize: 10.5, color: SaColors.muted)),
                                ],
                              ),
                            ),
                            Text('${e.count} / ${e.limit}',
                                style: const TextStyle(fontSize: 11.5, color: SaColors.ink)),
                            const SizedBox(width: 12),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SaColors.danger.withOpacity(.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('+${e.overagePercent}%',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: SaColors.danger)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
