// frontend/lib/screens/saas/widgets/staff_invite_modal.dart
// GO-08.41 / GO-08.43: SCR-14-M1 Staff Invitation Emission Modal

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/saas_staff_model.dart';
import '../../../services/saas_staff_service.dart';

/// Modal dialog for issuing asynchronous staff invitations (SCR-14-M1).
class StaffInviteModal extends StatefulWidget {
  final SaasStaffService service;
  final String actorRole; // OWNER | MANAGER
  final void Function(StaffInvitationEmissionResponse emission) onInvitationEmitted;

  const StaffInviteModal({
    super.key,
    required this.service,
    required this.actorRole,
    required this.onInvitationEmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required SaasStaffService service,
    required String actorRole,
    required void Function(StaffInvitationEmissionResponse emission) onInvitationEmitted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StaffInviteModal(
        service: service,
        actorRole: actorRole,
        onInvitationEmitted: onInvitationEmitted,
      ),
    );
  }

  @override
  State<StaffInviteModal> createState() => _StaffInviteModalState();
}

class _StaffInviteModalState extends State<StaffInviteModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late String _selectedRole;
  late String _selectedRelationType;

  bool _isEmitting = false;
  String? _errorMessage;
  StaffInvitationEmissionResponse? _emittedResult;

  bool get _isOwner => widget.actorRole == 'OWNER';

  List<String> get _availableRoles {
    if (_isOwner) {
      return const ['PROFESSIONAL', 'RECEPTIONIST', 'MANAGER', 'OWNER'];
    }
    // Manager is strictly restricted to operative roles
    return const ['PROFESSIONAL', 'RECEPTIONIST'];
  }

  List<String> get _availableRelationTypes {
    if (_isOwner) {
      return const ['STAFF_EMPLOYEE', 'INDEPENDENT_PROVIDER', 'OWNER_PARTNER'];
    }
    return const ['STAFF_EMPLOYEE'];
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = _availableRoles.first;
    _selectedRelationType = _availableRelationTypes.first;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _formatRoleLabel(String role) {
    switch (role) {
      case 'OWNER':
        return 'Propietario / Co-Owner (Control Total)';
      case 'MANAGER':
        return 'Administrador / Manager';
      case 'PROFESSIONAL':
        return 'Profesional / Estilista';
      case 'RECEPTIONIST':
        return 'Recepcionista';
      default:
        return role;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.service.createInvitation(
        email: _emailController.text,
        role: _selectedRole,
        relationType: _selectedRelationType,
      );

      if (mounted) {
        setState(() {
          _isEmitting = false;
          _emittedResult = result;
        });
        widget.onInvitationEmitted(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEmitting = false;
          _errorMessage = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emittedResult != null) {
      return _buildSuccessView();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Invitar Colaborador',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                const Text(
                  'El colaborador recibirá una invitación asíncrona válida por 7 días.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Correo Electrónico
                TextFormField(
                  key: const Key('input_invite_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico *',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo es obligatorio.';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Ingresa un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rol Contextual
                DropdownButtonFormField<String>(
                  key: const Key('dropdown_invite_role'),
                  value: _selectedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Rol Contextual en la Sede *',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _availableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        _formatRoleLabel(role),
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),

                // Tipo de Relación (Solo editable por OWNER)
                if (_isOwner)
                  DropdownButtonFormField<String>(
                    key: const Key('dropdown_invite_relation_type'),
                    value: _selectedRelationType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Relación Contractual *',
                      prefixIcon: Icon(Icons.handshake_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _availableRelationTypes.map((rel) {
                      return DropdownMenuItem(
                        value: rel,
                        child: Text(
                          _formatRelationLabel(rel),
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRelationType = val);
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Relación contractual predeterminada: ${_formatRelationLabel(_selectedRelationType)} (Solo el Propietario puede alterarla).',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_invite'),
          onPressed: _isEmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          key: const Key('btn_submit_invite'),
          onPressed: _isEmitting ? null : _submit,
          icon: _isEmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: const Text('Emitir Invitación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final emission = _emittedResult!;
    final token = emission.rawToken;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 10),
          Text('¡Invitación Emitida!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se emitió la invitación para ${emission.invitation.email} con el rol ${_formatRoleLabel(emission.invitation.role)}.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enlace de Incorporación Directo:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    emission.invitationUrl ?? 'https://app.glowapp.com/saas/invitations/accept?token=$token',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Válida por 7 días. Puedes reenviarla o cancelarla en cualquier momento desde la pestaña "Invitaciones Pendientes".',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          key: const Key('btn_copy_invite_token'),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copiar Enlace'),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: emission.invitationUrl ?? 'https://app.glowapp.com/saas/invitations/accept?token=$token',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enlace de invitación copiado al portapapeles.')),
            );
          },
        ),
        ElevatedButton(
          key: const Key('btn_close_invite_success'),
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
