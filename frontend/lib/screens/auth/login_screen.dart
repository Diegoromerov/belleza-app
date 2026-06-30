// frontend/lib/screens/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/theme.dart';

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
        color: const Color(0xFFEDE3DA), // Fondo sólido crema exacto de la imagen del logotipo (#EDE3DA)
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo_maestro_v5.png',
                      width: 260,
                      fit: BoxFit.contain,
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
                          boxShadow: AppTheme.glassShadow,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),

                              // Email Input
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: AppTheme.inputDecoration(
                                  hintText: 'Correo electrónico',
                                  prefixIcon: Icons.email_outlined,
                                  labelText: 'Correo electrónico',
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Ingresa tu correo' : null,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePassword,
                                decoration: AppTheme.inputDecoration(
                                  hintText: 'Contraseña',
                                  prefixIcon: Icons.lock_outline,
                                  labelText: 'Contraseña',
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
                                              .withValues(alpha: 0.6))),
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
                                              .withValues(alpha: 0.6))),
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
            boxShadow: AppTheme.softShadow,
          ),
          child: Center(
            child: icon,
          ),
        ),
      ),
    );
  }
}
