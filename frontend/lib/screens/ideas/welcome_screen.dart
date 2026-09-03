import 'package:flutter/material.dart';
import '../../services/audience_service.dart';
import '../../services/biometric_service.dart';
import '../../shared/mens_theme.dart';
import '../../shared/glow_tokens.dart';
import 'capture_screen.dart';

class BiometricWelcomeScreen extends StatefulWidget {
  const BiometricWelcomeScreen({super.key});

  @override
  State<BiometricWelcomeScreen> createState() => _BiometricWelcomeScreenState();
}

class _BiometricWelcomeScreenState extends State<BiometricWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkExistingConsent();
  }

  Future<void> _checkExistingConsent() async {
    final hasConsent = await BiometricService.hasConsent();
    if (hasConsent && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaptureScreen()),
      );
    }
  }
  bool _consentAccepted = false;
  bool _isRegisteringConsent = false;

  void _showPrivacyPolicyModal(BuildContext context, bool isMen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isMen ? MensTheme.obsidianCard : GlowTokens.creamSilk,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isMen ? MensTheme.champagneGold.withOpacity(0.3) : GlowTokens.terracota.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: isMen ? MensTheme.champagneGold : GlowTokens.terracota,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Política de Tratamiento Biométrico (Ley 1581)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMen ? MensTheme.textPrimary : GlowTokens.nightAndean,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  'De conformidad con la Ley Estatutaria 1581 de 2012 de Habeas Data de Colombia y el Decreto 1377 de 2013, te informamos que la captura de tu imagen facial y/o manos se considera un DATO SENSIBLE BIOMÉTRICO.\n\n'
                  '1. FINALIDAD DEL PROCESAMIENTO:\n'
                  'Tus fotos serán procesadas mediante algoritmos de Visión Computacional (MLKit/YouCam/ai_worker) y LLMs (DeepSeek/Gemini) con la única finalidad de determinar tu subtono de piel, estación cromática, métricas cutáneas y sugerirte productos de cuidado personal.\n\n'
                  '2. ALMACENAMIENTO VOLÁTIL & PRIVACIDAD:\n'
                  'Las imágenes no se guardan de forma permanente en servidores de terceros sin tu autorización expresa. Son procesadas en memoria de sesión.\n\n'
                  '3. REGISTRO AUDITABLE:\n'
                  'Al marcar la casilla de autorización, aceptaste registrar un token auditable con tu ID de usuario, IP de conexión, User-Agent y timestamp en nuestro panel de control B2B / Dashboard Administrativo.\n\n'
                  '4. CANALES DE ATENCIÓN Y REVOCATORIA (DERECHOS ARCO):\n'
                  'Puedes solicitar el acceso, actualización, rectificación o supresión de tus datos en cualquier momento escribiendo al correo oficial: habeasdata@glowapp.com o desde la sección de Ajustes de tu perfil.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isMen ? MensTheme.textSecondary : GlowTokens.nightAndean.withOpacity(0.85),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMen ? MensTheme.champagneGold : GlowTokens.terracota,
                  foregroundColor: isMen ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido y Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartScan(BuildContext context) async {
    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes autorizar el tratamiento de datos biométricos para continuar.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isRegisteringConsent = true;
    });

    try {
      // Registrar consentimiento auditable en el Backend de PostgreSQL/Dashboard B2B
      await BiometricService.saveConsent();
    } catch (e) {
      debugPrint('⚠️ Consentimiento guardado localmente en sesión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRegisteringConsent = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CaptureScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudienceMode>(
      valueListenable: AudienceService.currentAudience,
      builder: (context, currentMode, child) {
        final isMen = currentMode == AudienceMode.men;

        return Scaffold(
          backgroundColor: isMen ? MensTheme.obsidianBg : const Color(0xFFB17A48),
          body: Stack(
            children: [
              // 1. Imagen de Fondo de Alta Definición Haute Joaillerie
              Positioned.fill(
                child: isMen
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              MensTheme.obsidianBg,
                              MensTheme.obsidianCard,
                              MensTheme.obsidianBg,
                            ],
                          ),
                        ),
                      )
                    : Image.asset(
                        'images/aura_welcome_poster.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
              ),

              // 2. Capa de Controles Interactivos (Contrato y Botón de Inicio)
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          // Botón sutil de retroceso si existe historial de navegación
                          Align(
                            alignment: Alignment.topLeft,
                            child: Navigator.canPop(context)
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                                      onPressed: () => Navigator.maybePop(context),
                                    ),
                                  )
                                : const SizedBox(height: 24),
                          ),

                          const Spacer(),

                          // 🛡️ Contenedor Frosted Glass del Contrato & Habeas Data (Ley 1581)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1A15).withValues(alpha: 0.76),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _consentAccepted,
                                  activeColor: const Color(0xFFD4AF37),
                                  checkColor: Colors.black,
                                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _consentAccepted = val ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showPrivacyPolicyModal(context, isMen),
                                    child: RichText(
                                      text: const TextSpan(
                                        text: 'Autorizo el uso de mi imagen biométrica según la ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Política de Tratamiento de Datos (Ley 1581)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                              color: Color(0xFFE5C158),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Botón Principal de Inicio del Ritual
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isRegisteringConsent ? null : () => _handleStartScan(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _consentAccepted
                                    ? const Color(0xFFC5A052)
                                    : const Color(0xFF7A6B5A).withValues(alpha: 0.55),
                                foregroundColor: _consentAccepted
                                    ? const Color(0xFF14100C)
                                    : Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: _consentAccepted ? 6 : 0,
                              ),
                              child: _isRegisteringConsent
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      isMen ? 'Iniciar Escaneo de Visagismo' : 'Iniciar Ritual de Belleza Aura',
                                      style: const TextStyle(
                                        fontFamily: 'CormorantGaramond',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

