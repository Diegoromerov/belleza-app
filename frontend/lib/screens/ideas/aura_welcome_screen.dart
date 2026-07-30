import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';
import '../../../widgets/aura_3d_emblem.dart';
import '../widgets/glow_glass_card.dart';

/// Pantalla de Bienvenida de "Aura" (IA Asesora de Belleza de GlowApp).
/// Cuenta con el nuevo Emblema Metálico 3D "GA" en Oro Rosa con animación interactiva.
class AuraWelcomeScreen extends StatelessWidget {
  final VoidCallback? onStartRitual;

  const AuraWelcomeScreen({
    super.key,
    this.onStartRitual,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GlowTokens.creamSilk,
                GlowTokens.amber.withValues(alpha: 0.25),
                GlowTokens.terracota.withValues(alpha: 0.4),
                GlowTokens.nightAndean,
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const Spacer(),
                  const Aura3DEmblemWidget(
                    size: 230.0,
                  ),
                  const SizedBox(height: 36),
                  GlowGlassCard(
                    child: Column(
                      children: [
                        Text(
                          'Hola, soy Aura',
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu asesora de belleza y bienestar con Inteligencia Artificial. Diagnosticaré tu tipo de piel, rostro e higiene capilar para sugerirte el ritual perfecto.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: GlowTokens.nightAndean,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStartRitual,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlowTokens.roseGold,
                        foregroundColor: GlowTokens.nightAndean,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shadowColor: GlowTokens.roseGold.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Comenzar mi ritual',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

