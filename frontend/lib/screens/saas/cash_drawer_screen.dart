// frontend/lib/screens/saas/cash_drawer_screen.dart
// GO-08.53: SaaS Cash Drawer Screen (SCR-16)

import 'package:flutter/material.dart';
import '../../models/saas/saas_cash_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/saas_cash_service.dart';
import 'widgets/cash_drawer_modals.dart';

/// CashDrawerScreen (SCR-16)
///
/// Pantalla de Control y Gestión de Turnos de Caja para GlowApp SaaS.
class CashDrawerScreen extends StatefulWidget {
  final SaasCashService? service;
  final String? initialRole;
  final VoidCallback? onNavigateToContextSelector;

  const CashDrawerScreen({
    super.key,
    this.service,
    this.initialRole,
    this.onNavigateToContextSelector,
  });

  @override
  State<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends State<CashDrawerScreen> {
  late final SaasCashService _service;
  late final ActiveContextHolder _contextHolder;

  bool _isLoading = true;
  bool _activeContextMissing = false;
  String? _errorMessage;

  SaasCashStatusResponse? _currentStatus;
  SaasCashHistoryResponse? _historyResponse;
  bool _isLoadingHistory = false;

  String get _effectiveRole => (widget.initialRole ?? _currentStatus?.role ?? 'OWNER').toUpperCase();
  bool get _canViewHistory => _effectiveRole == 'OWNER' || _effectiveRole == 'MANAGER';
  bool get _isProfessional => _effectiveRole == 'PROFESSIONAL';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasCashService();
    _contextHolder = ActiveContextHolder();
    _checkContextAndLoad();
  }

