import 'package:flutter/material.dart';
import '../../shared/glow_tokens.dart';
import '../../widgets/glow_glass_card.dart';

/// Pantalla de Error Elegante y Transparencia de Fallback.
/// Diseñada con un fondo ámbar suave (#E8B4A0 con baja opacidad), mensaje empático
/// y dos opciones de acción para mantener una experiencia fluida.
class FallbackTransparencyScreen extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetryScan;
  final VoidCallback? onViewApproximateResult;

  const FallbackTransparencyScreen({
    super.key,
    this.error,
    this.onRetryScan,
    this.onViewApproximateResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Icono Empático
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3D59B).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC5A052),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.blur_on_rounded,
                        size: 48,
                        color: Color(0xFFC5A052),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card de Mensaje con Glassmorphism
                  GlowGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Interrupción momentánea',
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1A15),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'La iluminación actual o el movimiento impidieron completar un escaneo biométrico perfecto. No te preocupes, la luz cambia y podemos volver a intentarlo.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF6B5E59),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botón Primario: Volver a escanear (Gold capsule)
                  Container(
                    height: 52,
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
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onRetryScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 20, color: Color(0xFF1F1A15)),
                          SizedBox(width: 8),
                          Text(
                            'Volver a escanear',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1A15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón Secundario: Ver resultado aproximado
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onViewApproximateResult,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC5A052), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Ver resultado aproximado',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC5A052),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
