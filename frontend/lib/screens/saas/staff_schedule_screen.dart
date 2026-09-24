// frontend/lib/screens/saas/staff_schedule_screen.dart
// NODO-03A UI / SCR-09: Staff Operational Availability & Schedule Screen

import 'package:flutter/material.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/staff_schedule_service.dart';
import '../../models/saas/staff_schedule_model.dart';

class StaffScheduleScreen extends StatefulWidget {
  final StaffScheduleService? service;
  final String? initialRole;
  final String? initialMembershipId;
  final String? initialEstablishmentName;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToContextSelector;

  const StaffScheduleScreen({
    super.key,
    this.service,
    this.initialRole,
    this.initialMembershipId,
    this.initialEstablishmentName,
    this.onBack,
    this.onNavigateToContextSelector,
  });

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  late final StaffScheduleService _service;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _activeContextMissing = false;
  String? _errorMessage;
  String? _successMessage;
  String? _resolvedRole;
  String? _establishmentName;

  List<StaffScheduleItemModel> _staffList = [];
  String? _selectedMembershipId;
  StaffScheduleItemModel? _selectedStaffItem;

  // Form State for editing
  WeeklyScheduleModel _editableWeeklySchedule = WeeklyScheduleModel.empty;
  bool _outOfOperatingHoursWarning = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? StaffScheduleService();
    _resolvedRole = widget.initialRole;
    _establishmentName = widget.initialEstablishmentName;
    _checkContextAndLoad();
  }

  String get _currentRole => (_resolvedRole ?? widget.initialRole ?? 'PROFESSIONAL').toUpperCase();
  String? get _currentMembershipId => ActiveContextHolder().activeMembershipId ?? widget.initialMembershipId;

  bool get _isOwnerOrManager => _currentRole == 'OWNER' || _currentRole == 'MANAGER';
  bool get _isProfessional => _currentRole == 'PROFESSIONAL';
  bool get _isReceptionist => _currentRole == 'RECEPTIONIST';

  bool get _canEdit => _isOwnerOrManager || _isProfessional;
  bool get _canDelete => _isOwnerOrManager;

  void _checkContextAndLoad() {
    if (!ActiveContextHolder().hasActiveContext && widget.initialMembershipId == null && widget.initialRole == null) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
      });
      return;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _activeContextMissing = false;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final staff = await _service.listStaffSchedules();
      setState(() {
        _staffList = staff;
      });

      // Resolve role from staff list if matching activeMembershipId
      final activeMemId = _currentMembershipId;
      if (activeMemId != null && _staffList.isNotEmpty) {
        final match = _staffList.cast<StaffScheduleItemModel?>().firstWhere(
              (m) => m?.membershipId == activeMemId,
              orElse: () => null,
            );
        if (match != null && widget.initialRole == null) {
          _resolvedRole = match.role;
        }
      }

      // Determine initial selection
      String? targetId = widget.initialMembershipId;
      if (_isProfessional && activeMemId != null && activeMemId.isNotEmpty) {
        // Mode "Mi Horario" locked to current user's membership
        targetId = activeMemId;
      }

      if (targetId == null || targetId.isEmpty) {
        if (_staffList.isNotEmpty) {
          targetId = _staffList.first.membershipId;
        }
      }

      if (targetId != null && targetId.isNotEmpty) {
        await _selectStaffMember(targetId, notifyState: false);
      } else {
        _editableWeeklySchedule = WeeklyScheduleModel.empty;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e is StaffScheduleException ? e.message : e.toString();
      });
    }
  }

  Future<void> _selectStaffMember(String membershipId, {bool notifyState = true}) async {
    _selectedMembershipId = membershipId;
    _selectedStaffItem = _staffList.firstWhere(
      (s) => s.membershipId == membershipId,
      orElse: () => StaffScheduleItemModel(
        membershipId: membershipId,
        userName: 'Colaborador',
        role: 'PROFESSIONAL',
        scheduleState: 'NOT_CONFIGURED',
        weeklySchedule: WeeklyScheduleModel.empty,
      ),
    );

    try {
      final detail = await _service.getStaffSchedule(membershipId);
      _editableWeeklySchedule = detail.weeklySchedule;
      _outOfOperatingHoursWarning = detail.outOfOperatingHoursWarning;
    } catch (e) {
      // Fallback to item from list if detail fetch fails
      _editableWeeklySchedule = _selectedStaffItem?.weeklySchedule ?? WeeklyScheduleModel.empty;
      _outOfOperatingHoursWarning = false;
    }

    if (notifyState && mounted) {
      setState(() {});
    }
  }

  void _handleDayToggle(String dayKey, bool value) {
    if (!_canEdit) return;
    setState(() {
      final currentDay = _editableWeeklySchedule.getDay(dayKey);
      List<TimeBlockModel> blocks = List.from(currentDay.timeBlocks);
      if (value && blocks.isEmpty) {
        blocks.add(const TimeBlockModel(startTime: '09:00', endTime: '18:00'));
      }
      final updatedDay = DayScheduleModel(isWorking: value, timeBlocks: blocks);
      _editableWeeklySchedule = _editableWeeklySchedule.copyWithDay(dayKey, updatedDay);
    });
  }

  void _handleAddBlock(String dayKey) {
    if (!_canEdit) return;
    setState(() {
      final currentDay = _editableWeeklySchedule.getDay(dayKey);
      final blocks = List<TimeBlockModel>.from(currentDay.timeBlocks);
      blocks.add(const TimeBlockModel(startTime: '09:00', endTime: '18:00'));
      final updatedDay = DayScheduleModel(isWorking: true, timeBlocks: blocks);
      _editableWeeklySchedule = _editableWeeklySchedule.copyWithDay(dayKey, updatedDay);
    });
  }

  void _handleRemoveBlock(String dayKey, int index) {
    if (!_canEdit) return;
    setState(() {
      final currentDay = _editableWeeklySchedule.getDay(dayKey);
      final blocks = List<TimeBlockModel>.from(currentDay.timeBlocks);
      if (index >= 0 && index < blocks.length) {
        blocks.removeAt(index);
      }
      final updatedDay = DayScheduleModel(
        isWorking: blocks.isNotEmpty ? currentDay.isWorking : false,
        timeBlocks: blocks,
      );
      _editableWeeklySchedule = _editableWeeklySchedule.copyWithDay(dayKey, updatedDay);
    });
  }

  void _handleTimeChange(String dayKey, int index, String newStart, String newEnd) {
    if (!_canEdit) return;
    setState(() {
      final currentDay = _editableWeeklySchedule.getDay(dayKey);
      final blocks = List<TimeBlockModel>.from(currentDay.timeBlocks);
      if (index >= 0 && index < blocks.length) {
        blocks[index] = TimeBlockModel(startTime: newStart, endTime: newEnd);
      }
      final updatedDay = DayScheduleModel(isWorking: currentDay.isWorking, timeBlocks: blocks);
      _editableWeeklySchedule = _editableWeeklySchedule.copyWithDay(dayKey, updatedDay);
    });
  }

  String? _validateScheduleBeforeSave() {
    for (final dayKey in kCanonicalWeekdays) {
      final day = _editableWeeklySchedule.getDay(dayKey);
      if (!day.isWorking) continue;

      if (day.timeBlocks.isEmpty) {
        return 'El día ${kWeekdayLabels[dayKey]} está activo pero no tiene bloques horarios configurados.';
      }

      final parsed = <Map<String, dynamic>>[];
      for (final block in day.timeBlocks) {
        if (!isValidTimeFormat(block.startTime) || !isValidTimeFormat(block.endTime)) {
          return 'Formato de hora inválido en ${kWeekdayLabels[dayKey]}. Use HH:mm.';
        }
        final sMin = timeToMinutes(block.startTime);
        final eMin = timeToMinutes(block.endTime);
        if (sMin >= eMin) {
          return 'En ${kWeekdayLabels[dayKey]}, la hora de inicio (${block.startTime}) debe ser menor a la de fin (${block.endTime}).';
        }
        parsed.add({'s': sMin, 'e': eMin, 'block': block});
      }

      parsed.sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
      for (int i = 0; i < parsed.length - 1; i++) {
        final cur = parsed[i];
        final next = parsed[i + 1];
        if ((next['s'] as int) < (cur['e'] as int)) {
          return 'Solapamiento de bloques detectado en ${kWeekdayLabels[dayKey]}.';
        }
      }
    }
    return null;
  }

  Future<void> _saveSchedule() async {
    if (!_canEdit) return;
    if (_selectedMembershipId == null || _selectedMembershipId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ningún colaborador seleccionado.')),
      );
      return;
    }

    final validationError = _validateScheduleBeforeSave();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final updated = await _service.setStaffSchedule(
        _selectedMembershipId!,
        _editableWeeklySchedule,
      );

      setState(() {
        _isSaving = false;
        _editableWeeklySchedule = updated.weeklySchedule;
        _outOfOperatingHoursWarning = updated.outOfOperatingHoursWarning;
        _successMessage = 'Horario actualizado exitosamente.';
      });

      // Update in staff list
      final idx = _staffList.indexWhere((s) => s.membershipId == _selectedMembershipId);
      if (idx != -1) {
        _staffList[idx] = StaffScheduleItemModel(
          membershipId: _staffList[idx].membershipId,
          userId: _staffList[idx].userId,
          userName: _staffList[idx].userName,
          userEmail: _staffList[idx].userEmail,
          role: _staffList[idx].role,
          status: _staffList[idx].status,
          scheduleState: updated.scheduleState,
          weeklySchedule: updated.weeklySchedule,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is StaffScheduleException ? e.message : e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteSchedule() async {
    if (!_canDelete || _selectedMembershipId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('dialog_confirm_delete_schedule'),
        title: const Text('¿Resetear Horario?'),
        content: Text(
          'Esta acción reseteará a vacío el horario operativo semanal de ${_selectedStaffItem?.userName ?? "este colaborador"}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_delete_schedule'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resetear Horario', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _service.deleteStaffSchedule(_selectedMembershipId!);

      setState(() {
        _isSaving = false;
        _editableWeeklySchedule = WeeklyScheduleModel.empty;
        _outOfOperatingHoursWarning = false;
        _successMessage = 'Horario reseteado correctamente.';
      });

      final idx = _staffList.indexWhere((s) => s.membershipId == _selectedMembershipId);
      if (idx != -1) {
        _staffList[idx] = StaffScheduleItemModel(
          membershipId: _staffList[idx].membershipId,
          userId: _staffList[idx].userId,
          userName: _staffList[idx].userName,
          userEmail: _staffList[idx].userEmail,
          role: _staffList[idx].role,
          status: _staffList[idx].status,
          scheduleState: 'NOT_CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.blueGrey.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e is StaffScheduleException ? e.message : e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
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
        title: const Text('Horarios del Personal (N03A)'),
        leading: IconButton(
          key: const Key('btn_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            key: const Key('btn_refresh_schedules'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading || _isSaving ? null : _loadInitialData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_activeContextMissing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Sin Sede Activa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Debe seleccionar una sede activa para gestionar o consultar los horarios del personal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('btn_select_context'),
                onPressed: widget.onNavigateToContextSelector ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Seleccionar Sede'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('loading_indicator')),
      );
    }

    if (_errorMessage != null && _staffList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('btn_retry_schedules'),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: _loadInitialData,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        if (_outOfOperatingHoursWarning) _buildWarningBanner(),
        if (_isOwnerOrManager || _isReceptionist) _buildStaffSelector(),
        Expanded(
          child: _selectedMembershipId == null
              ? const Center(child: Text('Seleccione un colaborador para ver su horario.'))
              : _buildWeeklyEditor(),
        ),
        if (_canEdit || _canDelete) _buildActionFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    final estName = _establishmentName ?? 'Establecimiento';
    String modeLabel = 'Administrador';
    Color modeColor = Colors.indigo;

    if (_isProfessional) {
      modeLabel = 'Mi Horario';
      modeColor = Colors.teal;
    } else if (_isReceptionist) {
      modeLabel = 'Solo Lectura';
      modeColor = Colors.grey.shade700;
    }

    return Container(
      key: const Key('staff_schedule_header'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rol: $_currentRole',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              modeLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            backgroundColor: modeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      key: const Key('warning_operating_hours_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aviso: Uno o más bloques horarios están fuera del horario operativo general del establecimiento.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Text('Colaborador: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('select_staff_dropdown'),
                isExpanded: true,
                value: _selectedMembershipId,
                items: _staffList.map((item) {
                  final stateBadge = item.isConfigured ? '🟢 Configurado' : '⚪ Sin Horario';
                  return DropdownMenuItem<String>(
                    value: item.membershipId,
                    child: Text('${item.userName} (${item.role}) - $stateBadge'),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != _selectedMembershipId) {
                    _selectStaffMember(newId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEditor() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: kCanonicalWeekdays.map((dayKey) => _buildDayCard(dayKey)).toList(),
    );
  }

  Widget _buildDayCard(String dayKey) {
    final dayLabel = kWeekdayLabels[dayKey] ?? dayKey;
    final dayData = _editableWeeklySchedule.getDay(dayKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: dayData.isWorking ? Colors.indigo.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: dayData.isWorking ? Colors.indigo.shade900 : Colors.grey.shade700,
                    ),
                  ),
                ),
                Switch(
                  key: Key('switch_day_$dayKey'),
                  value: dayData.isWorking,
                  onChanged: _canEdit ? (val) => _handleDayToggle(dayKey, val) : null,
                ),
              ],
            ),
            if (!dayData.isWorking)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No laborable / Descanso',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
              ),
            if (dayData.isWorking) ...[
              const Divider(),
              ...List.generate(dayData.timeBlocks.length, (idx) {
                final block = dayData.timeBlocks[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.indigo),
                      const SizedBox(width: 8),
                      // Start time field
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          key: Key('input_start_${dayKey}_$idx'),
                          initialValue: block.startTime,
                          enabled: _canEdit,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Inicio',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            _handleTimeChange(dayKey, idx, val, block.endTime);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('-'),
                      ),
                      // End time field
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          key: Key('input_end_${dayKey}_$idx'),
                          initialValue: block.endTime,
                          enabled: _canEdit,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Fin',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            _handleTimeChange(dayKey, idx, block.startTime, val);
                          },
                        ),
                      ),
                      const Spacer(),
                      if (_canEdit)
                        IconButton(
                          key: Key('btn_remove_block_${dayKey}_$idx'),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _handleRemoveBlock(dayKey, idx),
                        ),
                    ],
                  ),
                );
              }),
              if (_canEdit)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: Key('btn_add_block_$dayKey'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar Bloque'),
                    onPressed: () => _handleAddBlock(dayKey),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_canDelete)
            OutlinedButton.icon(
              key: const Key('btn_delete_schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Resetear'),
              onPressed: _isSaving ? null : _confirmAndDeleteSchedule,
            ),
          const Spacer(),
          if (_canEdit)
            ElevatedButton.icon(
              key: const Key('btn_save_schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar Horario',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: _isSaving ? null : _saveSchedule,
            ),
        ],
      ),
    );
  }
}