  void _checkContextAndLoad() {
    final activeId = _contextHolder.activeMembershipId;
    if (activeId == null || activeId.isEmpty) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
      });
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeContextMissing = false;
    });

    try {
      final status = await _service.getCurrentStatus();
      if (mounted) {
        setState(() {
          _currentStatus = status;
          _isLoading = false;
        });
        if (_canViewHistory) {
          _loadHistory();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is SaasCashException ? e.message : e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadHistory({int page = 1}) async {
    if (!_canViewHistory) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _service.getHistory(page: page);
      if (mounted) {
        setState(() {
          _historyResponse = history;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _openOpenSessionModal() {
    CashOpenModal.show(
      context,
      service: _service,
      onSuccess: _loadData,
    );
  }

  void _openCashInModal() {
    final session = _currentStatus?.session;
    if (session == null) return;
    CashInModal.show(
      context,
      sessionId: session.id,
      service: _service,
      onSuccess: _loadData,
    );
  }

  void _openCashOutModal() {
    final session = _currentStatus?.session;
    if (session == null) return;
    CashOutModal.show(
      context,
      sessionId: session.id,
      service: _service,
      onSuccess: _loadData,
    );
  }

  void _openCloseSessionModal() {
    final session = _currentStatus?.session;
    if (session == null) return;
    CashCloseDialog.show(
      context,
      sessionId: session.id,
      service: _service,
      onClosed: (reconciliation) {
        ReconciliationSummaryDialog.show(
          context,
          reconciliation: reconciliation,
          onDismiss: _loadData,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfessional) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caja / Turno'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        body: _buildForbiddenState(),
      );
    }

    if (_activeContextMissing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caja / Turno'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        body: _buildMissingContextState(),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Caja (SCR-16)'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Caja (SCR-16)'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        body: _buildErrorState(),
      );
    }

    if (!_canViewHistory) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Caja (SCR-16)', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar Caja',
              onPressed: _loadData,
            ),
          ],
        ),
        body: _buildCurrentTurnView(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Caja (SCR-16)', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar Caja',
              onPressed: _loadData,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Turno Actual'),
              Tab(icon: Icon(Icons.history), text: 'Histórico de Turnos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCurrentTurnView(),
            _buildHistoryView(),
          ],
        ),
      ),
    );
  }

  Widget _buildForbiddenState() {
    return Center(
      key: const Key('state_cash_forbidden_role'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Acceso Restringido a Caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Tu rol asignado (PROFESSIONAL) no cuenta con permisos para operar o auditar la caja.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingContextState() {
    return Center(
      key: const Key('state_active_context_missing'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.store_mall_directory_outlined, color: Colors.amber, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Sin Sede Activa Seleccionada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Debes seleccionar una sede operativa para acceder a la gestión de caja.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            if (widget.onNavigateToContextSelector != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Seleccionar Sede'),
                onPressed: widget.onNavigateToContextSelector,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTurnView() {
    final status = _currentStatus;
    if (status == null || !status.isOpen || status.session == null) {
      return _buildNoOpenSessionState();
    }

    final session = status.session!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        key: const Key('state_open_session'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionHeaderCard(session),
          const SizedBox(height: 16),
          _buildMetricsGrid(session),
          const SizedBox(height: 16),
          _buildActionButtonsRow(session),
          const SizedBox(height: 24),
          _buildMovementsSection(session),
        ],
      ),
    );
  }

  Widget _buildNoOpenSessionState() {
    return Center(
      key: const Key('state_no_open_session'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_outlined, size: 54, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay un turno de caja abierto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para registrar cobros en efectivo en POS o gestionar movimientos, primero debes abrir el turno de caja con una base inicial.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('btn_open_session_modal'),
              onPressed: _openOpenSessionModal,
              icon: const Icon(Icons.add),
              label: const Text('Abrir Turno de Caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeaderCard(SaasCashSession session) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.point_of_sale, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Turno de Caja Abierto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text('ACTIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green.shade800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apertura: ${session.openedAt.toLocal().toString().substring(0, 16)} • Por: ${session.openedByUserName ?? "Operador"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(SaasCashSession session) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _metricTile('Base Inicial', '\$${session.openingBalance.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, Colors.indigo)),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(child: _metricTile('Ventas Efectivo', '\$${session.cashSalesTotal.toStringAsFixed(2)}', Icons.point_of_sale, Colors.green.shade700)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _metricTile('Ingresos Manuales', '+\$${session.cashInTotal.toStringAsFixed(2)}', Icons.add_circle_outline, Colors.teal)),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(child: _metricTile('Egresos Manuales', '-\$${session.cashOutTotal.toStringAsFixed(2)}', Icons.remove_circle_outline, Colors.red.shade700)),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo Esperado en Caja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
                  Text(
                    session.expectedCash != null ? '\$${session.expectedCash!.toStringAsFixed(2)}' : '--- (Cierre Ciego)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow(SaasCashSession session) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('btn_open_cash_in_modal'),
            onPressed: _openCashInModal,
            icon: const Icon(Icons.add, color: Colors.green),
            label: const Text('Ingreso', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('btn_open_cash_out_modal'),
            onPressed: _openCashOutModal,
            icon: const Icon(Icons.remove, color: Colors.red),
            label: const Text('Egreso', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('btn_open_close_session_modal'),
            onPressed: _openCloseSessionModal,
            icon: const Icon(Icons.lock_clock),
            label: const Text('Cerrar Caja', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsSection(SaasCashSession session) {
    final movements = session.movements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Movimientos del Turno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${movements.length} registrados', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        if (movements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            child: const Center(child: Text('No hay movimientos registrados aún en este turno.', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final mov = movements[index];
              return _buildMovementItem(mov);
            },
          ),
      ],
    );
  }

  Widget _buildMovementItem(SaasCashMovement mov) {
    Color badgeColor = Colors.indigo;
    IconData icon = Icons.inventory;
    String typeLabel = 'Apertura';

    if (mov.isCashSale) {
      badgeColor = Colors.green;
      icon = Icons.point_of_sale;
      typeLabel = 'Cobro de Venta (POS)';
    } else if (mov.isCashIn) {
      badgeColor = Colors.teal;
      icon = Icons.add_circle_outline;
      typeLabel = 'Ingreso (${mov.category ?? ""})';
    } else if (mov.isCashOut) {
      badgeColor = Colors.red;
      icon = Icons.remove_circle_outline;
      typeLabel = 'Egreso (${mov.category ?? ""})';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (mov.ticketNumber != null)
                  Text('Folio: ${mov.ticketNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                if (mov.reason != null && mov.reason!.isNotEmpty)
                  Text(mov.reason!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '${mov.createdAt.toLocal().toString().substring(11, 16)} • Por: ${mov.performedByUserName ?? "Operador"}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${mov.isCashOut ? "-" : "+"}\$${mov.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: mov.isCashOut ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    final history = _historyResponse;
    final items = history?.items ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No hay turnos cerrados en el historial', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final sess = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno #${sess.id.substring(0, sess.id.length > 8 ? 8 : sess.id.length)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apertura: ${sess.openedAt.toLocal().toString().substring(0, 16)} • Cierre: ${sess.closedAt != null ? sess.closedAt!.toLocal().toString().substring(0, 16) : "En curso"}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Esperado: \$${(sess.expectedCash ?? 0.0).toStringAsFixed(2)} | Contado: \$${(sess.countedCash ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('btn_ver_detalle_${sess.id}'),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () async {
                    try {
                      final detail = await _service.getSessionDetail(sess.id);
                      if (context.mounted) {
                        SessionDetailDialog.show(context, session: detail.session, movements: detail.movements);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        SessionDetailDialog.show(context, session: sess, movements: sess.movements);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
