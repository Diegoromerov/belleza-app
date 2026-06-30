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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF5F2),
              Color(0xFFE8D4CB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de Volver
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF8A7A77), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Encabezado
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F8A6B63),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            )
                          ]),
                      child: const Icon(Icons.face_retouching_natural,
                          size: 48, color: Color(0xFFC89D93)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4A3E3D),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Únete a nuestra comunidad de belleza',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A7A77),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjeta Glassmorphic
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Tipo de Usuario',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A3E3D),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Selector de Rol Premium
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFEADCD6).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedRole = 'CLIENTE'),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'CLIENTE'
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: _selectedRole ==
                                                    'CLIENTE'
                                                ? [
                                                    const BoxShadow(
                                                        color:
                                                            Color(0x1F000000),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2))
                                                  ]
                                                : [],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Cliente',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _selectedRole ==
                                                        'CLIENTE'
                                                    ? const Color(0xFF8A5D54)
                                                    : const Color(0xFF8A7A77),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedRole = 'PRESTADOR'),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'PRESTADOR'
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: _selectedRole ==
                                                    'PRESTADOR'
                                                ? [
                                                    const BoxShadow(
                                                        color:
                                                            Color(0x1F000000),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2))
                                                  ]
                                                : [],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Prestador',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _selectedRole ==
                                                        'PRESTADOR'
                                                    ? const Color(0xFF8A5D54)
                                                    : const Color(0xFF8A7A77),
                                                fontSize: 14,
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCF8F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFEADCD6), width: 1),
                                ),
                                child: Text(
                                  _selectedRole == 'CLIENTE'
                                      ? '✨ Agenda citas, encuentra estilistas locales en Fontibón y califica los servicios recibidos.'
                                      : '💼 Ofrece tus servicios, fija tus precios y horarios. Requiere cargar tus documentos (Cédula, RUT, Certificaciones) en el siguiente paso.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A7A77),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Form Fields
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: _inputDecoration(
                                    'Nombre completo', Icons.person_outline),
                                validator: (v) => v!.isEmpty
                                    ? 'Ingresa tu nombre completo'
                                    : null,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                    'Correo electrónico', Icons.email_outlined),
                                validator: (v) =>
                                    v!.isEmpty ? 'Ingresa tu correo' : null,
                                style: const TextStyle(fontSize: 14),
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
                                      color: const Color(0xFFC89D93),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v!.length < 6
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                    'Teléfono (opcional)',
                                    Icons.phone_outlined),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 24),

                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC89D93),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFE6D6D3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  shadowColor: const Color(0x3FC89D93),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'Crear Cuenta',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8A7A77), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFC89D93), size: 20),
      suffixIcon: suffixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEADCD6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEADCD6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
