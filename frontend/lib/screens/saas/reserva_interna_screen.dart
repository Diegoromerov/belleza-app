// frontend/lib/screens/saas/reserva_interna_screen.dart
// NODO-07 / SCR-11: Reserva Interna / Creación de Cita con Slots

import 'package:flutter/material.dart';
import '../../models/saas/saas_reserva_interna_models.dart';
import '../../models/saas/service_offer_assignment_model.dart';
import '../../services/saas/saas_reserva_interna_service.dart';
import 'widgets/customer_typeahead.dart';

class ReservaInternaScreen extends StatefulWidget {
  final SaasReservaInternaService? service;
  final String? initialDate;
  final String? preselectedMembershipId;
  final String? userRole;
  final VoidCallback? onAppointmentCreated;
  final VoidCallback? onCancel;

  const ReservaInternaScreen({
    super.key,
    this.service,
    this.initialDate,
    this.preselectedMembershipId,
    this.userRole,
    this.onAppointmentCreated,
    this.onCancel,
  });

  @override
  State<ReservaInternaScreen> createState() => _ReservaInternaScreenState();
}

class _ReservaInternaScreenState extends State<ReservaInternaScreen> {
  late final SaasReservaInternaService _service;
  late String _targetDate;

  bool _isLoadingInitial = true;
  bool _isLoadingSlots = false;
  bool _isCreating = false;
  String? _errorMessage;

  List<ServiceOfferModel> _serviceOffers = [];
  List<StaffMemberOption> _staffMembers = [];

  ServiceOfferModel? _selectedOffer;
  String? _selectedMembershipId; // null = AGGREGATED ("Cualquiera")
  String? _explicitAssignedMembershipId; // DEC-S11-004 / DEC-S11-006

  SaasAvailabilityProjection? _projection;
  SaasAvailabilitySlot? _selectedSlot;

  // Cliente (DEC-S11-002: Default GUEST)
  bool _isGuestMode = true;
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _guestEmailController = TextEditingController();
  final _customerUserIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasReservaInternaService();

