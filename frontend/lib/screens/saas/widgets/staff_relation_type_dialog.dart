// frontend/lib/screens/saas/widgets/staff_relation_type_dialog.dart
// GO-08.41 / GO-08.43: SCR-14-M4 Staff Relation Type Modification Dialog

import 'package:flutter/material.dart';
import '../../../models/saas_staff_model.dart';
import '../../../services/saas_staff_service.dart';

/// Dialog for changing a staff member's contractual relation type (SCR-14-M4).
/// Strictly restricted to actors with OWNER role.
class StaffRelationTypeDialog extends StatefulWidget {
  final StaffMember member;
  final SaasStaffService service;
  final void Function(StaffMember updatedMember) onRelationTypeUpdated;

  const StaffRelationTypeDialog({
    super.key,
    required this.member,
    required this.service,
    required this.onRelationTypeUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffMember member,
    required SaasStaffService service,
    required void Function(StaffMember updatedMember) onRelationTypeUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StaffRelationTypeDialog(
        member: member,
        service: service,
        onRelationTypeUpdated: onRelationTypeUpdated,
      ),
    );
  }

  @override
  State<StaffRelationTypeDialog> createState() => _StaffRelationTypeDialogState();
}

class _StaffRelationTypeDialogState extends State<StaffRelationTypeDialog> {
  late String _selectedRelationType;
  bool _isSaving = false;
  String? _errorMessage;

  static const _relationOptions = [
    'STAFF_EMPLOYEE',
    'INDEPENDENT_PROVIDER',
    'OWNER_PARTNER',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRelationType = widget.member.relationType;
    if (!_relationOptions.contains(_selectedRelationType)) {
      _selectedRelationType = _relationOptions.first;
    }
  }

  String _formatRelationLabel(String relation) {
    switch (relation) {
      case 'STAFF_EMPLOYEE':
        return 'Empleado / Nómina Directa';
      case 'INDEPENDENT_PROVIDER':
        return 'Prestador Independiente / Porcentual';
      case 'OWNER_PARTNER':
        return 'Socio Propietario / Partner';
      default:
        return relation;
    }
  }

  String _getRelationDescription(String relation) {
    switch (relation) {
      case 'STAFF_EMPLOYEE':
        return 'Vínculo laboral directo. El establecimiento liquida nómina o salario.';
      case 'INDEPENDENT_PROVIDER':
        return 'Prestación de servicios por comisión/porcentaje por servicio ejecutado.';
      case 'OWNER_PARTNER':
        return 'Participación societaria o co-propiedad del establecimiento.';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (_selectedRelationType == widget.member.relationType) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.service.updateStaffRelationType(
        widget.member.membershipId,
        _selectedRelationType,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRelationTypeUpdated(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tipo de relación de ${widget.member.userName} actualizado.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_outlined, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Relación Contractual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Colaborador info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      widget.member.userName.isNotEmpty ? widget.member.userName[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${widget.member.userEmail} • Relación actual: ${_formatRelationLabel(widget.member.relationType)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Selecciona el nuevo tipo de relación comercial:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              key: const Key('dropdown_staff_new_relation_type'),
              value: _selectedRelationType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Relación',
                prefixIcon: Icon(Icons.business_center_outlined),
                border: OutlineInputBorder(),
              ),
              items: _relationOptions.map((rel) {
                return DropdownMenuItem(
                  value: rel,
                  child: Text(_formatRelationLabel(rel), style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRelationType = val);
              },
            ),
            const SizedBox(height: 10),
            Text(
              _getRelationDescription(_selectedRelationType),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_relation_change'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_relation_change'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}
