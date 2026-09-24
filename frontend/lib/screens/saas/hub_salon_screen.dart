// frontend/lib/screens/saas/hub_salon_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/hub_salon_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/hub_salon_service.dart';
import 'available_context_selector_screen.dart';

/// HubSalonScreen
///
/// Pantalla principal y Cockpit Operativo de la sede activa en GlowApp SaaS.
///
/// INVARIANTES ARQUITECTÓNICAS (NODO-07 FASE 4):
/// 1. Tenencia en RAM: Lee exclusivamente `ActiveContextHolder().activeMembershipId`.
/// 2. Cero mutación: Jamás ejecuta `setActiveMembershipId` durante su ciclo de vida.
/// 3. Guardián de contexto: Si `activeMembershipId == null`, muestra estado `active_context_missing`.
/// 4. No data -> No card: Solo muestra datos reales provistos por `/summary` y `/staff`.
/// 5. Aislamiento B2C: Cero reutilización o acoplamiento con `ProviderDashboardScreen`.
/// 6. Fronteras N02..N06: Accesos de navegación modular hacia futuros contratos.
class HubSalonScreen extends StatefulWidget {
  final HubSalonService? service;
  final VoidCallback? onNavigateToCatalog;
  final VoidCallback? onNavigateToStaffSchedules;
  final VoidCallback? onNavigateToAgenda;
  final VoidCallback? onNavigateToCustomers;
  final VoidCallback? onNavigateToStaff;
  final VoidCallback? onNavigateToCashDrawer;
  final VoidCallback? onNavigateToContextSelector;

  const HubSalonScreen({
    Key? key,
    this.service,
    this.onNavigateToCatalog,
    this.onNavigateToStaffSchedules,
    this.onNavigateToAgenda,
    this.onNavigateToCustomers,
    this.onNavigateToStaff,
    this.onNavigateToCashDrawer,
    this.onNavigateToContextSelector,
  }) : super(key: key);

  @override
  State<HubSalonScreen> createState() => _HubSalonScreenState();
}

class _HubSalonScreenState extends State<HubSalonScreen> {
  late final HubSalonService _service;
  late final ActiveContextHolder _contextHolder;

  bool _isLoading = true;
  bool _isRetryingStaff = false;
  bool _activeContextMissing = false;
  String? _summaryError;
  HubCockpitData? _cockpitData;

