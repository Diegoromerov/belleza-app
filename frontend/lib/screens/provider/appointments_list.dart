// lib/screens/provider/appointments_list.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../widgets/provider/provider_luxe_components.dart';

class AppointmentsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> appointments;
  final Function(int id, String newStatus)? onStatusChanged;

  const AppointmentsListScreen({
    super.key,
    required this.appointments,
    this.onStatusChanged,
  });

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  String _selectedFilter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.appointments.where((a) {
      if (_selectedFilter == 'Todas') return true;
      final st = (a['estado'] ?? a['status'] ?? '').toString();
      return st.toUpperCase() == _selectedFilter.toUpperCase();
    }).toList();

    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GESTIÓN DE CITAS PRO',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // FILTRO DE ESTADOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: ['Todas', 'CONFIRMADA', 'COMPLETADA', 'CANCELADA'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      selectedColor: LuxeColors.gold871,
                      backgroundColor: LuxeColors.nude100,
                      labelStyle: TextStyle(
                        color: isSelected ? LuxeColors.nude900 : LuxeColors.nude700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: LuxeSpacing.md),

            // LISTA DE CITAS CON ESTADO VACÍO ELEGANTE
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_available, size: 56, color: LuxeColors.gold871),
                          const SizedBox(height: 16),
                          const Text(
                            'Día Libre / Sin Citas en este Estado',
                            style: TextStyle(fontFamily: 'Didot', fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tienes citas programadas bajo el filtro "$_selectedFilter"',
                            style: LuxeTypography.bodySm,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: LuxeSpacing.xl),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final id = item['id'] as int? ?? index;
                        final clientName = item['cliente_nombre'] ?? item['client_name'] ?? 'Cliente Glow';
                        final serviceName = item['servicio_nombre'] ?? item['service_name'] ?? 'Servicio de Belleza';
                        final timeText = item['hora'] ?? '10:00 AM';
                        final status = item['estado'] ?? 'CONFIRMADA';

                        return ProviderAppointmentTile(
                          clientName: clientName,
                          serviceName: serviceName,
                          timeText: timeText,
                          status: status,
                          onAccept: () {
                            widget.onStatusChanged?.call(id, 'COMPLETADA');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cita marcada como completada.'),
                                backgroundColor: LuxeColors.nude900,
                              ),
                            );
                          },
                          onReject: () {
                            widget.onStatusChanged?.call(id, 'CANCELADA');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
