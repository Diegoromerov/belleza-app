import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';
import '../widgets/glow_glass_card.dart';

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
      backgroundColor: GlowTokens.creamSilk,
      body: Container(
        decoration: BoxDecoration(
          color: GlowTokens.amber.withValues(alpha: 0.15),
        ),
        child: SafeArea(
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
                    color: GlowTokens.amber.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GlowTokens.amber,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.blur_on_rounded,
                      size: 48,
                      color: GlowTokens.terracota,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Card de Mensaje con Glassmorphism
                GlowGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        'Interrupción momentánea',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: GlowTokens.nightAndean,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'La iluminación actual o el movimiento impidieron completar un escaneo biométrico perfecto. No te preocupes, la luz cambia y podemos volver a intentarlo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: GlowTokens.nightAndean,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Botón Primario: Volver a escanear
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetryScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlowTokens.terracota,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Volver a escanear',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                  child: OutlinedButton(
                    onPressed: onViewApproximateResult,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Ver resultado aproximado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
    );
  }
}
