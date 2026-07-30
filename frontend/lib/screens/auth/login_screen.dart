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
      backgroundColor: const Color(0xFFFAF8F5), // LuxeColors.nude50
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo_maestro_v5.png',
                    width: 240,
                    fit: BoxFit.contain,
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
                          'INICIAR SESIÓN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Didot',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1A15), // LuxeColors.nude900
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Input
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFC5A052)),
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
                          ),
                          validator: (v) => v!.isEmpty ? 'Ingresa tu correo' : null,
                          style: const TextStyle(fontSize: 15, fontFamily: 'CormorantGaramond'),
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC5A052)),
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFFC5A052),
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v!.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                          style: const TextStyle(fontSize: 15, fontFamily: 'CormorantGaramond'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: Color(0xFFC5A052),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'CormorantGaramond',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

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

                        // Submit Button (Luxe Gold871)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                  'ENTRAR AL RITUAL',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Separador para Social Logins
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE8E0D5))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o accede con',
                                style: TextStyle(
                                    color: Color(0xFF9E8C78),
                                    fontSize: 12,
                                    fontFamily: 'CormorantGaramond'),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE8E0D5))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Social Buttons (Google, Outlook, Apple)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSocialButton(
                              icon: const Icon(Icons.g_mobiledata,
                                  color: Color(0xFFC5A052), size: 32),
                              onTap: _isLoading
                                  ? null
                                  : () => _handleOAuth('GOOGLE'),
                              label: 'Google',
                            ),
                            _buildSocialButton(
                              icon: const Icon(Icons.mail_outline,
                                  color: Color(0xFFC5A052), size: 22),
                              onTap: _isLoading
                                  ? null
                                  : () => _handleOAuth('OUTLOOK'),
                              label: 'Outlook',
                            ),
                            _buildSocialButton(
                              icon: const Icon(Icons.apple,
                                  color: Color(0xFF1F1A15), size: 24),
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
                const SizedBox(height: 28),

                // Link de Registro
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC5A052),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(color: Color(0xFF6B5A48), fontSize: 14, fontFamily: 'CormorantGaramond'),
                      children: [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC5A052)),
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFAF8F5),
            border: Border.all(color: const Color(0xFFE8E0D5), width: 1.0),
          ),
          child: Center(
            child: icon,
          ),
        ),
      ),
    );
  }
}
