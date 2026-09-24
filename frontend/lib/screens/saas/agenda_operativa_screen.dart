import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/saas/saas_agenda_models.dart';
import '../../services/saas/saas_agenda_service.dart';

class AgendaOperativaScreen extends StatefulWidget {
  final SaasAgendaService? agendaService;
  final FutureOr<bool?> Function()? onNavigateToCreateAppointment;
  final VoidCallback? onNavigateBack;
  final String? initialDate;
  final String? userRole;

  const AgendaOperativaScreen({
    super.key,
    this.agendaService,
    this.onNavigateToCreateAppointment,
    this.onNavigateBack,
    this.initialDate,
    this.userRole,
  });

  @override
  State<AgendaOperativaScreen> createState() => _AgendaOperativaScreenState();
}

class _AgendaOperativaScreenState extends State<AgendaOperativaScreen> {
  late final SaasAgendaService _service;
  late String _targetDate;
  String? _selectedMembershipId;
  bool _isLoading = true;
  String? _errorMessage;
  SaasAgendaProjection? _projection;

  @override
  void initState() {
    super.initState();
    _service = widget.agendaService ?? SaasAgendaService();
    _targetDate = widget.initialDate ?? _formatDate(DateTime.now());
    _loadAgenda();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _getEffectiveRole() {
    if (widget.userRole != null && widget.userRole!.isNotEmpty) {
      return widget.userRole!.toUpperCase();
    }
    return 'OWNER';
  }

  bool get _isProfessionalOnly => _getEffectiveRole() == 'PROFESSIONAL';

  Future<void> _loadAgenda() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final membershipFilter = _isProfessionalOnly ? null : _selectedMembershipId;
      final projection = await _service.getAgendaProjection(
        targetDate: _targetDate,
        membershipId: membershipFilter,
      );

      if (mounted) {
        setState(() {
          _projection = projection;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('SaasAgendaException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _changeDateOffset(int days) {
    try {
      final current = DateTime.parse(_targetDate);
      final updated = current.add(Duration(days: days));
      setState(() {
        _targetDate = _formatDate(updated);
      });
      _loadAgenda();
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    try {
      final current = DateTime.tryParse(_targetDate) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (picked != null) {
        setState(() {
          _targetDate = _formatDate(picked);
        });
        _loadAgenda();
      }
    } catch (_) {}
  }

  Future<void> _handleStatusTransition(
    SaasAgendaAppointment appointment,
    SaasAppointmentStatus targetStatus,
  ) async {
    String? cancellationReason;

    // Regla 12 de NODO-06: IN_SERVICE -> CANCELLED requiere cancellation_reason
    if (appointment.status == SaasAppointmentStatus.inService &&
        targetStatus == SaasAppointmentStatus.cancelled) {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            key: const Key('dialog_cancellation_reason'),
            title: const Text('Motivo de Cancelación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'La cita está en servicio. Ingrese obligatoriamente el motivo de la cancelación:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_cancellation_reason'),
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                key: const Key('btn_confirm_cancel_reason'),
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Confirmar Cancelación'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
      cancellationReason = reasonController.text.trim();
    }

    try {
      await _service.updateAppointmentStatus(
        appointmentId: appointment.id,
        targetStatus: targetStatus.toBackendString(),
        cancellationReason: cancellationReason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cita actualizada a ${targetStatus.label}'),
            backgroundColor: targetStatus.color,
          ),
        );
        // Demand Refresh tras mutación exitosa
        _loadAgenda();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAppointmentDetailModal(String appointmentId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<SaasAppointmentDetailModel>(
          future: _service.getAppointmentDetail(appointmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                key: const Key('dialog_appointment_detail'),
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Container(
                key: const Key('dialog_appointment_detail'),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Error al cargar detalle'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                  ],
                ),
              );
            }

            final detail = snapshot.data!;
            return Container(
              key: const Key('dialog_appointment_detail'),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        detail.serviceNameSnapshot,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: detail.status.color.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: detail.status.color),
                        ),
                        child: Text(
                          detail.status.label,
                          style: TextStyle(
                            color: detail.status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _detailRow('Modo Cliente', detail.clientMode),
                  if (detail.guestName != null)
                    _detailRow('Invitado', detail.guestName!),
                  if (detail.guestPhone != null)
                    _detailRow('Teléfono Invitado', detail.guestPhone!),
                  if (detail.guestEmail != null)
                    _detailRow('Email Invitado', detail.guestEmail!),
                  if (detail.customerUserId != null)
                    _detailRow('ID Cliente Registrado', detail.customerUserId.toString()),
                  _detailRow('Duración Snapshot', '${detail.durationMinutesSnapshot} min'),
                  _detailRow('Precio Snapshot', '\$${detail.priceSnapshot.toStringAsFixed(2)}'),
                  _detailRow('Inicio Programado', detail.scheduledAt),
                  _detailRow('Fin Programado', detail.endTime),
                  if (detail.cancellationReason != null)
                    _detailRow('Motivo Cancelación', detail.cancellationReason!),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Operativa'),
        leading: IconButton(
          key: const Key('btn_back_agenda'),
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onNavigateBack ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          ElevatedButton.icon(
            key: const Key('btn_nueva_cita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva Cita'),
            onPressed: () async {
              if (widget.onNavigateToCreateAppointment != null) {
                final dynamic result = await widget.onNavigateToCreateAppointment!();
                if (result == true && mounted) {
                  _loadAgenda();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navegación a SCR-11 (Nueva Cita)')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigationBar(),
          if (!_isProfessionalOnly) _buildStaffFilterBar(),
          _buildOperationalSummary(),
          Expanded(child: _buildAgendaBody()),
        ],
      ),
    );
  }

  Widget _buildDateNavigationBar() {
    return Container(
      key: const Key('date_navigation_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('btn_prev_day'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDateOffset(-1),
          ),
          GestureDetector(
            key: const Key('btn_pick_date'),
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 6),
                Text(
                  _targetDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                key: const Key('btn_today'),
                onPressed: () {
                  setState(() {
                    _targetDate = _formatDate(DateTime.now());
                  });
                  _loadAgenda();
                },
                child: const Text('Hoy'),
              ),
              IconButton(
                key: const Key('btn_next_day'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeDateOffset(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffFilterBar() {
    final professionals = _projection?.professionals ?? [];
    return Container(
      key: const Key('staff_filter_bar'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              key: const Key('chip_staff_all'),
              label: const Text('Todos'),
              selected: _selectedMembershipId == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMembershipId = null;
                  });
                  _loadAgenda();
                }
              },
            ),
          ),
          ...professionals.map((prof) {
            final isSelected = _selectedMembershipId == prof.membershipId;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                key: Key('chip_staff_${prof.membershipId}'),
                label: Text(prof.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedMembershipId = selected ? prof.membershipId : null;
                  });
                  _loadAgenda();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOperationalSummary() {
    final professionals = _projection?.professionals ?? [];
    int totalAppts = 0;
    int inService = 0;
    int completed = 0;

    for (final prof in professionals) {
      for (final appt in prof.appointments) {
        totalAppts++;
        if (appt.status == SaasAppointmentStatus.inService) inService++;
        if (appt.status == SaasAppointmentStatus.completed) completed++;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricBadge('Citas Hoy', totalAppts.toString(), Colors.blue),
          _metricBadge('En Atención', inService.toString(), Colors.purple),
          _metricBadge('Finalizadas', completed.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAgendaBody() {
    if (_isLoading) {
      return const Center(
        key: Key('agenda_loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        key: const Key('agenda_error'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('btn_retry_agenda'),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: _loadAgenda,
              ),
            ],
          ),
        ),
      );
    }

    final professionals = _projection?.professionals ?? [];
    if (professionals.isEmpty) {
      return const Center(
        key: Key('agenda_empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No hay citas ni profesionales para este día.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const Key('agenda_refresh_indicator'),
      onRefresh: _loadAgenda,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final prof = professionals[index];
          return _buildProfessionalCard(prof);
        },
      ),
    );
  }

  Widget _buildProfessionalCard(SaasAgendaProfessional prof) {
    return Card(
      key: Key('prof_card_${prof.membershipId}'),
      margin: const EdgeInsets.only(bottom: 16),
      shape: _roundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        prof.name.isNotEmpty ? prof.name[0].toUpperCase() : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      prof.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (prof.shifts.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: prof.shifts.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${s.startTime} - ${s.endTime}',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            const Divider(height: 16),
            if (prof.appointments.isEmpty && prof.marketplaceBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Sin citas programadas.',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ...prof.appointments.map((appt) => _buildAppointmentTile(appt)),
            ...prof.marketplaceBookings.map((b) => _buildMarketplaceBookingTile(b)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTile(SaasAgendaAppointment appt) {
    final allowedTransitions = appt.status.allowedTransitions;

    return InkWell(
      key: Key('appt_tile_${appt.id}'),
      onTap: () => _showAppointmentDetailModal(appt.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${appt.startTime} - ${appt.endTime}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    appt.clientName,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              key: Key('status_badge_${appt.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appt.status.color.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: appt.status.color),
              ),
              child: Text(
                appt.status.label,
                style: TextStyle(
                  color: appt.status.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            if (!appt.status.isTerminal && allowedTransitions.isNotEmpty)
              PopupMenuButton<SaasAppointmentStatus>(
                key: Key('btn_actions_${appt.id}'),
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (newStatus) => _handleStatusTransition(appt, newStatus),
                itemBuilder: (context) {
                  return allowedTransitions.map((targetStatus) {
                    return PopupMenuItem<SaasAppointmentStatus>(
                      value: targetStatus,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward, size: 14, color: targetStatus.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              targetStatus.label,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceBookingTile(SaasAgendaMarketplaceBooking booking) {
    return Container(
      key: Key('marketplace_tile_${booking.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${booking.startTime} - ${booking.endTime}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '🔒 Ocupado (Reserva Marketplace B2C)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.deepOrange,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              booking.status,
              style: const TextStyle(fontSize: 10, color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }

  ShapeBorder _roundedRectangleBorder() {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  }
}