  String? _lastLoadedMembershipId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HubSalonService();
    _contextHolder = ActiveContextHolder();
    _checkContextAndLoad();
  }

  void _checkContextAndLoad() {
    final activeId = _contextHolder.activeMembershipId;
    if (activeId == null || activeId.isEmpty) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
        _cockpitData = null;
        _summaryError = null;
      });
      return;
    }

    _lastLoadedMembershipId = activeId;
    _loadCockpitData();
  }

  Future<void> _loadCockpitData() async {
    setState(() {
      _isLoading = true;
      _activeContextMissing = false;
      _summaryError = null;
    });

    try {
      final data = await _service.getCockpitData();
      if (mounted) {
        setState(() {
          _cockpitData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.toString().replaceFirst('HubSalonException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryStaffOnly() async {
    if (_cockpitData == null) return;

    setState(() {
      _isRetryingStaff = true;
    });

    try {
      final staffResponse = await _service.getStaff();
      if (mounted) {
        setState(() {
          _cockpitData = HubCockpitData(
            summary: _cockpitData!.summary,
            staff: staffResponse,
            staffError: null,
          );
          _isRetryingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cockpitData = HubCockpitData(
            summary: _cockpitData!.summary,
            staff: null,
            staffError: e.toString().replaceFirst('HubSalonException: ', ''),
          );
          _isRetryingStaff = false;
        });
      }
    }
  }

  Future<void> _handleContextSwitch() async {
    if (widget.onNavigateToContextSelector != null) {
      widget.onNavigateToContextSelector!();
      _checkContextAndLoad();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AvailableContextSelectorScreen(),
      ),
    );

    if (!mounted) return;

    // Verificar si el contexto en memoria cambió tras la selección explícita
    final currentId = _contextHolder.activeMembershipId;
    if (currentId != _lastLoadedMembershipId) {
      _checkContextAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Estado: Active Context Missing
    if (_activeContextMissing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hub Salón SaaS'),
          centerTitle: true,
        ),
        body: _buildActiveContextMissingView(),
      );
    }

    // 2. Estado: Loading general
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando Salón...'),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Sincronizando información operativa...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Estado: Error de Resumen
    if (_summaryError != null || _cockpitData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hub Salón SaaS'),
          centerTitle: true,
        ),
        body: _buildErrorSummaryView(),
      );
    }

    // 4. Estados: Loaded / Empty Staff / Partial Success
    final summary = _cockpitData!.summary.summary;
    final establishment = summary.establishment;
    final org = summary.organization;
    final userContext = summary.activeUserContext;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              establishment.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${establishment.city ?? 'Sede'} • Rol: ${userContext.role}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('btn_cambiar_sede'),
            icon: const Icon(Icons.store),
            tooltip: 'Cambiar Sede / Contexto',
            onPressed: _handleContextSwitch,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCockpitData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContextCard(establishment, org, userContext),
              const SizedBox(height: 16),
              _buildEstablishmentInfoCard(establishment),
              const SizedBox(height: 16),
              _buildOperationalStatsCard(summary.staffSummary),
              const SizedBox(height: 24),
              _buildModuleShortcutsSection(),
              const SizedBox(height: 24),
              _buildStaffDirectorySection(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS DE ESTADO ──────────────────────────────────────────────

  Widget _buildActiveContextMissingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Contexto de Salón No Seleccionado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para operar en el Hub Salón debes seleccionar explícitamente una de tus sedes asignadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('btn_seleccionar_contexto_missing'),
              onPressed: _handleContextSwitch,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Seleccionar Sede Operativa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSummaryView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error al Cargar Hub Salón',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _summaryError ?? 'No fue posible consultar los datos de la sede activa.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('btn_reintentar_summary'),
              onPressed: _loadCockpitData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar Carga'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECCIÓN A & B: CONTEXTO Y ESTABLECIMIENTO ──────────────────────

  Widget _buildContextCard(
    HubEstablishment establishment,
    HubOrganization org,
    HubActiveUserContext userContext,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.domain, color: Colors.indigo, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    org.legalName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: establishment.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    establishment.isActive ? 'OPERACIONAL' : 'INACTIVO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: establishment.isActive ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rol Asignado: ${userContext.role}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tipo: ${userContext.relationType}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstablishmentInfoCard(HubEstablishment establishment) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Sede',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (establishment.address != null && establishment.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${establishment.address} (${establishment.city ?? 'Bogotá'})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (establishment.phone != null && establishment.phone!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    establishment.phone!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─── SECCIÓN C: MÉTRICAS OPERATIVAS (NO DATA -> NO CARD) ────────────

  Widget _buildOperationalStatsCard(HubStaffSummary staffSummary) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Activo Adscrito',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  '${staffSummary.activeMembersCount} colaboradores',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECCIÓN D: ACCIONES Y RUTAS MODULARES ──────────────────────────

  Widget _buildModuleShortcutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Módulos del Salón',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildShortcutButton(
                key: const Key('btn_modulo_catalogo'),
                icon: Icons.inventory_2_outlined,
                label: 'Catálogo (N02)',
                onTap: widget.onNavigateToCatalog ?? () => _showModulePlaceholder('Catálogo de Servicios (NODO-02)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                key: const Key('btn_modulo_personal'),
                icon: Icons.badge_outlined,
                label: 'Horarios (N03A)',
                onTap: widget.onNavigateToStaffSchedules ?? () => _showModulePlaceholder('Gestión de Horarios y Staff (NODO-03A)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                key: const Key('btn_modulo_agenda'),
                icon: Icons.calendar_month_outlined,
                label: 'Agenda (N06)',
                onTap: widget.onNavigateToAgenda ?? () => _showModulePlaceholder('Agenda y Citas (NODO-06)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildShortcutButton(
                key: const Key('btn_modulo_clientes'),
                icon: Icons.people_outline,
                label: 'Clientes (SCR-13)',
                onTap: widget.onNavigateToCustomers ?? () => _showModulePlaceholder('Directorio de Clientes (SCR-13)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildShortcutButton(
                key: const Key('btn_modulo_caja'),
                icon: Icons.point_of_sale_outlined,
                label: 'Caja (SCR-16)',
                onTap: widget.onNavigateToCashDrawer ?? () => _showModulePlaceholder('Gestión de Caja (SCR-16)'),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox.shrink()),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox.shrink()),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.indigo, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showModulePlaceholder(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Acceso a $moduleName (Módulo cerrado / Navegación futura)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── SECCIÓN E: DIRECTORIO DE PERSONAL ──────────────────────────────

  Widget _buildStaffDirectorySection() {
    final hasStaffError = _cockpitData?.hasStaffError ?? false;
    final staff = _cockpitData?.staff;
    final members = staff?.members ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Directorio de Personal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.onNavigateToStaff != null)
              TextButton.icon(
                key: const Key('btn_gestionar_personal'),
                icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                label: const Text('Administrar'),
                onPressed: widget.onNavigateToStaff,
              )
            else if (members.isNotEmpty)
              Text(
                '${members.length} registrados',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Estado: Partial Success (Staff falló)
        if (hasStaffError)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'No se pudo sincronizar el detalle del personal.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                _isRetryingStaff
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        key: const Key('btn_reintentar_staff'),
                        onPressed: _retryStaffOnly,
                        child: const Text('Reintentar'),
                      ),
              ],
            ),
          )

        // Estado: Empty Staff (Sin miembros)
        else if (members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.person_off_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No hay personal registrado en esta sede',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )

        // Estado: Loaded con miembros
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                title: Text(
                  member.userName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${member.userEmail} • ${member.relationType}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.role, // e.g. OWNER | PROFESSIONAL
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
