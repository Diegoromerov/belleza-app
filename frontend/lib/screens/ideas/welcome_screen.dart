import 'package:flutter/material.dart';
import '../../services/audience_service.dart';
import '../../shared/mens_theme.dart';
import 'capture_screen.dart';

class BiometricWelcomeScreen extends StatelessWidget {
  const BiometricWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudienceMode>(
      valueListenable: AudienceService.currentAudience,
      builder: (context, currentMode, child) {
        final isMen = currentMode == AudienceMode.men;

        final bgColor = isMen ? MensTheme.obsidianBg : Colors.white;
        final cardColor = isMen ? MensTheme.obsidianCard : Colors.purple.withOpacity(0.08);
        final primaryColor = isMen ? MensTheme.champagneGold : Colors.purple;
        final scannerColor = isMen ? MensTheme.cyberCyan : Colors.purple;
        final textColor = isMen ? MensTheme.textPrimary : Colors.black87;
        final subtextColor = isMen ? MensTheme.textSecondary : Colors.black54;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: isMen
                          ? Border.all(color: MensTheme.cyberCyan.withOpacity(0.5), width: 2)
                          : null,
                      boxShadow: isMen ? MensTheme.cyanScannerGlow : [],
                    ),
                    child: Center(
                      child: Icon(
                        isMen ? Icons.face_retouching_natural_rounded : Icons.face_retouching_natural_outlined,
                        size: 64,
                        color: scannerColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isMen
                        ? '¡Hub Biométrico IA\nVisagismo, Barba & Corte!'
                        : '¡Te damos la bienvenida al\nHub Biométrico!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      isMen
                          ? 'Escanearemos las proporciones de tu rostro para analizar tu visagismo, mandíbula y recomendar el estilo de barba y corte ideal.'
                          : 'A continuación realizaremos un escaneo facial de 15 segundos para analizar tus tonos y recomendar la rutina y paletas ideales.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: subtextColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Recomendaciones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildGuidelineRow(
                            Icons.wb_sunny_outlined,
                            'Asegura una buena iluminación natural.',
                            isMen),
                        const SizedBox(height: 12),
                        _buildGuidelineRow(
                            Icons.no_photography_outlined,
                            isMen
                                ? 'Despeja la barbilla y frente para precisión 3D.'
                                : 'Evita accesorios como gafas o gorras.',
                            isMen),
                        const SizedBox(height: 12),
                        _buildGuidelineRow(
                            Icons.center_focus_strong_outlined,
                            'Mantén la mirada fija al centro del visor.',
                            isMen),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaptureScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isMen ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: isMen ? 8 : 2,
                        shadowColor: isMen ? MensTheme.champagneGold.withOpacity(0.4) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isMen ? 'INICIAR ESCANEO DE VISAGISMO' : 'CONTINUAR',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidelineRow(IconData icon, String text, bool isMen) {
    final iconColor = isMen ? MensTheme.cyberCyan : Colors.purple;
    final textColor = isMen ? MensTheme.textSecondary : Colors.black87;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
