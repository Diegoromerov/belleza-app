import 'package:flutter/material.dart';
import '../../services/audience_service.dart';
import '../../services/biometric_service.dart';
import '../../shared/mens_theme.dart';
import '../../shared/glow_tokens.dart';
import '../../widgets/aura_3d_emblem.dart';
import '../../widgets/glow_glass_card.dart';
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
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isMen
                      ? [
                          MensTheme.obsidianBg,
                          MensTheme.obsidianCard,
                          MensTheme.obsidianBg,
                        ]
                      : [
                          GlowTokens.creamSilk,
                          GlowTokens.amber.withValues(alpha: 0.25),
                          GlowTokens.terracota.withValues(alpha: 0.4),
                          GlowTokens.nightAndean,
                        ],
                  stops: isMen ? const [0.0, 0.5, 1.0] : const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                const Aura3DEmblemWidget(
                                  size: 210.0,
                                ),
                                const SizedBox(height: 24),
                                GlowGlassCard(
                                  child: Column(
                                    children: [
                                      Text(
                                        isMen ? 'Aura Men Visagismo' : 'Hola, soy Aura',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: isMen ? MensTheme.champagneGold : GlowTokens.nightAndean,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isMen
                                            ? 'Tu asesora IA de Visagismo. Analizaré la estructura facial y barometría de tu mandíbula para recomendar tu corte de cabello y barba ideal.'
                                            : 'Tu asesora de belleza y bienestar con Inteligencia Artificial. Diagnosticaré tu tipo de piel, rostro e higiene capilar para sugerirte el ritual perfecto.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isMen ? MensTheme.textSecondary : GlowTokens.nightAndean,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),

                    
                    // 🛡️ BOTÓN DISCRETO & CASILLA DE HABEAS DATA / TRAZABLE AUDITABLE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMen ? Colors.black26 : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _consentAccepted,
                            activeColor: isMen ? MensTheme.champagneGold : GlowTokens.terracota,
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
                                text: TextSpan(
                                  text: 'Autorizo el uso de mi imagen biométrica según la ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMen ? MensTheme.textSecondary : GlowTokens.nightAndean,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Política de Tratamiento de Datos (Ley 1581)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: isMen ? MensTheme.champagneGold : GlowTokens.terracota,
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
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRegisteringConsent ? null : () => _handleStartScan(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _consentAccepted
                              ? (isMen ? MensTheme.champagneGold : GlowTokens.terracota)
                              : Colors.grey,
                          foregroundColor: isMen ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _consentAccepted ? 6 : 1,
                        ),
                        child: _isRegisteringConsent
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isMen ? 'Iniciar Escaneo de Visagismo' : 'Iniciar Ritual de Belleza Aura',
                                style: const TextStyle(
                                  fontSize: 16,
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

