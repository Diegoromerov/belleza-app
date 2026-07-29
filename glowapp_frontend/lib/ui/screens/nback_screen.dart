import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:glowapp_frontend/core/theme/app_theme.dart';
import 'package:glowapp_frontend/providers/training_provider.dart';
import 'package:glowapp_frontend/ui/widgets/glass_card.dart';

/// Pantalla del juego N‑Back.
/// Se muestra una secuencia de círculos de colores. El usuario debe
/// pulsar el botón "Coincide" cuando el color actual coincide con el
/// que apareció `nivel` pasos antes.
class NBackScreen extends ConsumerStatefulWidget {
  const NBackScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NBackScreen> createState() => _NBackScreenState();
}

class _NBackScreenState extends ConsumerState<NBackScreen> {
  @override
  void initState() {
    super.initState();
    // Iniciar el juego al entrar en la pantalla.
    Future.microtask(() => ref.read(trainingProvider.notifier).startGame());
  }

  void _handleMatch() async {
    final notifier = ref.read(trainingProvider.notifier);
    await notifier.checkMatch();
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego N‑Back'),
        backgroundColor: GlowTheme.primary,
      ),
      backgroundColor: GlowTheme.background,
      body: Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mostrar el estímulo actual
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: state.currentStimulusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
                const SizedBox(height: 24),
                // Botón de coincidencia
                ElevatedButton.icon(
                  onPressed: state.isPlaying ? _handleMatch : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Coincide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlowTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                // Feedback y progreso
                if (state.feedbackMessage != null)
                  Text(
                    state.feedbackMessage!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 12),
                Text('Intentos: ${state.totalAttempts} • Aciertos: ${state.correctAnswers}'),
                const SizedBox(height: 12),
                if (!state.isPlaying)
                  ElevatedButton(
                    onPressed: () => ref.read(trainingProvider.notifier).startGame(),
                    child: const Text('Reiniciar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
