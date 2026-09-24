// frontend/lib/screens/saas/staff_directory_screen.dart
// GO-08.41 / GO-08.43: SCR-14 Staff Directory Screen

import 'package:flutter/material.dart';
import '../../models/saas_staff_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas_staff_service.dart';
import 'widgets/staff_invite_modal.dart';
import 'widgets/staff_relation_type_dialog.dart';
import 'widgets/staff_role_dialog.dart';
import 'widgets/staff_status_dialog.dart';

/// StaffDirectoryScreen (SCR-14)
///
/// Pantalla principal para la administración de personal e invitaciones en GlowApp SaaS.
/// Implementa las especificaciones funcionales y de UX ratificadas en GO-08.41.
class StaffDirectoryScreen extends StatefulWidget {
  final SaasStaffService? service;
  final String? initialRole;
  final int? currentUserId;
  final VoidCallback? onNavigateToContextSelector;

  const StaffDirectoryScreen({
    super.key,
    this.service,
    this.initialRole,
    this.currentUserId,
    this.onNavigateToContextSelector,
  });

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final SaasStaffService _service;
  late final ActiveContextHolder _contextHolder;
  late TabController _tabController;

  bool _isLoading = true;
  bool _activeContextMissing = false;
  String? _errorMessage;

  // Filtros de Personal
  String _selectedRole = 'ALL';
  String _selectedStatus = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  List<StaffMember> _staffMembers = [];
  List<StaffInvitation> _pendingInvitations = [];

  // RBAC
  String get _currentRole => widget.initialRole ?? 'OWNER';
  int get _currentUserId => widget.currentUserId ?? 1;

