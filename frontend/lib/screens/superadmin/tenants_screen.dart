// lib/screens/superadmin/tenants_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beauty_app/models/superadmin/superadmin_models.dart';
import 'package:beauty_app/providers/superadmin_providers.dart';
import 'superadmin_ui.dart';

/// Listado de tenants con búsqueda, filtro por plan, paginación y acciones
/// de cambio de plan y suspensión. Todo dato viene de `/api/superadmin/tenants`.
class TenantsScreen extends ConsumerStatefulWidget {
  const TenantsScreen({super.key});

  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  final _searchCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantsProvider.notifier).load(page: 1);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePlan(TenantSummary tenant) async {
    var selected = tenant.plan;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar plan · ${tenant.name}'),
        content: StatefulBuilder(
          builder: (ctx2, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nuevo plan'),
                items: kSuperAdminPlans
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setLocal(() => selected = v ?? selected),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Motivo (queda en auditoría)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('APLICAR')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final message = await ref
        .read(tenantsProvider.notifier)
        .changePlan(tenant.id, selected, reason: reasonCtrl.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No se pudo cambiar el plan')),
    );
  }

  Future<void> _toggleSuspend(TenantSummary tenant) async {
    final suspended = tenant.statusLabel.contains('SUSPEND');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspended ? 'Reactivar tenant' : 'Suspender tenant'),
        content: Text(suspended
            ? '¿Reactivar «${tenant.name}»?'
            : '¿Suspender «${tenant.name}»? Dejará de operar en la plataforma.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFIRMAR')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final message = await ref
        .read(tenantsProvider.notifier)
        .suspend(tenant.id, suspend: !suspended);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No se pudo actualizar el tenant')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantsProvider);
    final notifier = ref.read(tenantsProvider.notifier);

    if (state.isForbidden) return const SaForbidden();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaHeader(
          title: 'Tenants',
          subtitle: 'Cuentas de negocio, su plan y su consumo de API.',
          trailing: IconButton(
            tooltip: 'Actualizar',
            onPressed: () => notifier.load(),
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email del dueño',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: SaColors.line),
                  ),
                ),
                onSubmitted: (v) => notifier.search(v),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String?>(
                initialValue: notifier.planFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Plan'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  ...kSuperAdminPlans
                      .map((p) => DropdownMenuItem<String?>(value: p, child: Text(p))),
                ],
                onChanged: (v) => notifier.filterByPlan(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(minHeight: 2, color: SaColors.gold),
        if (state.isLoading) const SaLoading(),
        if (state.error != null && !state.isForbidden)
          SaErrorState(error: state.error!, onRetry: () => notifier.load()),
        if (state.data != null && !state.isLoading) _buildTable(state.data!, notifier),
      ],
    );
  }

  Widget _buildTable(TenantPage page, TenantsNotifier notifier) {
    if (page.tenants.isEmpty) {
      return const SaEmptyState(
          message: 'No hay tenants con estos filtros.\nSi esperabas ver cuentas, revisa que el backend esté devolviendo datos y no una lista vacía.');
    }

    return SaPanel(
      title: '${page.total} tenants · página ${page.page} de ${page.totalPages}',
      child: Column(
        children: [
          for (final t in page.tenants) _tenantRow(t),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: page.page > 1 ? notifier.previousPage : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${page.page} / ${page.totalPages}',
                  style: const TextStyle(fontSize: 11.5, color: SaColors.muted)),
              IconButton(
                onPressed: page.page < page.totalPages ? notifier.nextPage : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tenantRow(TenantSummary t) {
    final active = t.subscription?.isActive ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                Text(t.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: SaColors.ink)),
                const SizedBox(height: 2),
                Text(t.ownerEmail,
                    style: const TextStyle(fontSize: 10.5, color: SaColors.muted)),
              ],
            ),
          ),
          _pill(t.plan, active ? SaColors.ok : SaColors.muted),
          const SizedBox(width: 8),
          _pill(t.statusLabel, active ? SaColors.ok : SaColors.warn),
          const SizedBox(width: 12),
          // Anchos flexibles: con tamaños fijos la fila desbordaba en pantallas
          // medianas (RenderFlex overflowed by 20 px en los widget tests).
          Expanded(
            flex: 2,
            child: Text('${t.teamSize} equipo · ${t.apiCallsThisMonth} API',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: SaColors.muted)),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            onSelected: (value) {
              if (value == 'plan') _changePlan(t);
              if (value == 'suspend') _toggleSuspend(t);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'plan', child: Text('Cambiar plan')),
              PopupMenuItem(
                value: 'suspend',
                child: Text(t.statusLabel.contains('SUSPEND') ? 'Reactivar' : 'Suspender'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      );
}
