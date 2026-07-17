import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/services/api_service.dart';

// Estado del ejercicio de entrenamiento
class TrainingState {
  final int difficultyLevel; // 1 (Básico), 2 (Intermedio), 3 (Avanzado)
  final List<String> sequence; // Secuencia de estímulos (colores)
  final int currentIndex;
  final int correctAnswers;
  final int totalAttempts;
  final bool isPlaying;
  final String? feedbackMessage; // Mensaje de feedback

  const TrainingState({
    this.difficultyLevel = 1,
    this.sequence = const [],
    this.currentIndex = 0,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    this.isPlaying = false,
    this.feedbackMessage,
  });

  TrainingState copyWith({
    int? difficultyLevel,
    List<String>? sequence,
    int? currentIndex,
    int? correctAnswers,
    int? totalAttempts,
    bool? isPlaying,
    String? feedbackMessage,
  }) {
    return TrainingState(
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      sequence: sequence ?? this.sequence,
      currentIndex: currentIndex ?? this.currentIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      isPlaying: isPlaying ?? this.isPlaying,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
    );
  }
}

class TrainingNotifier extends StateNotifier<TrainingState> {
  final Ref ref;
  final List<String> _stimuliPool = ['🔴 Rojo', '🔵 Azul', '🟢 Verde', '🟡 Dorado', '🟣 Violeta'];

  TrainingNotifier(this.ref) : super(const TrainingState());

  void startTraining(int difficultyLevel) {
    final sequenceLength = 5 + (difficultyLevel * 3);
    final random = Random();
    final newSequence = List<String>.generate(
      sequenceLength,
      (_) => _stimuliPool[random.nextInt(_stimuliPool.length)],
    );
    state = TrainingState(
      difficultyLevel: difficultyLevel,
      sequence: newSequence,
      currentIndex: difficultyLevel, // N‑Back empieza a evaluar desde el índice N
      isPlaying: true,
      feedbackMessage: 'Observa la secuencia inicial...',
    );
  }

  void evaluateAnswer(bool isMatch) {
    if (!state.isPlaying || state.currentIndex < state.difficultyLevel) return;
    final targetIndex = state.currentIndex - state.difficultyLevel;
    final isActuallyMatch = state.sequence[state.currentIndex] == state.sequence[targetIndex];
    final isCorrect = isMatch == isActuallyMatch;
    state = state.copyWith(
      correctAnswers: isCorrect ? state.correctAnswers + 1 : state.correctAnswers,
      totalAttempts: state.totalAttempts + 1,
      feedbackMessage: isCorrect
          ? '¡Excelente! Protocolo memorizado correctamente.'
          : 'Atención: Revisa la secuencia anterior.',
    );
    _advanceSequence();
  }

  void _advanceSequence() {
    if (state.currentIndex >= state.sequence.length - 1) {
      _finishTraining();
    } else {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        feedbackMessage: null,
      );
    }
  }

  Future<void> _finishTraining() async {
    final accuracy = state.totalAttempts > 0
        ? (state.correctAnswers / state.totalAttempts * 100).round()
        : 0;
    state = state.copyWith(
      isPlaying: false,
      feedbackMessage: 'Ejercicio completado. Precisión: $accuracy%',
    );
    // Enviar resultado al backend
    final authAsync = ref.read(authProvider);
    final user = authAsync.value;
    if (user != null) {
      await ref.read(apiServiceProvider).submitTrainingResult(
        userId: user.id,
        difficultyLevel: state.difficultyLevel,
        totalAttempts: state.totalAttempts,
        correctAnswers: state.correctAnswers,
        accuracy: accuracy,
      );
    }
  }

  /// Public method to trigger training finish and result submission.
  Future<void> finishTraining() async {
    await _finishTraining();
  }

}

final trainingProvider = StateNotifierProvider<TrainingNotifier, TrainingState>((ref) => TrainingNotifier(ref));
