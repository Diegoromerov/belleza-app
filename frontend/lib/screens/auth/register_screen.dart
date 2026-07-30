// frontend/lib/screens/auth/register_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _selectedRole = 'CLIENTE'; // 'CLIENTE' or 'PRESTADOR'
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final phone = _phoneCtrl.text.trim();

      final success = await AuthService.register(
        name,
        email,
        password,
        phone.isNotEmpty ? phone : null,
        _selectedRole,
      );

      if (success && mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        // Iniciar sesión automáticamente para emular el flujo de OAuth
        final loginResult = await AuthService.login(email, password);
        if (!mounted) return;

        if (loginResult != null) {
          final bool onboardingCompleto =
              loginResult['user']['onboarding_completo'] ?? false;
          final String? role = loginResult['user']['role'];

          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                '✅ Registro exitoso como ${_selectedRole == 'PRESTADOR' ? 'Prestador' : 'Cliente'}.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));

          if (onboardingCompleto) {
            if (role == 'provider') {
              navigator.pushNamedAndRemoveUntil('/provider', (route) => false);
            } else {
              navigator.pushNamedAndRemoveUntil('/home', (route) => false);
            }
          } else {
            navigator.pushNamedAndRemoveUntil('/onboarding', (route) => false);
          }
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('✅ Cuenta creada. Inicie sesión para continuar.'),
            backgroundColor: Colors.green,
          ));
          navigator.pop();
        }
      } else {
        setState(() => _error =
            'Error al registrar. El correo electrónico podría estar en uso.');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // LuxeColors.nude50
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de Volver
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F1A15), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Encabezado
                Hero(
                  tag: 'logo',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EFEA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC5A052), width: 1),
                    ),
                    child: const Icon(Icons.face_retouching_natural,
                        size: 40, color: Color(0xFFC5A052)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'REGISTRO CONCIERGE',
                  style: TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1A15),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Únete a la comunidad de alta belleza y salud',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E8C78),
                    fontFamily: 'CormorantGaramond',
                  ),
                ),
                const SizedBox(height: 24),

                // Tarjeta Luxe
                Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFEA), // LuxeColors.nude100
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8E0D5), // LuxeColors.nude200
                      width: 1.0,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'TIPO DE USUARIO',
                          style: TextStyle(
                            fontFamily: 'Didot',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1A15),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Selector de Rol Luxe
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E0D5),
                            borderRadius: BorderRadius.circular(10.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'CLIENTE'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'CLIENTE'
                                          ? const Color(0xFFFAF8F5)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cliente',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedRole == 'CLIENTE'
                                              ? const Color(0xFF1F1A15)
                                              : const Color(0xFF9E8C78),
                                          fontSize: 13,
                                          fontFamily: 'CormorantGaramond',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'PRESTADOR'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'PRESTADOR'
                                          ? const Color(0xFFFAF8F5)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Prestador / Pro',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedRole == 'PRESTADOR'
                                              ? const Color(0xFF1F1A15)
                                              : const Color(0xFF9E8C78),
                                          fontSize: 13,
                                          fontFamily: 'CormorantGaramond',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Caja informativa de rol
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(10.5),
                            border: Border.all(color: const Color(0xFFE8E0D5), width: 0.5),
                          ),
                          child: Text(
                            _selectedRole == 'CLIENTE'
                                ? '✨ Acceso a diagnósticos de IA Aura, GlowStore y reserva de servicios concierge.'
                                : '💼 Ofrece tus servicios, gestiona tu agenda y recibe pagos con comisión preferencial.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B5A48),
                              fontFamily: 'CormorantGaramond',
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputDecoration('Nombre completo', Icons.person_outline),
                          validator: (v) => v!.isEmpty ? 'Ingresa tu nombre completo' : null,
                          style: const TextStyle(fontSize: 14, fontFamily: 'CormorantGaramond'),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                          validator: (v) => v!.isEmpty ? 'Ingresa tu correo' : null,
                          style: const TextStyle(fontSize: 14, fontFamily: 'CormorantGaramond'),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(
                            'Contraseña',
                            Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFFC5A052),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                          style: const TextStyle(fontSize: 14, fontFamily: 'CormorantGaramond'),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Teléfono (opcional)', Icons.phone_outlined),
                          style: const TextStyle(fontSize: 14, fontFamily: 'CormorantGaramond'),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFFB00020),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5A052),
                            foregroundColor: const Color(0xFF1F1A15),
                            disabledBackgroundColor: const Color(0xFFE8E0D5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.5)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF1F1A15),
                                      strokeWidth: 2.5),
                                )
                              : const Text(
                                  'CREAR MI CUENTA',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9E8C78), fontSize: 14, fontFamily: 'CormorantGaramond'),
      prefixIcon: Icon(icon, color: const Color(0xFFC5A052), size: 20),
      suffixIcon: suffixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: const Color(0xFFFAF8F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.5),
        borderSide: const BorderSide(color: Color(0xFFE8E0D5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.5),
        borderSide: const BorderSide(color: Color(0xFFE8E0D5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.5),
        borderSide: const BorderSide(color: Color(0xFFC5A052), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
