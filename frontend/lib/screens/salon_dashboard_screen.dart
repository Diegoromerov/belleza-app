// frontend/lib/screens/salon_dashboard_screen.dart
// SOUL Design System — GlowApp v1.0
// Governance: Token.of(context), GlowIcon, TypographyTokens, Spacing, Radii, AppShadow

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'provider/business/business_dashboard_screen.dart';
import '../core/theme/tokens.dart';
import '../design/icons/glow_icon.dart';

class SalonDashboardScreen extends StatefulWidget {
  const SalonDashboardScreen({super.key});

  @override
  State<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends State<SalonDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _salonData;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _bookings = [];

  final _inviteEmailCtrl = TextEditingController();
  String _selectedSubRole = 'PRESTADOR_INDEPENDIENTE';
  bool _isInviting = false;
  String? _inviteResultLink;

  // ── Governance: token resolved from context (light/dark/expression-aware)
  Token get _t => Token.of(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchSalonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSalonData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthService.getMySalon();
      if (res != null && res['success'] == true) {
        final salon = Map<String, dynamic>.from(res['salon'] ?? {});
        final rawMembers = List<dynamic>.from(res['members'] ?? []);
        final membersList =
            rawMembers.map((m) => Map<String, dynamic>.from(m)).toList();

        List<Map<String, dynamic>> bookingsList = [];
        try {
          bookingsList = await ApiService.fetchProviderBookings();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _salonData = salon;
            _members = membersList;
            _bookings = bookingsList;
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _salonData = {
            'id': 1,
            'nombre_salon': 'Salón Elegance Studio',
            'nit': '901888777-1',
            'direccion': 'Calle 127 # 7-18',
            'telefono': '3109998877',
            'ciudad': 'Bogotá',
            'plan_saas': 'FREE_TRIAL',
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos del salón: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _showInviteDialog() async {
    _inviteEmailCtrl.clear();
    _selectedSubRole = 'PRESTADOR_INDEPENDIENTE';
    _inviteResultLink = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final t = Token.of(context);
          return AlertDialog(
            backgroundColor: t.surfaceLevel1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.xl)),
            title: Row(
              children: [
                GlowIcon.resolve(
                  'profile',
                  size: GlowIconSize.lg,
                  color: t.brandPrimary,
                  semanticLabel: 'Invitar al equipo',
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  'Invitar al Equipo',
                  style: TypographyTokens.h3(t),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agrega el correo del colaborador y define su rol dentro del salón.',
                    style: TypographyTokens.bodySmall(t)
                        .copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    controller: _inviteEmailCtrl,
                    style: TextStyle(color: t.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: TextStyle(color: t.textSecondary),
                      filled: true,
                      fillColor: t.surfaceInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        borderSide: BorderSide(color: t.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        borderSide: BorderSide(color: t.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        borderSide:
                            BorderSide(color: t.borderFocus, width: 2),
                      ),
                      prefixIcon: GlowIcon.resolve(
                        'mail',
                        color: t.brandPrimary,
                        semanticLabel: 'Correo electrónico',
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Rol en el Salón',
                    style: TypographyTokens.bodySmall(t)
                        .copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md),
                    decoration: BoxDecoration(
                      color: t.surfaceInput,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubRole,
                        dropdownColor: t.surfaceLevel1,
                        isExpanded: true,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontFamily: TypographyFamilies.functional,
                          fontSize: 14,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ADMINISTRADOR',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'PRESTADOR_INDEPENDIENTE',
                            child: Text('Prestador Independiente'),
                          ),
                          DropdownMenuItem(
                            value: 'EMPLEADO',
                            child: Text('Empleado del Salón'),
                          ),
                          DropdownMenuItem(
                            value: 'RECEPCIONISTA',
                            child: Text('Recepcionista'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedSubRole = val);
                          }
                        },
                      ),
                    ),
                  ),
                  if (_inviteResultLink != null) ...[
                    const SizedBox(height: Spacing.lg),
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: t.status['success_bg'],
                        borderRadius: BorderRadius.circular(Radii.md),
                        border:
                            Border.all(color: t.status['success']!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ ¡Invitación Generada!',
                            style: TypographyTokens.body(t).copyWith(
                              color: t.status['success']!,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          SelectableText(
                            _inviteResultLink!,
                            style: TypographyTokens.bodySmall(t)
                                .copyWith(color: t.textPrimary),
                          ),
                          const SizedBox(height: Spacing.sm),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: _inviteResultLink!));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Enlace copiado al portapapeles')),
                              );
                            },
                            icon: GlowIcon.resolve(
                              'copy',
                              size: GlowIconSize.sm,
                              color: t.brandPrimaryOn,
                              semanticLabel: 'Copiar enlace',
                            ),
                            label: const Text('Copiar Enlace'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.brandPrimary,
                              foregroundColor: t.brandPrimaryOn,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Radii.round),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: t.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: _isInviting
                    ? null
                    : () async {
                        final email = _inviteEmailCtrl.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ingresa un correo válido')),
                          );
                          return;
                        }
                        setModalState(() => _isInviting = true);
                        try {
                          final salonId = _salonData?['id'] ?? 1;
                          final res = await AuthService.inviteTeamMember(
                            salonId: salonId is int
                                ? salonId
                                : int.parse(salonId.toString()),
                            email: email,
                            subRol: _selectedSubRole,
                          );
                          if (res != null && res['success'] == true) {
                            setModalState(() {
                              _inviteResultLink = res['invite_link'];
                              _isInviting = false;
                            });
                            _fetchSalonData();
                          } else {
                            setModalState(() => _isInviting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(res?['error'] ??
                                        'Error al generar invitación')),
                              );
                            }
                          }
                        } catch (e) {
                          setModalState(() => _isInviting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _t.brandPrimary,
                  foregroundColor: _t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.round),
                  ),
                ),
                child: _isInviting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _t.brandPrimaryOn,
                        ),
                      )
                    : const Text('Generar Invitación'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final salonName =
        _salonData?['nombre_salon'] ?? 'Salón Elegance Studio';
    final planSaas = _salonData?['plan_saas'] ?? 'FREE_TRIAL';

    return Scaffold(
      backgroundColor: t.surfaceLevel0,
      appBar: AppBar(
        backgroundColor: t.surfaceLevel1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: Spacing.lg,
        title: Row(
          children: [
            GlowIcon.resolve(
              'storefront',
              size: GlowIconSize.lg,
              color: t.brandPrimary,
              semanticLabel: 'Salón',
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salonName,
                    style: TypographyTokens.h3(t),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        'SALÓN',
                        style: TextStyle(
                          fontFamily: TypographyFamilies.functional,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xs, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.brandPrimary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(Radii.xs),
                        ),
                        child: Text(
                          planSaas.toString().replaceAll('_', ' '),
                          style: TextStyle(
                            fontFamily: TypographyFamilies.data,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: t.textAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: GlowIcon.resolve(
              'refresh',
              size: GlowIconSize.sm,
              color: t.textSecondary,
              semanticLabel: 'Actualizar datos',
            ),
            onPressed: _fetchSalonData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: GlowIcon.resolve(
              'logout',
              size: GlowIconSize.sm,
              color: t.textSecondary,
              semanticLabel: 'Cerrar sesión',
            ),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: t.borderSubtle, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: t.brandPrimary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: t.brandPrimary,
              unselectedLabelColor: t.textSecondary,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: TypographyFamilies.functional,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: TypographyFamilies.functional,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  icon: GlowIcon.resolve('dashboard',
                      size: GlowIconSize.sm, color: t.brandPrimary),
                  text: 'Resumen',
                ),
                Tab(
                  icon: GlowIcon.resolve('profile',
                      size: GlowIconSize.sm, color: t.textSecondary),
                  text: 'Equipo',
                ),
                Tab(
                  icon: GlowIcon.resolve('hair',
                      size: GlowIconSize.sm, color: t.textSecondary),
                  text: 'Servicios',
                ),
                Tab(
                  icon: GlowIcon.resolve('settings',
                      size: GlowIconSize.sm, color: t.textSecondary),
                  text: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: t.brandPrimary),
            )
          : _error != null
              ? _buildErrorState(t)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(t),
                    _buildTeamTab(t),
                    _buildServicesTab(t),
                    _buildSettingsTab(t),
                  ],
                ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState(Token t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowIcon.resolve(
              'error',
              size: GlowIconSize.xl,
              color: t.error,
              semanticLabel: 'Error',
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TypographyTokens.body(t)
                  .copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _fetchSalonData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.round),
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontFamily: TypographyFamilies.functional,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab(Token t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  t: t,
                  title: 'Citas Hoy',
                  value: '${_bookings.length}',
                  icon: GlowIcon.calendar(
                    color: t.info,
                    semanticLabel: 'Citas de hoy',
                  ),
                  accentColor: t.info,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildKpiCard(
                  t: t,
                  title: 'Equipo Activo',
                  value: '${_members.length}',
                  icon: GlowIcon.resolve(
                    'profile',
                    color: t.success,
                    semanticLabel: 'Equipo activo',
                  ),
                  accentColor: t.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),

          // Business health card — fully token-based, no hardcoded colors
          _buildBusinessHealthCard(t),
          const SizedBox(height: Spacing.xl),

          // Agenda header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agenda del salón',
                style: TypographyTokens.h3(t),
              ),
              Text(
                'Hoy',
                style: TextStyle(
                  fontFamily: TypographyFamilies.functional,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          _bookings.isEmpty
              ? _buildEmptyState(
                  t: t,
                  icon: GlowIcon.calendar(
                    size: GlowIconSize.xl,
                    color: t.textMuted,
                    semanticLabel: 'Sin citas',
                  ),
                  message: 'No hay citas agendadas para hoy',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    return _buildBookingCard(t, b);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBusinessHealthCard(Token t) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: t.premiumGradient,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: t.borderStrong.withValues(alpha: 0.4),
        ),
        boxShadow: AppShadow.card(t),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: t.brandPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: GlowIcon.resolve(
              'badge',
              size: GlowIconSize.lg,
              color: t.textAccent,
              semanticLabel: 'Salud legal',
            ),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salud Legal & Normativa',
                  style: TypographyTokens.body(t).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Bioseguridad RH1, Concepto Sanitario y Contratos.',
                  style: TypographyTokens.bodySmall(t)
                      .copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BusinessDashboardScreen()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: t.textAccent,
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md, vertical: Spacing.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ver',
                  style: TextStyle(
                    fontFamily: TypographyFamilies.functional,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                GlowIcon.forward(
                  size: GlowIconSize.xs,
                  color: t.textAccent,
                  semanticLabel: 'Ir a centro de negocios',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Token t, Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: t.surfaceLevel1,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: t.borderSubtle),
        boxShadow: AppShadow.soft(t),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.xs),
        leading: CircleAvatar(
          backgroundColor: t.brandPrimary.withValues(alpha: 0.12),
          child: GlowIcon.resolve(
            'hair',
            color: t.brandPrimary,
            semanticLabel: 'Servicio',
          ),
        ),
        title: Text(
          b['service_name'] ?? 'Servicio de Belleza',
          style: TypographyTokens.body(t)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Cliente: ${b['client_name'] ?? 'Cliente Demo'}',
          style: TypographyTokens.bodySmall(t)
              .copyWith(color: t.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: Spacing.xs),
          decoration: BoxDecoration(
            color: t.successBg,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            (b['status'] ?? 'CONFIRMADA').toUpperCase(),
            style: TextStyle(
              fontFamily: TypographyFamilies.functional,
              color: t.successOn,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Team tab ──────────────────────────────────────────────────────────────

  Widget _buildTeamTab(Token t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal y Colaboradores',
                style: TypographyTokens.h3(t),
              ),
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: GlowIcon.resolve(
                  'profile',
                  size: GlowIconSize.sm,
                  color: t.brandPrimaryOn,
                  semanticLabel: 'Invitar',
                ),
                label: const Text('Invitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.round),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _members.isEmpty
              ? _buildEmptyState(
                  t: t,
                  icon: GlowIcon.resolve(
                    'profile',
                    size: GlowIconSize.xl,
                    color: t.textMuted,
                    semanticLabel: 'Sin colaboradores',
                  ),
                  message:
                      'Aún no has agregado colaboradores a tu equipo.',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final m = _members[index];
                    return _buildMemberCard(t, m);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Token t, Map<String, dynamic> m) {
    final subRol = m['sub_rol'] ?? 'DUEÑO';
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      decoration: BoxDecoration(
        color: t.surfaceLevel1,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: t.borderSubtle),
        boxShadow: AppShadow.soft(t),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg, vertical: Spacing.xs),
        leading: CircleAvatar(
          backgroundColor: t.info.withValues(alpha: 0.12),
          child: GlowIcon.resolve(
            'profile',
            color: t.info,
            semanticLabel: 'Colaborador',
          ),
        ),
        title: Text(
          m['nombre'] ?? 'Colaborador',
          style: TypographyTokens.body(t)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          m['email'] ?? '',
          style: TypographyTokens.bodySmall(t)
              .copyWith(color: t.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: Spacing.xs),
          decoration: BoxDecoration(
            color: t.brandPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            subRol.replaceAll('_', ' '),
            style: TextStyle(
              fontFamily: TypographyFamilies.functional,
              color: t.textAccent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Services tab ──────────────────────────────────────────────────────────

  Widget _buildServicesTab(Token t) {
    final defaultServices = [
      {
        'name': 'Corte + Cepillado Personalizado',
        'price': '\$65.000 COP',
        'duration': '45 min',
        'icon': 'hair',
      },
      {
        'name': 'Balayage & Colorimetría Avanzada',
        'price': '\$280.000 COP',
        'duration': '180 min',
        'icon': 'hair',
      },
      {
        'name': 'Manicura Semipermanente Profesional',
        'price': '\$55.000 COP',
        'duration': '60 min',
        'icon': 'nails',
      },
      {
        'name': 'Tratamiento Capilar Hidratante Plex',
        'price': '\$95.000 COP',
        'duration': '60 min',
        'icon': 'spa',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: defaultServices.length,
      itemBuilder: (context, index) {
        final s = defaultServices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: Spacing.md),
          decoration: BoxDecoration(
            color: t.surfaceLevel1,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: t.borderSubtle),
            boxShadow: AppShadow.soft(t),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg, vertical: Spacing.sm),
            leading: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: t.successBg,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: GlowIcon.resolve(
                s['icon']!,
                size: GlowIconSize.sm,
                color: t.success,
                semanticLabel: 'Servicio',
              ),
            ),
            title: Text(
              s['name']!,
              style: TypographyTokens.body(t)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Duración estimada: ${s['duration']}',
              style: TypographyTokens.bodySmall(t)
                  .copyWith(color: t.textSecondary),
            ),
            trailing: Text(
              s['price']!,
              style: TypographyTokens.priceDisplay(t).copyWith(
                color: t.brandPrimary,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Settings tab ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab(Token t) {
    final address = _salonData?['direccion'] ?? 'Calle 127 # 7-18';
    final city = _salonData?['ciudad'] ?? 'Bogotá';
    final nit = _salonData?['nit'] ?? '901888777-1';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.surfaceLevel1,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: t.borderSubtle),
              boxShadow: AppShadow.soft(t),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Establecimiento',
                    style: TypographyTokens.h3(t),
                  ),
                  Divider(
                      color: t.borderSubtle, height: Spacing.xxl),
                  _buildSettingRow(t, 'badge', 'NIT / Registro', nit),
                  _buildSettingRow(
                      t, 'location', 'Dirección', '$address, $city'),
                  _buildSettingRow(
                      t, 'phone', 'Contacto', '+57 310 999 8877'),
                  _buildSettingRow(
                      t, 'star', 'Suscripción', 'Free Trial (SaaS PRO)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
      Token t, String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          GlowIcon.resolve(
            icon,
            size: GlowIconSize.sm,
            color: t.brandPrimary,
            semanticLabel: label,
          ),
          const SizedBox(width: Spacing.md),
          Text(
            '$label:',
            style: TypographyTokens.bodySmall(t)
                .copyWith(color: t.textSecondary),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              value,
              style: TypographyTokens.body(t).copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared components ─────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required Token t,
    required Widget icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xxxl),
      decoration: BoxDecoration(
        color: t.surfaceLevel1,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TypographyTokens.bodySmall(t)
                  .copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required Token t,
    required String title,
    required String value,
    required Widget icon,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: t.surfaceLevel1,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: t.borderSubtle),
        boxShadow: AppShadow.soft(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: (accentColor ?? t.brandPrimary).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: icon,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            value,
            style: TypographyTokens.priceDisplay(t),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            title,
            style: TypographyTokens.bodySmall(t)
                .copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}