    // DEC-S11-003: Heredar fecha inicial si se suministra
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      _targetDate = widget.initialDate!;
    } else {
      final now = DateTime.now();
      _targetDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    // DEC-S11-001 & DEC-S11-005: Confinar si es PROFESSIONAL
    if (_isProfessionalOnly) {
      _selectedMembershipId = widget.preselectedMembershipId;
    } else {
      _selectedMembershipId = widget.preselectedMembershipId; // Puede ser null = AGGREGATED
    }

    _initData();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestEmailController.dispose();
    _customerUserIdController.dispose();
    super.dispose();
  }

  // DEC-S11-005: Purificación Canónica Estricta de Roles
  bool get _isProfessionalOnly {
    final role = widget.userRole?.toUpperCase();
    return role == 'PROFESSIONAL';
  }

  Future<void> _initData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      final offersFuture = _service.getServiceOffers();
      final staffFuture = _service.getStaffMembers();

      final results = await Future.wait([offersFuture, staffFuture]);
      _serviceOffers = results[0] as List<ServiceOfferModel>;
      _staffMembers = results[1] as List<StaffMemberOption>;

      if (_serviceOffers.isNotEmpty) {
        _selectedOffer = _serviceOffers.first;
      }

      setState(() {
        _isLoadingInitial = false;
      });

      if (_selectedOffer != null) {
        await _loadAvailability();
      }
    } catch (e) {
      setState(() {
        _isLoadingInitial = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('SaasReservaInternaException: ', '');
      });
    }
  }

  Future<void> _loadAvailability() async {
    if (_selectedOffer == null) return;

    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
      _explicitAssignedMembershipId = null;
    });

    try {
      final mode = (_selectedMembershipId == null && !_isProfessionalOnly) ? 'AGGREGATED' : 'TARGETED';
      final proj = await _service.getAvailabilityProjection(
        serviceOfferId: _selectedOffer!.id,
        targetDate: _targetDate,
        membershipId: _selectedMembershipId,
        projectionMode: mode,
      );

      setState(() {
        _projection = proj;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar disponibilidad: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeDateOffset(int offsetDays) {
    try {
      final parts = _targetDate.split('-');
      final current = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final next = current.add(Duration(days: offsetDays));
      setState(() {
        _targetDate = '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
      });
      _loadAvailability();
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    try {
      final parts = _targetDate.split('-');
      final initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        setState(() {
          _targetDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        });
        _loadAvailability();
      }
    } catch (_) {}
  }

  String _getStaffName(String membershipId) {
    final staff = _staffMembers.where((s) => s.membershipId == membershipId);
    if (staff.isNotEmpty) return staff.first.name;
    return 'ID: $membershipId';
  }

  void _onSlotSelected(SaasAvailabilitySlot slot) {
    setState(() {
      _selectedSlot = slot;

      // DEC-S11-004 & DEC-S11-006:
      // En TARGETED (filtro explícito o rol PROFESSIONAL), se mantiene el seleccionado.
      if (_selectedMembershipId != null || _isProfessionalOnly) {
        _explicitAssignedMembershipId = _selectedMembershipId;
      } else {
        // En AGGREGATED (incluso si availableMemberships.length == 1):
        // Cero autoasignación: requiere SIEMPRE selección explícita del usuario.
        _explicitAssignedMembershipId = null;
      }
    });
  }

  bool get _isCreationValid {
    if (_selectedOffer == null) return false;
    if (_selectedSlot == null) return false;

    // DEC-S11-004 / DEC-S11-006: Requiere profesional explícito concreto
    final effectiveStaff = _explicitAssignedMembershipId ?? (_isProfessionalOnly ? _selectedMembershipId : null);
    if (effectiveStaff == null || effectiveStaff.isEmpty) return false;

    // DEC-S11-002: Validar cliente XOR
    if (_isGuestMode) {
      if (_guestNameController.text.trim().length < 2) return false;
      if (_guestPhoneController.text.trim().length < 7) return false;
    } else {
      final id = int.tryParse(_customerUserIdController.text.trim());
      if (id == null || id <= 0) return false;
    }

    return true;
  }

  Future<void> _submitAppointment() async {
    if (!_isCreationValid) return;

    final effectiveStaff = _explicitAssignedMembershipId ?? _selectedMembershipId!;
    // Parsear scheduled_at ISO-8601 combinando targetDate + slot.startTime
    final scheduledAtIso = '${_targetDate}T${_selectedSlot!.startTime}:00.000Z';

    final payload = CreateAppointmentPayload(
      serviceOfferId: _selectedOffer!.id,
      membershipId: effectiveStaff,
      scheduledAt: scheduledAtIso,
      customerUserId: _isGuestMode ? null : int.parse(_customerUserIdController.text.trim()),
      guestName: _isGuestMode ? _guestNameController.text.trim() : null,
      guestPhone: _isGuestMode ? _guestPhoneController.text.trim() : null,
      guestEmail: _isGuestMode && _guestEmailController.text.trim().isNotEmpty
          ? _guestEmailController.text.trim()
          : null,
    );

    setState(() {
      _isCreating = true;
    });

    try {
      await _service.createAppointment(payload);
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cita creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (widget.onAppointmentCreated != null) {
        widget.onAppointmentCreated!();
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('409') || errStr.contains('APPOINTMENT_OCCUPANCY_COLLISION') || errStr.contains('ocupado')) {
          // Colisión de concurrencia: Alerta + Auto-reload
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conflicto de concurrencia: El horario seleccionado acaba de ser ocupado. Actualizando disponibilidad...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          // Recargar slots automáticamente
          _loadAvailability();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear cita: $errStr'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCR-11 — Reserva Interna'),
        leading: IconButton(
          key: const Key('btn_back_reserva'),
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingInitial
          ? const Center(key: Key('reserva_initial_loading'), child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  key: const Key('reserva_initial_error'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        key: const Key('btn_retry_initial'),
                        onPressed: _initData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildServiceSection(),
                    const SizedBox(height: 16),
                    _buildDateAndStaffSection(),
                    const SizedBox(height: 16),
                    _buildSlotsSection(),
                    if (_selectedSlot != null &&
                        _selectedMembershipId == null &&
                        !_isProfessionalOnly &&
                        _selectedSlot!.availableMemberships.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildExplicitStaffSelectorSection(),
                    ],
                    const SizedBox(height: 16),
                    _buildClientSection(),
                    const SizedBox(height: 16),
                    _buildSummarySection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('btn_confirm_create_appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: (_isCreating || !_isCreationValid) ? null : _submitAppointment,
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Confirmar y Agendar Cita',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      key: const Key('btn_cancel_reserva'),
                      onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildServiceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Servicio a Reservar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ServiceOfferModel>(
              key: const Key('dropdown_service_offers'),
              // ignore: deprecated_member_use
              value: _selectedOffer,
              isExpanded: true,
              items: _serviceOffers.map((offer) {
                return DropdownMenuItem<ServiceOfferModel>(
                  value: offer,
                  child: Text(
                    '${offer.name} (${offer.baseDuration} min - \$${offer.basePrice.toStringAsFixed(0)})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newOffer) {
                setState(() {
                  _selectedOffer = newOffer;
                });
                _loadAvailability();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndStaffSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('2. Fecha y Colaborador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            // Navegación de Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  key: const Key('btn_prev_date_reserva'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Día anterior',
                  onPressed: () => _changeDateOffset(-1),
                ),
                GestureDetector(
                  key: const Key('btn_pick_date_reserva'),
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Text(_targetDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('btn_next_date_reserva'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Día siguiente',
                  onPressed: () => _changeDateOffset(1),
                ),
              ],
            ),
            if (!_isProfessionalOnly) ...[
              const Divider(height: 16),
              const Text('Colaborador:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      key: const Key('chip_staff_aggregated'),
                      label: const Text('Todos los profesionales (Aggregated)'),
                      selected: _selectedMembershipId == null,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedMembershipId = null;
                          });
                          _loadAvailability();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ..._staffMembers.map((staff) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          key: Key('chip_staff_${staff.membershipId}'),
                          label: Text(staff.name),
                          selected: _selectedMembershipId == staff.membershipId,
                          onSelected: (val) {
                            setState(() {
                              _selectedMembershipId = val ? staff.membershipId : null;
                            });
                            _loadAvailability();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 16),
              Text(
                'Agenda Confinada: ${_getStaffName(_selectedMembershipId ?? "")}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('3. Horarios Disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_isLoadingSlots)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Consultando slots disponibles...')),
              )
            else if (_projection == null || _projection!.slots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No hay disponibilidad para los criterios seleccionados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _projection!.slots.map((slot) {
                  final isSelected = _selectedSlot?.startTime == slot.startTime && _selectedSlot?.endTime == slot.endTime;
                  return ChoiceChip(
                    key: Key('slot_chip_${slot.startTime}'),
                    label: Text('${slot.startTime} - ${slot.endTime}'),
                    selected: isSelected,
                    selectedColor: Colors.pink.shade100,
                    onSelected: (val) {
                      if (val) {
                        _onSlotSelected(slot);
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplicitStaffSelectorSection() {
    final availableIds = _selectedSlot!.availableMemberships;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. Seleccionar Profesional para este Horario (DEC-S11-004):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: availableIds.map((memId) {
                final isSelected = _explicitAssignedMembershipId == memId;
                return ChoiceChip(
                  key: Key('chip_explicit_staff_$memId'),
                  label: Text(_getStaffName(memId)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _explicitAssignedMembershipId = memId;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('5. Identidad del Cliente (DEC-S11-002)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  key: const Key('tab_client_guest'),
                  label: const Text('Invitado (Guest)'),
                  selected: _isGuestMode,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isGuestMode = true;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: const Key('tab_client_registered'),
                  label: const Text('Registrado (ID)'),
                  selected: !_isGuestMode,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isGuestMode = false;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isGuestMode) ...[
              TextField(
                key: const Key('input_guest_name'),
                controller: _guestNameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('input_guest_phone'),
                controller: _guestPhoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('input_guest_email'),
                controller: _guestEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (Opcional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ] else ...[
              CustomerTypeahead(
                hintText: 'Buscar en Directorio (Nombre/Tel/Email)...',
                onCustomerSelected: (customer) {
                  setState(() {
                    _customerUserIdController.text = customer.userId ?? customer.id;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('input_customer_user_id'),
                controller: _customerUserIdController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'ID de Usuario Registrado *',
                  hintText: 'Ej. 205',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final profId = _explicitAssignedMembershipId ??
        (_isProfessionalOnly ? _selectedMembershipId : null) ??
        '';
    final profName = profId.isNotEmpty ? _getStaffName(profId) : 'Por seleccionar';

    return Card(
      key: const Key('summary_card'),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('6. Resumen de Cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 16),
            _summaryRow('Servicio', _selectedOffer?.name ?? '-'),
            _summaryRow('Duración', _selectedOffer != null ? '${_selectedOffer!.baseDuration} min' : '-'),
            _summaryRow('Precio Base', _selectedOffer != null ? '\$${_selectedOffer!.basePrice.toStringAsFixed(2)}' : '-'),
            _summaryRow('Fecha', _targetDate),
            _summaryRow('Horario', _selectedSlot != null ? '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}' : 'No seleccionado'),
            _summaryRow('Atiende', profName),
            _summaryRow(
              'Cliente',
              _isGuestMode
                  ? (_guestNameController.text.trim().isNotEmpty ? _guestNameController.text.trim() : 'Invitado')
                  : (_customerUserIdController.text.trim().isNotEmpty ? 'ID: ${_customerUserIdController.text.trim()}' : 'No especificado'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
