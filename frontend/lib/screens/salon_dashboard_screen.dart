// frontend/lib/screens/salon_dashboard_screen.dart
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
          return AlertDialog(
            backgroundColor: _t.surfaceLevel1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.person_add_alt_1, color: Color(0xFFF3D59B)),
                SizedBox(width: 10),
                Text(
                  'Invitar al Equipo',
                  style: TextStyle(
                      color: _t.textPrimary, fontWeight: FontWeight.bold),
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
                    style: TypographyTokens.bodySmall(_t).copyWith(color: _t.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _inviteEmailCtrl,
                    style: TextStyle(color: _t.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: TextStyle(color: _t.textSecondary),
                      filled: true,
                      fillColor: _t.surfaceLevel0,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: GlowIcon.resolve(
                        'mail',
                        color: _t.brandPrimary,
                        semanticLabel: 'Correo electrónico',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Rol en el Salón:',
                      style: TextStyle(color: _t.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _t.surfaceLevel0,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _t.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubRole,
                        dropdownColor: _t.surfaceLevel0,
                        isExpanded: true,
                        style: TextStyle(color: _t.textPrimary),
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _t.status['success_bg'],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _t.status['success']!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ ¡Invitación Generada!',
                              style: TextStyle(
                                  color: _t.status['success']!,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          SelectableText(
                            _inviteResultLink!,
                            style: TextStyle(
                                color: _t.textPrimary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _inviteResultLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Enlace copiado al portapapeles')),
                              );
                            },
                            icon: GlowIcon.resolve(
                              'copy',
                              size: GlowIconSize.sm,
                              color: _t.surfaceLevel1,
                              semanticLabel: 'Copiar enlace',
                            ),
                            label: const Text('Copiar Enlace'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _t.brandPrimary,
                              foregroundColor: _t.surfaceLevel1,
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
                child: Text('Cancelar',
                    style: TextStyle(color: _t.textSecondary)),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(res?['error'] ??
                                      'Error al generar invitación')),
                            );
                          }
                        } catch (e) {
                          setModalState(() => _isInviting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _t.brandPrimary,
                  foregroundColor: _t.surfaceLevel1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isInviting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
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

  Token get _t => Token.light;

  @override
  Widget build(BuildContext context) {
    final salonName =
        _salonData?['nombre_salon'] ?? 'Salón Elegance Studio';
    final planSaas = _salonData?['plan_saas'] ?? 'FREE_TRIAL';

    return Scaffold(
      backgroundColor: _t.surfaceLevel0,
      appBar: AppBar(
        backgroundColor: _t.surfaceLevel1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            GlowIcon.resolve(
              'storefront',
              size: GlowIconSize.lg,
              color: _t.brandPrimary,
              semanticLabel: 'Salón',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salonName,
                    style: TypographyTokens.h3(_t).copyWith(color: _t.textPrimary),
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
                          color: _t.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        planSaas.toString().replaceAll('_', ' '),
                        style: TextStyle(
                          fontFamily: TypographyFamilies.data,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _t.textSecondary,
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
              color: _t.textSecondary,
              semanticLabel: 'Actualizar datos',
            ),
            onPressed: _fetchSalonData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: GlowIcon.resolve(
              'logout',
              color: _t.textSecondary,
              semanticLabel: 'Cerrar sesión',
            ),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _t.brandPrimary,
          indicatorWeight: 3,
          labelColor: _t.brandPrimary,
          unselectedLabelColor: _t.textSecondary,
          labelStyle: TextStyle(
            fontFamily: TypographyFamilies.functional,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: TypographyFamilies.functional,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: GlowIcon.resolve('dashboard',
                  size: GlowIconSize.sm, color: _t.brandPrimary),
              text: 'Resumen',
            ),
            Tab(
              icon: GlowIcon.resolve('profile',
                  size: GlowIconSize.sm, color: _t.textSecondary),
              text: 'Equipo',
            ),
            Tab(
              icon: GlowIcon.resolve('hair',
                  size: GlowIconSize.sm, color: _t.textSecondary),
              text: 'Servicios',
            ),
            Tab(
              icon: GlowIcon.resolve('settings',
                  size: GlowIconSize.sm, color: _t.textSecondary),
              text: 'Ajustes',
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: _t.brandPrimary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlowIcon.resolve(
                          'error',
                          size: GlowIconSize.xl,
                          color: _t.status['error']!,
                          semanticLabel: 'Error',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TypographyTokens.body(_t).copyWith(
                            color: _t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _fetchSalonData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _t.brandPrimary,
                              foregroundColor: _t.surfaceLevel1,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
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
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTeamTab(),
                    _buildServicesTab(),
                    _buildSettingsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas KPI Rápidas
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Citas Hoy',
                  value: '${_bookings.length}',
                  icon: GlowIcon.calendar(color: _t.status['info']!, semanticLabel: 'Citas de hoy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Equipo Activo',
                  value: '${_members.length}',
                  icon: GlowIcon.peopleAlt(color: _t.status['success']!, semanticLabel: 'Equipo activo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tarjeta: Ciclo de Vida y Salud del Negocio (Acceso al Business Engine)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF262018), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5A052).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A052).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFFF3D59B), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Salud Legal & Normativa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Bioseguridad RH1, Concepto Sanitario y Contratos de Sillas.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF3D59B),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver Centro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Título Agenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agenda del salón',
                style: TypographyTokens.h3(_t).copyWith(color: _t.textPrimary),
              ),
              Text(
                'Hoy',
                style: TextStyle(
                  fontFamily: TypographyFamilies.functional,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _t.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _bookings.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _t.surfaceLevel1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_available,
                            size: 40, color: _t.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'No hay citas agendadas para hoy',
                          style: TextStyle(color: _t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    return Card(
                      color: _t.surfaceLevel1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _t.brandPrimary.withValues(alpha: 0.2),
                          child: GlowIcon.resolve(
                            'hair',
                            color: _t.brandPrimary,
                            semanticLabel: 'Servicio',
                          ),
                        ),
                        title: Text(
                          b['service_name'] ?? 'Servicio de Belleza',
                          style: TextStyle(
                              color: _t.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Cliente: ${b['client_name'] ?? 'Cliente Demo'}',
                          style: TypographyTokens.bodySmall(_t).copyWith(color: _t.textSecondary),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _t.status['success_bg'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (b['status'] ?? 'CONFIRMADA').toUpperCase(),
                            style: TextStyle(
                              color: _t.status['success']!,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal y Colaboradores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _t.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: GlowIcon.resolve(
                    'profile',
                    size: GlowIconSize.sm,
                    color: _t.surfaceLevel1,
                    semanticLabel: 'Invitar',
                  ),
                label: const Text('Invitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _t.brandPrimary,
                  foregroundColor: _t.surfaceLevel1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _members.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _t.surfaceLevel1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Aún no has agregado colaboradores a tu equipo.',
                      style: TextStyle(color: _t.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final m = _members[index];
                    final subRol = m['sub_rol'] ?? 'DUEÑO';
                    return Card(
                      color: _t.surfaceLevel1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _t.status['info']!.withValues(alpha: 0.2),
                          child: GlowIcon.resolve(
                            'profile',
                            color: _t.status['info']!,
                            semanticLabel: 'Colaborador',
                          ),
                        ),
                        title: Text(
                          m['nombre'] ?? 'Colaborador',
                          style: TextStyle(
                              color: _t.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          m['email'] ?? '',
                          style: TypographyTokens.bodySmall(_t).copyWith(color: _t.textSecondary),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _t.brandPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                                ),
                          child: Text(
                            subRol.replaceAll('_', ' '),
                            style: TextStyle(
                              color: Color(0xFFF3D59B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final defaultServices = [
      {'name': 'Corte + Cepillado Personalizado', 'price': '\$65.000 COP', 'duration': '45 min'},
      {'name': 'Balayage & Colorimetría Avanzada', 'price': '\$280.000 COP', 'duration': '180 min'},
      {'name': 'Manicura Semipermanente Profesional', 'price': '\$55.000 COP', 'duration': '60 min'},
      {'name': 'Tratamiento Capilar Hidratante Plex', 'price': '\$95.000 COP', 'duration': '60 min'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: defaultServices.length,
      itemBuilder: (context, index) {
        final s = defaultServices[index];
        return Card(
          color: _t.surfaceLevel1,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _t.status['success']!.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GlowIcon.resolve(
                index == 2 ? 'nails' : 'beautyRitual',
                color: _t.status['success']!,
                semanticLabel: 'Servicio',
              ),
            ),
            title: Text(
              s['name']!,
              style: TypographyTokens.body(_t).copyWith(
                color: _t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Duración estimada: ${s['duration']}',
              style: TypographyTokens.bodySmall(_t).copyWith(color: _t.textSecondary),
            ),
            trailing: Text(
              s['price']!,
              style: TypographyTokens.priceDisplay(_t).copyWith(
                color: _t.brandPrimary,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final address = _salonData?['direccion'] ?? 'Calle 127 # 7-18';
    final city = _salonData?['ciudad'] ?? 'Bogotá';
    final nit = _salonData?['nit'] ?? '901888777-1';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _t.surfaceLevel1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Establecimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _t.textPrimary,
                    ),
                  ),
                  Divider(color: _t.borderSubtle, height: 24),
                  _buildSettingRow('badge', 'NIT / Registro', nit),
                  _buildSettingRow('location', 'Dirección', '$address, $city'),
                  _buildSettingRow('phone', 'Contacto', '+57 310 999 8877'),
                  _buildSettingRow('star', 'Plan de suscripción', 'Free Trial (SaaS PRO)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          GlowIcon.resolve(icon, size: GlowIconSize.sm, color: _t.brandPrimary, semanticLabel: label),
          const SizedBox(width: 12),
          Text('$label:', style: TypographyTokens.bodySmall(_t).copyWith(color: _t.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TypographyTokens.body(_t).copyWith(
                color: _t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Widget icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _t.surfaceLevel1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 12),
          Text(
            value,
            style: TypographyTokens.priceDisplay(_t).copyWith(
              color: _t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TypographyTokens.bodySmall(_t).copyWith(
              color: _t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

}