  bool get _isOwner => _currentRole == 'OWNER';
  bool get _isManager => _currentRole == 'MANAGER';
  bool get _canInvite => _isOwner || _isManager;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasStaffService();
    _contextHolder = ActiveContextHolder();
    _tabController = TabController(length: 2, vsync: this);
    _checkContextAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkContextAndLoad() {
    if (!_contextHolder.hasActiveContext) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
      });
      return;
    }
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _activeContextMissing = false;
      _errorMessage = null;
    });

    try {
      final staffFuture = _service.listStaff(
        role: _selectedRole,
        status: _selectedStatus,
        search: _searchController.text,
      );

      final invFuture = _canInvite
          ? _service.listInvitations(status: 'PENDING')
          : Future.value(StaffInvitationListResponse(invitations: []));

      final results = await Future.wait([staffFuture, invFuture]);
      final staffRes = results[0] as StaffListResponse;
      final invRes = results[1] as StaffInvitationListResponse;

      if (mounted) {
        setState(() {
          _staffMembers = staffRes.members;
          _pendingInvitations = invRes.invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _openInviteModal() {
    StaffInviteModal.show(
      context,
      service: _service,
      actorRole: _currentRole,
      onInvitationEmitted: (emission) {
        _loadAllData();
        _tabController.animateTo(1); // Cambiar a pestaña de Invitaciones
      },
    );
  }

  void _openRoleDialog(StaffMember member) {
    StaffRoleDialog.show(
      context,
      member: member,
      service: _service,
      actorRole: _currentRole,
      currentUserId: _currentUserId,
      onRoleUpdated: (updated) => _loadAllData(),
    );
  }

  void _openStatusDialog(StaffMember member) {
    StaffStatusDialog.show(
      context,
      member: member,
      service: _service,
      actorRole: _currentRole,
      currentUserId: _currentUserId,
      onStatusUpdated: (updated) => _loadAllData(),
    );
  }

  void _openRelationTypeDialog(StaffMember member) {
    StaffRelationTypeDialog.show(
      context,
      member: member,
      service: _service,
      onRelationTypeUpdated: (updated) => _loadAllData(),
    );
  }

  Future<void> _resendInvitation(StaffInvitation invitation) async {
    try {
      final result = await _service.resendInvitation(invitation.id);
      if (mounted) {
        _loadAllData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitación a ${invitation.email} renovada (+7 días).'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is SaasStaffException ? e.message : 'Error al reenviar invitación.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _revokeInvitation(StaffInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Invitación'),
        content: Text('¿Deseas revocar la invitación pendiente enviada a ${invitation.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cancelar Invitación'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.revokeInvitation(invitation.id);
      if (mounted) {
        _loadAllData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitación a ${invitation.email} cancelada exitosamente.'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is SaasStaffException ? e.message : 'Error al cancelar invitación.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo y Colaboradores', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.people_alt_outlined),
              text: 'Personal (${_staffMembers.length})',
            ),
            Tab(
              icon: const Icon(Icons.mail_outline),
              text: 'Invitaciones (${_pendingInvitations.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('btn_refresh_staff'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refrescar',
          ),
          if (_canInvite)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                key: const Key('btn_invitar_colaborador'),
                onPressed: _openInviteModal,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Invitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_activeContextMissing) {
      return _buildMissingContextState();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('staff_loading_indicator')),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildStaffTab(),
        _buildInvitationsTab(),
      ],
    );
  }

  Widget _buildMissingContextState() {
    return Center(
      key: const Key('state_active_context_missing'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text(
              'Contexto de Sede Requerido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Debes seleccionar una sede activa para acceder a la administración de personal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (widget.onNavigateToContextSelector != null)
              ElevatedButton.icon(
                key: const Key('btn_go_to_context_selector'),
                onPressed: widget.onNavigateToContextSelector,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Seleccionar Sede'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const Key('state_staff_error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('btn_retry_staff'),
              onPressed: _loadAllData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: PERSONAL ────────────────────────────────────────────────
  Widget _buildStaffTab() {
    return Column(
      children: [
        _buildStaffFiltersBar(),
        Expanded(
          child: _staffMembers.isEmpty
              ? _buildEmptyStaffView()
              : ListView.separated(
                  key: const Key('list_staff_members'),
                  padding: const EdgeInsets.all(12),
                  itemCount: _staffMembers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = _staffMembers[index];
                    return _buildStaffMemberCard(member);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            key: const Key('input_search_staff'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o correo...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadAllData();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _loadAllData(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Rol:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                key: const Key('dropdown_filter_role'),
                value: _selectedRole,
                isDense: true,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Todos los roles')),
                  DropdownMenuItem(value: 'OWNER', child: Text('Propietarios')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Managers')),
                  DropdownMenuItem(value: 'PROFESSIONAL', child: Text('Profesionales')),
                  DropdownMenuItem(value: 'RECEPTIONIST', child: Text('Recepcionistas')),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedRole) {
                    setState(() => _selectedRole = val);
                    _loadAllData();
                  }
                },
              ),
              const Spacer(),
              const Text('Estado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                key: const Key('dropdown_filter_status'),
                value: _selectedStatus,
                isDense: true,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Activos')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspendidos')),
                  DropdownMenuItem(value: 'REVOKED', child: Text('Revocados')),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedStatus) {
                    setState(() => _selectedStatus = val);
                    _loadAllData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStaffView() {
    return Center(
      key: const Key('state_empty_staff'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay colaboradores encontrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se encontraron miembros de equipo con los filtros seleccionados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (_canInvite) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                key: const Key('btn_empty_invite_staff'),
                onPressed: _openInviteModal,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Invitar Primer Colaborador'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStaffMemberCard(StaffMember member) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: member.isActive ? Colors.indigo.shade50 : Colors.grey.shade200,
                  child: Text(
                    member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: member.isActive ? Colors.indigo : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.userName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.userEmail,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(member.status),
                    const SizedBox(height: 4),
                    _buildRoleBadge(member.role),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.handshake_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Relación: ${_formatRelationLabel(member.relationType)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                if (member.joinedAt != null)
                  Text(
                    'Ingreso: ${member.joinedAt!.year}-${member.joinedAt!.month.toString().padLeft(2, '0')}-${member.joinedAt!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),

            // Acciones de Gestión de Personal
            if (_canInvite && !member.isRevoked) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isOwner)
                    TextButton.icon(
                      key: Key('btn_relation_member_${member.membershipId}'),
                      icon: const Icon(Icons.business_center_outlined, size: 16),
                      label: const Text('Contrato'),
                      onPressed: () => _openRelationTypeDialog(member),
                    ),
                  TextButton.icon(
                    key: Key('btn_role_member_${member.membershipId}'),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('Cambiar Rol'),
                    onPressed: () => _openRoleDialog(member),
                  ),
                  TextButton.icon(
                    key: Key('btn_status_member_${member.membershipId}'),
                    icon: Icon(
                      member.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 16,
                      color: member.isActive ? Colors.amber.shade800 : Colors.green,
                    ),
                    label: Text(
                      member.isActive ? 'Suspender' : 'Reactivar',
                      style: TextStyle(
                        color: member.isActive ? Colors.amber.shade800 : Colors.green,
                      ),
                    ),
                    onPressed: () => _openStatusDialog(member),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: INVITACIONES PENDIENTES ─────────────────────────────────
  Widget _buildInvitationsTab() {
    if (_pendingInvitations.isEmpty) {
      return Center(
        key: const Key('state_empty_invitations'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay invitaciones pendientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todas las invitaciones emitidas han sido aceptadas, canceladas o expiraron.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (_canInvite) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('btn_empty_emit_invite'),
                  onPressed: _openInviteModal,
                  icon: const Icon(Icons.send),
                  label: const Text('Emitir Nueva Invitación'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('list_pending_invitations'),
      padding: const EdgeInsets.all(12),
      itemCount: _pendingInvitations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final inv = _pendingInvitations[index];
        return _buildInvitationCard(inv);
      },
    );
  }

  Widget _buildInvitationCard(StaffInvitation invitation) {
    final daysRemaining = invitation.expiresAt.difference(DateTime.now()).inDays;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber.shade100,
                  child: const Icon(Icons.hourglass_top, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rol: ${_formatRoleLabel(invitation.role)} • ${_formatRelationLabel(invitation.relationType)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    daysRemaining >= 0 ? 'Expira en $daysRemaining d' : 'Expirada',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                if (invitation.inviterName != null)
                  Text(
                    'Emitida por: ${invitation.inviterName}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const Spacer(),
                TextButton.icon(
                  key: Key('btn_resend_invite_${invitation.id}'),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reenviar'),
                  onPressed: () => _resendInvitation(invitation),
                ),
                TextButton.icon(
                  key: Key('btn_cancel_invite_${invitation.id}'),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                  label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                  onPressed: () => _revokeInvitation(invitation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── BADGES ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Activo';
        break;
      case 'SUSPENDED':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Suspendido';
        break;
      case 'REVOKED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Revocado';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;

    switch (role) {
      case 'OWNER':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        break;
      case 'MANAGER':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'PROFESSIONAL':
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  String _formatRelationLabel(String relation) {
    switch (relation) {
      case 'STAFF_EMPLOYEE':
        return 'Empleado Nómina';
      case 'INDEPENDENT_PROVIDER':
        return 'Independiente Porcentual';
      case 'OWNER_PARTNER':
        return 'Socio Partner';
      default:
        return relation;
    }
  }

  String _formatRoleLabel(String role) {
    switch (role) {
      case 'OWNER':
        return 'Propietario';
      case 'MANAGER':
        return 'Administrador';
      case 'PROFESSIONAL':
        return 'Profesional';
      case 'RECEPTIONIST':
        return 'Recepcionista';
      default:
        return role;
    }
  }
}
