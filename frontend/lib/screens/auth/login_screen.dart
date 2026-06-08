// frontend/lib/screens/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Forzar limpieza de base url cache por si no se limpió en logout
    ApiService.resetCachedBaseUrl();
    try {
      final result =
          await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (result != null && mounted) {
        final bool onboardingCompleto =
            result['user']['onboarding_completo'] ?? false;
        final String? role = result['user']['role'];
        if (onboardingCompleto) {
          if (role == 'provider') {
            Navigator.pushReplacementNamed(context, '/provider');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {
        setState(() => _error = 'Credenciales incorrectas');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String idToken = 'test_google_token_usuario_pruebas';
      
      // En producción / móviles reales, ejecutamos el flujo interactivo de Google
      if (!kIsWeb) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          if (googleAuth.idToken != null) {
            idToken = googleAuth.idToken!;
          }
        } else {
          // El usuario canceló la autenticación
          setState(() => _isLoading = false);
          return;
        }
      }

      final result = await AuthService.loginWithGoogle(idToken);

      if (result != null && mounted) {
        final bool onboardingCompleto =
            result['user']['onboarding_completo'] ?? false;
        final String? role = result['user']['role'];
        if (onboardingCompleto) {
          if (role == 'provider') {
            Navigator.pushReplacementNamed(context, '/provider');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {
        setState(() => _error = 'Error al autenticar con Google');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOAuth(String provider) async {
    if (provider == 'GOOGLE') {
      await _handleGoogleSignIn();
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final email = provider == 'OUTLOOK'
              ? 'outlookuser@outlook.com'
              : 'appleuser@icloud.com';
      final name = provider == 'OUTLOOK' ? 'Usuario de Outlook' : 'Usuario de Apple';
      final fotoUrl = provider == 'OUTLOOK'
              ? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200&auto=format&fit=crop'
              : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop';
      final providerId = provider == 'OUTLOOK' ? 'outlook_987654321' : 'apple_555666777';

      final result = await AuthService.loginOAuth(
        email: email,
        nombre: name,
        fotoUrl: fotoUrl,
        authProvider: provider,
        providerId: providerId,
      );

      if (result != null && mounted) {
        final bool onboardingCompleto =
            result['user']['onboarding_completo'] ?? false;
        final String? role = result['user']['role'];
        if (onboardingCompleto) {
          if (role == 'provider') {
            Navigator.pushReplacementNamed(context, '/provider');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else {
        setState(() => _error = 'Error al autenticar con $provider');
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  // Encabezado principal elegante
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F8A6B63),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            )
                          ]),
                      child: Icon(Icons.face_retouching_natural,
                          size: 56, color: Color(0xFFC89D93)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belleza App',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4A3E3D),
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu estilista a domicilio en Fontibón',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A7A77),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta Glassmorphic
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x0A000000),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Ingreso Local',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A3E3D),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email Input
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                    'Correo electrónico', Icons.email_outlined),
                                validator: (v) =>
                                    v!.isEmpty ? 'Ingresa tu correo' : null,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 16),

                              // Password Input
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
                                style: const TextStyle(fontSize: 15),
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
                                onPressed: _isLoading ? null : _handleLogin,
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
                                        'Entrar con Correo',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2),
                                      ),
                              ),

                              const SizedBox(height: 24),

                              // Separador para Social Logins
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: const Color(0xFFE8D7D3)
                                              .withOpacity(0.6))),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'o accede rápido con',
                                      style: TextStyle(
                                          color: Color(0xFF8A7A77),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: const Color(0xFFE8D7D3)
                                              .withOpacity(0.6))),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Social Buttons en Igualdad de Condiciones (Google, Outlook, Apple)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialButton(
                                    icon: const Icon(Icons.g_mobiledata,
                                        color: Color(0xFFD32F2F), size: 36),
                                    onTap: _isLoading
                                        ? null
                                        : () => _handleOAuth('GOOGLE'),
                                    label: 'Google',
                                  ),
                                  _buildSocialButton(
                                    icon: const Icon(Icons.mail_outline,
                                        color: Color(0xFF1976D2), size: 24),
                                    onTap: _isLoading
                                        ? null
                                        : () => _handleOAuth('OUTLOOK'),
                                    label: 'Outlook',
                                  ),
                                  _buildSocialButton(
                                    icon: const Icon(Icons.apple,
                                        color: Colors.black87, size: 28),
                                    onTap: _isLoading
                                        ? null
                                        : () => _handleOAuth('APPLE'),
                                    label: 'Apple',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Link de Registro
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8A5D54),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tienes cuenta? ',
                        style:
                            TextStyle(color: Color(0xFF7A6A67), fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC89D93)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback? onTap,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEADCD6), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: icon,
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
      fillColor: Colors.white.withOpacity(0.7),
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
