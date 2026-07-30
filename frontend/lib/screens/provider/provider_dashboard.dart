// lib/screens/provider/provider_dashboard.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../widgets/provider/provider_luxe_components.dart';
import '../../widgets/provider/service_card.dart';
import 'appointments_list.dart';
import 'earnings_view.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String providerName;

  const ProviderDashboardScreen({
    super.key,
    this.providerName = 'Estudio Glow Pro',
  });

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final List<Map<String, dynamic>> _todayAppointments = [
    {
      'id': 1,
      'cliente_nombre': 'Carlos Mendoza',
      'servicio_nombre': 'Visagismo Barba & Corte',
      'hora': '09:30 AM',
      'estado': 'CONFIRMADA',
    },
    {
      'id': 2,
      'cliente_nombre': 'Mariana Silva',
      'servicio_nombre': 'Ritual Piel de Seda',
      'hora': '11:00 AM',
      'estado': 'COMPLETADA',
    },
  ];

  final List<Map<String, dynamic>> _myServices = [
    {'id': 101, 'nombre': 'Visagismo Barba & Corte', 'precio': 85000, 'duracion': '45 min'},
    {'id': 102, 'nombre': 'Ritual Piel de Seda Andina', 'precio': 140000, 'duracion': '60 min'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        title: Text(
          widget.providerName.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Didot',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: LuxeColors.gold871),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EarningsViewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxeSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DASHBOARD DE MÉTRICAS (GRID 2X2 CON BORDE DORADO 4PX)
              const Text(
                'RESUMEN OPERATIVO HOY',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: LuxeSpacing.lg,
                  mainAxisSpacing: LuxeSpacing.lg,
                ),
                children: const [
                  ProviderMetricCard(
                    label: 'Ingresos Hoy',
                    value: '\$225.000',
                    icon: Icons.payments_outlined,
                    subtitle: '+12% vs ayer',
                  ),
                  ProviderMetricCard(
                    label: 'Citas Hoy',
                    value: '4 Citas',
                    icon: Icons.calendar_today_outlined,
                    subtitle: '2 completadas',
                  ),
                  ProviderMetricCard(
                    label: 'Calificación',
                    value: '4.9 ★',
                    icon: Icons.star_border,
                    subtitle: '128 reseñas',
                  ),
                  ProviderMetricCard(
                    label: 'Servicios Pro',
                    value: '6 Activos',
                    icon: Icons.design_services_outlined,
                  ),
                ],
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 2. PRÓXIMAS CITAS HOY CON PROVIDERAPPOINTMENTTILE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CITAS PROGRAMADAS',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentsListScreen(appointments: _todayAppointments),
                        ),
                      );
                    },
                    child: const Text('Ver Agenda completa', style: TextStyle(color: LuxeColors.gold871, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayAppointments.length,
                itemBuilder: (context, index) {
                  final item = _todayAppointments[index];
                  return ProviderAppointmentTile(
                    clientName: item['cliente_nombre'],
                    serviceName: item['servicio_nombre'],
                    timeText: item['hora'],
                    status: item['estado'],
                  );
                },
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 3. CATÁLOGO DE SERVICIOS PROFEIONALES CON SERVICECARD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MIS SERVICIOS OFRECIDOS',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: LuxeColors.gold871),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myServices.length,
                separatorBuilder: (_, __) => const SizedBox(height: LuxeSpacing.md),
                itemBuilder: (context, index) {
                  return ServiceCard(service: _myServices[index]);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
