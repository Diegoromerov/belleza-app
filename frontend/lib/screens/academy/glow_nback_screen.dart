// frontend/lib/screens/academy/glow_nback_screen.dart
// NBackScreen migrado de glowapp_frontend — adaptado a StatefulWidget puro (sin Riverpod)
import 'dart:math';
import 'package:flutter/material.dart';
import 'glow_glass_card.dart';

// ─── Constantes de tema ───────────────────────────────────────────────────────
const Color _kPrimary    = Color(0xFFC89D93);
const Color _kAccent     = Color(0xFFE2C4BC);
const Color _kBackground = Color(0xFF0F172A);

// ─── Modelo de estado (sin Riverpod) ─────────────────────────────────────────
class _TrainingState {
  final int difficultyLevel;
  final List<String> sequence;
  final int currentIndex;
  final int correctAnswers;
  final int totalAttempts;
  final bool isPlaying;
  final String? feedbackMessage;
  final bool? lastAnswerCorrect;

  const _TrainingState({
    this.difficultyLevel = 1,
    this.sequence = const [],
    this.currentIndex = 0,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    this.isPlaying = false,
    this.feedbackMessage,
    this.lastAnswerCorrect,
  });

  _TrainingState copyWith({
    int? difficultyLevel,
    List<String>? sequence,
    int? currentIndex,
    int? correctAnswers,
    int? totalAttempts,
    bool? isPlaying,
    String? feedbackMessage,
    bool? lastAnswerCorrect,
  }) {
    return _TrainingState(
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      sequence: sequence ?? this.sequence,
      currentIndex: currentIndex ?? this.currentIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      isPlaying: isPlaying ?? this.isPlaying,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
    );
  }
}

// ─── Pantalla principal ───────────────────────────────────────────────────────
class GlowNBackScreen extends StatefulWidget {
  const GlowNBackScreen({super.key});

  @override
  State<GlowNBackScreen> createState() => _GlowNBackScreenState();
}

class _GlowNBackScreenState extends State<GlowNBackScreen>
    with SingleTickerProviderStateMixin {

  static const List<String> _stimuliPool = [
    '🔴 Rojo', '🔵 Azul', '🟢 Verde', '🟡 Dorado', '🟣 Violeta'
  ];

  static const Map<String, Color> _stimuliColors = {
    '🔴 Rojo'   : Color(0xFFEF4444),
    '🔵 Azul'   : Color(0xFF3B82F6),
    '🟢 Verde'  : Color(0xFF22C55E),
    '🟡 Dorado' : Color(0xFFF59E0B),
    '🟣 Violeta': Color(0xFFA855F7),
  };

  _TrainingState _state = const _TrainingState();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTraining(1);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Lógica del juego (portada desde training_provider.dart) ─────────────
  void _startTraining(int level) {
    final sequenceLength = 5 + (level * 3);
    final random = Random();
    final newSequence = List<String>.generate(
      sequenceLength,
      (_) => _stimuliPool[random.nextInt(_stimuliPool.length)],
    );
    setState(() {
      _state = _TrainingState(
        difficultyLevel: level,
        sequence: newSequence,
        currentIndex: level,
        isPlaying: true,
        feedbackMessage: 'Observa la secuencia inicial...',
      );
    });
  }

  void _evaluateAnswer(bool isMatch) {
    if (!_state.isPlaying) return;
    final targetIndex = _state.currentIndex - _state.difficultyLevel;
    final isActuallyMatch =
        _state.sequence[_state.currentIndex] == _state.sequence[targetIndex];
    final isCorrect = isMatch == isActuallyMatch;

    _pulseController.forward(from: 0);

    setState(() {
      _state = _state.copyWith(
        correctAnswers: isCorrect ? _state.correctAnswers + 1 : _state.correctAnswers,
        totalAttempts: _state.totalAttempts + 1,
        lastAnswerCorrect: isCorrect,
        feedbackMessage: isCorrect
            ? '¡Excelente! Protocolo memorizado correctamente.'
            : 'Atención: Revisa la secuencia anterior.',
      );
    });

    Future.delayed(const Duration(milliseconds: 700), _advanceSequence);
  }

  void _advanceSequence() {
    if (!mounted) return;
    if (_state.currentIndex >= _state.sequence.length - 1) {
      _finishTraining();
    } else {
      setState(() {
        _state = _state.copyWith(
          currentIndex: _state.currentIndex + 1,
          feedbackMessage: null,
          lastAnswerCorrect: null,
        );
      });
    }
  }

  void _finishTraining() {
    final accuracy = _state.totalAttempts > 0
        ? (_state.correctAnswers / _state.totalAttempts * 100).round()
        : 0;
    setState(() {
      _state = _state.copyWith(
        isPlaying: false,
        feedbackMessage: 'Ejercicio completado. Precisión: $accuracy%',
        lastAnswerCorrect: null,
      );
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentStimulus = _state.isPlaying && _state.sequence.isNotEmpty
        ? _state.sequence[_state.currentIndex]
        : null;
    final stimulusColor = currentStimulus != null
        ? _stimuliColors[currentStimulus] ?? _kPrimary
        : _kPrimary;
    final accuracy = _state.totalAttempts > 0
        ? (_state.correctAnswers / _state.totalAttempts * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Juego N‑Back',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Selector de nivel
          ...[1, 2, 3].map((level) => GestureDetector(
            onTap: () => _startTraining(level),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _state.difficultyLevel == level
                    ? _kPrimary
                    : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${level}‑Back',
                  style: TextStyle(
                    color: _state.difficultyLevel == level
                        ? Colors.white
                        : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Barra de progreso ──
            if (_state.sequence.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paso ${_state.currentIndex + 1} de ${_state.sequence.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    'Precisión: $accuracy%',
                    style: TextStyle(
                      color: accuracy >= 70 ? const Color(0xFF22C55E) : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _state.sequence.isEmpty
                      ? 0
                      : (_state.currentIndex + 1) / _state.sequence.length,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(_kPrimary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ── Estímulo visual ──
            Expanded(
              child: Center(
                child: GlowGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: stimulusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: stimulusColor.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentStimulus ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_state.feedbackMessage != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _state.feedbackMessage!,
                              key: ValueKey(_state.feedbackMessage),
                              style: TextStyle(
                                color: _state.lastAnswerCorrect == true
                                    ? const Color(0xFF22C55E)
                                    : _state.lastAnswerCorrect == false
                                        ? Colors.redAccent
                                        : Colors.white60,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Marcador ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip(Icons.check_circle_outline, '${_state.correctAnswers}', const Color(0xFF22C55E), 'Aciertos'),
                _statChip(Icons.cancel_outlined, '${_state.totalAttempts - _state.correctAnswers}', Colors.redAccent, 'Errores'),
                _statChip(Icons.flag_outlined, '${_state.totalAttempts}', _kAccent, 'Intentos'),
              ],
            ),

            const SizedBox(height: 24),

            // ── Botones de respuesta ──
            if (_state.isPlaying) ...[
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: '✅  Sí coincide',
                      color: const Color(0xFF22C55E),
                      onPressed: () => _evaluateAnswer(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      label: '❌  No coincide',
                      color: Colors.redAccent,
                      onPressed: () => _evaluateAnswer(false),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: _actionButton(
                  label: '🔄  Jugar de nuevo',
                  color: _kPrimary,
                  onPressed: () => _startTraining(_state.difficultyLevel),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
