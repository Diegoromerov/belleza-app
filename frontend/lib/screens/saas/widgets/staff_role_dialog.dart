// frontend/lib/screens/saas/widgets/staff_role_dialog.dart
// GO-08.41 / GO-08.43: SCR-14-M2 Staff Role Modification Dialog

import 'package:flutter/material.dart';
import '../../../models/saas_staff_model.dart';
import '../../../services/saas_staff_service.dart';

/// Dialog for changing a staff member's contextual role (SCR-14-M2).
class StaffRoleDialog extends StatefulWidget {
  final StaffMember member;
  final SaasStaffService service;
  final String actorRole; // OWNER | MANAGER
  final int currentUserId;
  final void Function(StaffMember updatedMember) onRoleUpdated;

  const StaffRoleDialog({
    super.key,
    required this.member,
    required this.service,
    required this.actorRole,
    required this.currentUserId,
    required this.onRoleUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffMember member,
    required SaasStaffService service,
    required String actorRole,
    required int currentUserId,
    required void Function(StaffMember updatedMember) onRoleUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StaffRoleDialog(
        member: member,
        service: service,
        actorRole: actorRole,
        currentUserId: currentUserId,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }

  @override
  State<StaffRoleDialog> createState() => _StaffRoleDialogState();
}

class _StaffRoleDialogState extends State<StaffRoleDialog> {
  late String _selectedRole;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isSelfMutation => widget.member.userId == widget.currentUserId;
  bool get _isOwner => widget.actorRole == 'OWNER';
  bool get _isManager => widget.actorRole == 'MANAGER';

  List<String> get _availableRoles {
    if (_isOwner) {
      return const ['PROFESSIONAL', 'RECEPTIONIST', 'MANAGER', 'OWNER'];
    }
    if (_isManager) {
      // Manager can only toggle between operative roles
      return const ['PROFESSIONAL', 'RECEPTIONIST'];
    }
    return [widget.member.role];
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    if (!_availableRoles.contains(_selectedRole)) {
      _selectedRole = _availableRoles.first;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'OWNER':
        return 'Propietario (Owner)';
      case 'MANAGER':
        return 'Administrador (Manager)';
      case 'PROFESSIONAL':
        return 'Profesional / Estilista';
      case 'RECEPTIONIST':
        return 'Recepcionista';
      default:
        return role;
    }
  }

  Future<void> _submit() async {
    if (_isSelfMutation) return;
    if (_selectedRole == widget.member.role) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.service.updateStaffRole(
        widget.member.membershipId,
        _selectedRole,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRoleUpdated(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol de ${widget.member.userName} actualizado a ${_formatRole(_selectedRole)}.'),
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Modificar Rol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

            // Tarjeta de información del colaborador
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
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      widget.member.userName.isNotEmpty ? widget.member.userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
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
                          '${widget.member.userEmail} • Rol actual: ${_formatRole(widget.member.role)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Invariante de auto-mutación
            if (_isSelfMutation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Por motivos de gobernanza y seguridad, no puedes modificar tu propio rol dentro de la sede.',
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const Text(
                'Selecciona el nuevo rol para este colaborador:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: const Key('dropdown_staff_new_role'),
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Rol',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_formatRole(role), style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_role_change'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!_isSelfMutation)
          ElevatedButton(
            key: const Key('btn_confirm_role_change'),
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
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
