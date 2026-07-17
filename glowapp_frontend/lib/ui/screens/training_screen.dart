import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:glowapp_frontend/core/theme/app_theme.dart';
import 'package:glowapp_frontend/providers/training_provider.dart';
import 'package:glowapp_frontend/ui/widgets/glass_card.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingState = ref.watch(trainingProvider);
    final notifier = ref.read(trainingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento de Retención'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (trainingState.isPlaying) ...[
                  LinearProgressIndicator(
                    value: trainingState.currentIndex / trainingState.sequence.length,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(GlowTheme.secondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Grado de Complejidad: ${_getDifficultyName(trainingState.difficultyLevel)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                ],
                Expanded(
                  child: Center(
                    child: trainingState.isPlaying
                        ? _ActiveExerciseView(state: trainingState, notifier: notifier)
                        : _ResultsView(state: trainingState, notifier: notifier),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyName(int level) {
    switch (level) {
      case 1:
        return 'Básico (N‑1)';
      case 2:
        return 'Intermedio (N‑2)';
      case 3:
        return 'Avanzado (N‑3)';
      default:
        return 'Personalizado';
    }
  }
}

// -------------------- UI components --------------------

class _ActiveExerciseView extends StatelessWidget {
  final TrainingState state;
  final TrainingNotifier notifier;

  const _ActiveExerciseView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final currentStimulus = state.sequence[state.currentIndex];
    final targetStimulus = state.currentIndex >= state.difficultyLevel
        ? state.sequence[state.currentIndex - state.difficultyLevel]
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          child: Column(
            children: [
              const Text('Estímulo Actual', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Text(
                currentStimulus,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (targetStimulus != null) ...[
                const SizedBox(height: 16),
                Text(
                  '¿Es igual al de hace ${state.difficultyLevel} paso(s)?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        if (state.feedbackMessage != null) ...[
          const SizedBox(height: 24),
          Text(
            state.feedbackMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: state.feedbackMessage!.contains('Excelente') ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 48),
        if (state.currentIndex >= state.difficultyLevel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AnswerButton(
                label: 'NO',
                color: Colors.redAccent,
                onPressed: () async {
                  await _triggerHaptic(false);
                  notifier.evaluateAnswer(false);
                },
              ),
              _AnswerButton(
                label: 'SÍ',
                color: GlowTheme.primary,
                onPressed: () async {
                  await _triggerHaptic(true);
                  notifier.evaluateAnswer(true);
                },
              ),
            ],
          )
        else
          const Text('Observa la secuencia...', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Future<void> _triggerHaptic(bool isYes) async {
    if (await Vibration.hasVibrator() ?? false) {
      isYes ? Vibration.vibrate(duration: 50) : Vibration.vibrate(pattern: [0, 50, 50, 50]);
    }
  }
}

class _ResultsView extends StatelessWidget {
  final TrainingState state;
  final TrainingNotifier notifier;

  const _ResultsView({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final accuracy = state.totalAttempts > 0 ? (state.correctAnswers / state.totalAttempts * 100).round() : 0;
    final passed = accuracy >= 80;

    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.verified_outlined : Icons.auto_stories_outlined,
            size: 64,
            color: passed ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          Text(
            passed ? '¡Dominio Alcanzado!' : 'Necesita Refuerzo',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Precisión en el protocolo: $accuracy%',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => notifier.reset(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  notifier.reset();
                  context.pop();
                },
                child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _AnswerButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
