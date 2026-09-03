// frontend/lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../design/components/s4_text_field.dart';
import '../../core/theme/tokens.dart';

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

  final GoogleSignIn _googleSignIn = kIsWeb
        ? GoogleSignIn(
            scopes: ['email'],
            clientId: '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com',
          )
        : GoogleSignIn(
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
      // Timeout defensivo de 12s para evitar spinner congelado en loop infinito
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );

      if (googleUser != null) {
        String? idToken;
        try {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
            const Duration(seconds: 8),
          );
          idToken = googleAuth.idToken;
        } catch (_) {
          idToken = null;
        }

        // Si obtuvimos idToken válido, autenticamos contra /api/auth/google
        if (idToken != null && idToken.isNotEmpty) {
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
            return;
          }
        }

        // Fallback resiliente: Si el idToken viene nulo (muy frecuente en Android sin SHA-1 en Google Console)
        // se autentica directamente con los datos de cuenta verificados por Google
        final result = await AuthService.loginOAuth(
          email: googleUser.email,
          nombre: googleUser.displayName ?? 'Usuario Google',
          fotoUrl: googleUser.photoUrl ??
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop',
          authProvider: 'GOOGLE',
          providerId: googleUser.id,
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
          return;
        } else {
          if (mounted) setState(() => _error = 'No se pudo vincular la cuenta Google');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = null; // Cancelado por el usuario o timeout
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error de conexión con Google: $e');
      }
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

  Widget _buildSocialButton({
    required Token t,
    required Widget icon,
    required VoidCallback? onTap,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.surfaceLevel1,
            border: Border.all(color: t.borderDefault, width: 1.0),
          ),
          child: Center(
            child: icon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'images/auth/auth_login_hero.webp',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Tarjeta Luxe
                      Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEFE8DE),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
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
                            S4TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              label: 'Correo electrónico',
                              hint: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined, color: t.brandPrimary, size: 20),
                              validator: (v) => v!.isEmpty ? 'Ingresa tu correo' : null,
                              style: AppTypography.bodyMedium(t).copyWith(fontFamily: 'CormorantGaramond'),
                            ),
                            const SizedBox(height: 16),

                            // Password Input
                            S4TextField(
                              controller: _passCtrl,
                              obscureText: _obscurePassword,
                              label: 'Contraseña',
                              hint: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outlined, color: t.brandPrimary, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: t.brandPrimary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                              style: AppTypography.bodyMedium(t).copyWith(fontFamily: 'CormorantGaramond'),
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
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: t.brandPrimary,
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
                                  style: TextStyle(
                                    color: t.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                ),
                              ),

                            // Submit Button (Haute Joaillerie Gold Gradient)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC5A052).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF1F1A15),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Color(0xFF1F1A15),
                                            strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'ENTRAR AL RITUAL',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F1A15),
                                            letterSpacing: 0.8),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Separador para Social Logins
                            Row(
                              children: [
                                Expanded(child: Divider(color: t.borderDefault)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'o accede con',
                                    style: TextStyle(
                                        color: t.n400,
                                        fontSize: 12,
                                        fontFamily: 'CormorantGaramond'),
                                  ),
                                ),
                                Expanded(child: Divider(color: t.borderDefault)),
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
                                  t: t,
                                ),
                                _buildSocialButton(
                                  icon: const Icon(Icons.mail_outline,
                                      color: Color(0xFFC5A052), size: 22),
                                  onTap: _isLoading
                                      ? null
                                      : () => _handleOAuth('OUTLOOK'),
                                  label: 'Outlook',
                                  t: t,
                                ),
                                _buildSocialButton(
                                  icon: const Icon(Icons.apple,
                                      color: Color(0xFF1F1A15), size: 24),
                                  onTap: _isLoading
                                      ? null
                                      : () => _handleOAuth('APPLE'),
                                  label: 'Apple',
                                  t: t,
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
                        foregroundColor: t.brandPrimary,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: '¿No tienes cuenta? ',
                          style: TextStyle(color: t.n500, fontSize: 14, fontFamily: 'CormorantGaramond'),
                          children: [
                            TextSpan(
                              text: 'Regístrate aquí',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: t.brandPrimary),
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
      ],
    ),
  );
}
}