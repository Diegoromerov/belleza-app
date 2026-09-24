// frontend/lib/screens/saas/widgets/staff_status_dialog.dart
// GO-08.41 / GO-08.43: SCR-14-M3 Staff Status Modification Dialog

import 'package:flutter/material.dart';
import '../../../models/saas_staff_model.dart';
import '../../../services/saas_staff_service.dart';

/// Dialog for suspending, reactivating, or revoking a staff membership (SCR-14-M3).
class StaffStatusDialog extends StatefulWidget {
  final StaffMember member;
  final SaasStaffService service;
  final String actorRole; // OWNER | MANAGER
  final int currentUserId;
  final void Function(StaffMember updatedMember) onStatusUpdated;

  const StaffStatusDialog({
    super.key,
    required this.member,
    required this.service,
    required this.actorRole,
    required this.currentUserId,
    required this.onStatusUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffMember member,
    required SaasStaffService service,
    required String actorRole,
    required int currentUserId,
    required void Function(StaffMember updatedMember) onStatusUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => StaffStatusDialog(
        member: member,
        service: service,
        actorRole: actorRole,
        currentUserId: currentUserId,
        onStatusUpdated: onStatusUpdated,
      ),
    );
  }

  @override
  State<StaffStatusDialog> createState() => _StaffStatusDialogState();
}

class _StaffStatusDialogState extends State<StaffStatusDialog> {
  late String _targetAction; // 'SUSPEND' | 'REACTIVATE' | 'REVOKE'
  final _confirmRevokeController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isSelfMutation => widget.member.userId == widget.currentUserId;
  bool get _isOwner => widget.actorRole == 'OWNER';

  @override
  void initState() {
    super.initState();
    if (widget.member.status == 'ACTIVE') {
      _targetAction = 'SUSPEND';
    } else if (widget.member.status == 'SUSPENDED') {
      _targetAction = 'REACTIVATE';
    } else {
      _targetAction = 'REVOKE';
    }
  }

  @override
  void dispose() {
    _confirmRevokeController.dispose();
    super.dispose();
  }

  String get _newStatusTarget {
    switch (_targetAction) {
      case 'SUSPEND':
        return 'SUSPENDED';
      case 'REACTIVATE':
        return 'ACTIVE';
      case 'REVOKE':
        return 'REVOKED';
      default:
        return 'ACTIVE';
    }
  }

  Future<void> _submit() async {
    if (_isSelfMutation) return;

    if (_targetAction == 'REVOKE') {
      if (_confirmRevokeController.text.trim() != 'CONFIRMAR') {
        setState(() {
          _errorMessage = 'Debes escribir exactamente "CONFIRMAR" para revocar la membresía.';
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.service.updateStaffStatus(
        widget.member.membershipId,
        _newStatusTarget,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onStatusUpdated(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado de ${widget.member.userName} modificado a $_newStatusTarget.'),
            backgroundColor: _targetAction == 'REVOKE' ? Colors.red.shade700 : Colors.green.shade700,
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
              color: _targetAction == 'REVOKE'
                  ? Colors.red.shade50
                  : (_targetAction == 'SUSPEND' ? Colors.amber.shade50 : Colors.green.shade50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _targetAction == 'REVOKE'
                  ? Icons.person_remove_outlined
                  : (_targetAction == 'SUSPEND' ? Icons.pause_circle_outline : Icons.play_circle_outline),
              color: _targetAction == 'REVOKE'
                  ? Colors.red
                  : (_targetAction == 'SUSPEND' ? Colors.amber.shade800 : Colors.green),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Gestionar Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
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

              // Información del colaborador
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
                            '${widget.member.userEmail} • Estado actual: ${widget.member.status}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                          'No puedes suspender ni revocar tu propia membresía en la sede.',
                          style: TextStyle(fontSize: 12, color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.member.isRevoked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.grey, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta membresía fue revocada definitivamente. Para reintegrar al colaborador, emite una nueva invitación.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Selector de Acción
                const Text('Acción a realizar:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    if (widget.member.status == 'ACTIVE')
                      const ButtonSegment(value: 'SUSPEND', label: Text('Suspender'), icon: Icon(Icons.pause)),
                    if (widget.member.status == 'SUSPENDED')
                      const ButtonSegment(value: 'REACTIVATE', label: Text('Reactivar'), icon: Icon(Icons.play_arrow)),
                    if (_isOwner)
                      const ButtonSegment(value: 'REVOKE', label: Text('Revocar'), icon: Icon(Icons.delete_forever)),
                  ],
                  selected: {_targetAction},
                  onSelectionChanged: (set) {
                    setState(() {
                      _targetAction = set.first;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Explicación de la acción
                if (_targetAction == 'SUSPEND')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Efectos de la Suspensión:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• El colaborador perderá acceso a esta sede inmediatamente.\n'
                          '• Proyectará 0 turnos en la agenda para nuevas citas.\n'
                          '• Las citas y tickets históricos se retienen íntegramente.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                if (_targetAction == 'REACTIVATE')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text(
                      'El colaborador recuperará el acceso a la sede y volverá a proyectar disponibilidad conforme a sus horarios configurados.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),

                if (_targetAction == 'REVOKE') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ ADVERTENCIA: ACCIÓN IRREVERSIBLE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'La revocación cancela permanentemente la membresía del colaborador en esta sede. Toda la historia de tickets y citas pasadas se conservará por integridad fiscal y operativa.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para confirmar, escribe "CONFIRMAR" a continuación:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('input_confirm_revoke'),
                    controller: _confirmRevokeController,
                    decoration: const InputDecoration(
                      hintText: 'CONFIRMAR',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_status_dialog'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!_isSelfMutation && !widget.member.isRevoked)
          ElevatedButton(
            key: const Key('btn_confirm_status_change'),
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _targetAction == 'REVOKE'
                  ? Colors.red
                  : (_targetAction == 'SUSPEND' ? Colors.amber.shade800 : Colors.green.shade700),
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _targetAction == 'REVOKE'
                        ? 'Revocar Membresía'
                        : (_targetAction == 'SUSPEND' ? 'Suspender Acceso' : 'Reactivar Colaborador'),
                  ),
          ),
      ],
    );
  }
}
