// frontend/lib/screens/salon_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../shared/theme.dart';

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

  // Controllers para invitar miembros
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

        // Cargar citas de la API de proveedores
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
      } else {
        if (mounted) {
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
            backgroundColor: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.person_add_alt_1, color: Color(0xFFF3D59B)),
                SizedBox(width: 10),
                Text(
                  'Invitar al Equipo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresa el correo del colaborador para generar el enlace de invitación:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _inviteEmailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon:
                          const Icon(Icons.email, color: Color(0xFFF3D59B)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Rol en el Salón:',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubRole,
                        dropdownColor: const Color(0xFF0F172A),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
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
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ ¡Invitación Generada!',
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          SelectableText(
                            _inviteResultLink!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
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
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar Enlace'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC5A052),
                              foregroundColor: const Color(0xFF1F1A15),
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
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white60)),
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
                  backgroundColor: const Color(0xFFC5A052),
                  foregroundColor: const Color(0xFF1F1A15),
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

  @override
  Widget build(BuildContext context) {
    final salonName =
        _salonData?['nombre_salon'] ?? 'Salón Elegance Studio';
    final planSaas = _salonData?['plan_saas'] ?? 'FREE_TRIAL';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A052).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, color: Color(0xFFF3D59B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salonName,
                    style: const TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A052),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          planSaas.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1A15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Panel SaaS Salón',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
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
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchSalonData,
            tooltip: 'Actualizar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF3D59B),
          labelColor: const Color(0xFFF3D59B),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Equipo'),
            Tab(icon: Icon(Icons.cut_outlined), text: 'Servicios'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Ajustes'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC5A052)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSalonData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5A052),
                          foregroundColor: const Color(0xFF1F1A15),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        backgroundColor: const Color(0xFFC5A052),
        foregroundColor: const Color(0xFF1F1A15),
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Invitar Colaborador',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
                  icon: Icons.calendar_today,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Equipo Activo',
                  value: '${_members.length}',
                  icon: Icons.badge,
                  color: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Título Agenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Agenda del Salón',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Hoy',
                style: TextStyle(color: Color(0xFFF3D59B)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _bookings.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.event_available,
                            size: 40, color: Colors.white38),
                        SizedBox(height: 12),
                        Text(
                          'No hay citas agendadas para hoy',
                          style: TextStyle(color: Colors.white60),
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
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFC5A052).withValues(alpha: 0.2),
                          child: const Icon(Icons.content_cut,
                              color: Color(0xFFF3D59B)),
                        ),
                        title: Text(
                          b['service_name'] ?? 'Servicio de Belleza',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Cliente: ${b['client_name'] ?? 'Cliente Demo'}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (b['status'] ?? 'CONFIRMADA').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.greenAccent,
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
              const Text(
                'Personal y Colaboradores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Invitar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A052),
                  foregroundColor: const Color(0xFF1F1A15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _members.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Aún no has agregado colaboradores a tu equipo.',
                      style: TextStyle(color: Colors.white60),
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
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          child: const Icon(Icons.person,
                              color: Color(0xFF38BDF8)),
                        ),
                        title: Text(
                          m['nombre'] ?? 'Colaborador',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          m['email'] ?? '',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5A052).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC5A052)),
                          ),
                          child: Text(
                            subRol.replaceAll('_', ' '),
                            style: const TextStyle(
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
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.style, color: Color(0xFF34D399)),
            ),
            title: Text(
              s['name']!,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Duración estimada: ${s['duration']}',
              style: const TextStyle(color: Colors.white60),
            ),
            trailing: Text(
              s['price']!,
              style: const TextStyle(
                color: Color(0xFFF3D59B),
                fontWeight: FontWeight.bold,
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
            color: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Establecimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildSettingRow(Icons.pin, 'NIT / Registro', nit),
                  _buildSettingRow(Icons.location_on, 'Dirección', '$address, $city'),
                  _buildSettingRow(Icons.phone, 'Contacto', '+57 310 999 8877'),
                  _buildSettingRow(Icons.star, 'Plan de Suscripción', 'Free Trial (SaaS PRO)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF3D59B)),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
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
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
