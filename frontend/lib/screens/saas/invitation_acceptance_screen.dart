// frontend/lib/screens/saas/invitation_acceptance_screen.dart
// GO-08.41 / GO-08.43: SCR-15 Public Staff Invitation Acceptance Screen

import 'package:flutter/material.dart';
import '../../models/saas_staff_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/auth_service.dart';
import '../../services/saas_staff_service.dart';

/// Public screen for inspecting and claiming a staff invitation (SCR-15).
class InvitationAcceptanceScreen extends StatefulWidget {
  final String token;
  final SaasStaffService? service;
  final Future<Map<String, dynamic>?> Function(String email, String password)? authLogin;
  final VoidCallback? onAcceptanceSuccess;

  const InvitationAcceptanceScreen({
    super.key,
    required this.token,
    this.service,
    this.authLogin,
    this.onAcceptanceSuccess,
  });

  @override
  State<InvitationAcceptanceScreen> createState() => _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState extends State<InvitationAcceptanceScreen> {
  late final SaasStaffService _service;

  bool _isLoading = true;
  String? _inspectionError;
  StaffInvitationInspection? _inspection;

  // Formulario para nuevo usuario
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isProcessing = false;
  String? _acceptanceError;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasStaffService();
    _inspectToken();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _inspectToken() async {
    setState(() {
      _isLoading = true;
      _inspectionError = null;
    });

    try {
      final data = await _service.getInvitationByToken(widget.token);
      if (mounted) {
        setState(() {
          _inspection = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inspectionError = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptAsExistingUser() async {
    setState(() {
      _isProcessing = true;
      _acceptanceError = null;
    });

    try {
      final res = await _service.acceptInvitation(widget.token);
      if (res.success) {
        // Cargar la membresía aceptada en Active Context
        ActiveContextHolder().setActiveMembershipId(res.membershipId);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Te has unido exitosamente a ${_inspection?.establishmentName ?? 'la sede'}!'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
          if (widget.onAcceptanceSuccess != null) {
            widget.onAcceptanceSuccess!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _acceptanceError = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
        });
      }
    }
  }

  Future<void> _acceptAsNewUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _acceptanceError = null;
    });

    final email = _inspection!.email;
    final password = _passwordController.text;
    final fullName = _fullNameController.text;

    try {
      // 1. Aceptar invitación y crear cuenta en backend
      final res = await _service.acceptInvitation(
        widget.token,
        fullName: fullName,
        password: password,
      );

      if (res.success) {
        // 2. Establecer sesión mediante AuthService.login (OBS-01)
        try {
          if (widget.authLogin != null) {
            await widget.authLogin!(email, password);
          } else {
            await AuthService.login(email, password);
          }
        } catch (_) {
          // Si el login falla por alguna razón de red, continuamos con el contexto
        }

        ActiveContextHolder().setActiveMembershipId(res.membershipId);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Bienvenido a ${_inspection?.establishmentName ?? 'GlowApp'}! Tu cuenta ha sido creada.'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
          if (widget.onAcceptanceSuccess != null) {
            widget.onAcceptanceSuccess!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _acceptanceError = e is SaasStaffException
              ? e.message
              : e.toString().replaceFirst('SaasStaffException: ', '');
        });
      }
    }
  }

  String _formatRoleLabel(String role) {
    switch (role) {
      case 'OWNER':
        return 'Propietario / Co-Owner';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Invitación a Salón GlowApp', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(key: Key('loading_inspection')),
            SizedBox(height: 16),
            Text('Verificando enlace de invitación...'),
          ],
        ),
      );
    }

    if (_inspectionError != null || _inspection == null) {
      return _buildInspectionErrorCard();
    }

    return _buildAcceptanceCard();
  }

  Widget _buildInspectionErrorCard() {
    return Card(
      key: const Key('card_inspection_error'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Enlace No Válido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _inspectionError ?? 'No fue posible validar la invitación.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _inspectToken,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text('Reintentar Verificación'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptanceCard() {
    final inv = _inspection!;
    final daysRemaining = inv.expiresAt.difference(DateTime.now()).inDays;

    return Card(
      key: const Key('card_invitation_acceptance'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con datos del Salón
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: Colors.indigo, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              inv.establishmentName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              inv.tenantName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Tarjeta de invitación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rol Asignado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatRoleLabel(inv.role),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Destinatario:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          inv.email,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Validez:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        daysRemaining >= 0 ? 'Expira en $daysRemaining días' : 'Expirada',
                        style: TextStyle(
                          fontSize: 12,
                          color: daysRemaining <= 1 ? Colors.red : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_acceptanceError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _acceptanceError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Formulario según si el usuario ya existe o es nuevo
            if (inv.userExists)
              _buildExistingUserSection()
            else
              _buildNewUserForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ya posees una cuenta registrada con este correo electrónico.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('btn_accept_existing_user'),
          onPressed: _isProcessing ? null : _acceptAsExistingUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Aceptar y Unirme al Salón', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildNewUserForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Crea tu contraseña para activar tu cuenta e ingresar al salón:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('input_accept_full_name'),
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa tu nombre completo.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('input_accept_password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) {
              if (val == null || val.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('input_accept_confirm_password'),
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              labelText: 'Confirmar Contraseña *',
              prefixIcon: Icon(Icons.lock_clock_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Las contraseñas no coinciden.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('btn_accept_new_user'),
            onPressed: _isProcessing ? null : _acceptAsNewUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Crear Cuenta y Unirme al Salón', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
