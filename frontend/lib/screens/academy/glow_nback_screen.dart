// frontend/lib/screens/academy/glow_nback_screen.dart
// NBackScreen migrado — paleta oficial AppTheme (fondo crema, rose-gold, terracota)
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';

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
    '🔴 Rojo'   : Color(0xFFDC6B6B),
    '🔵 Azul'   : Color(0xFF6B9EDC),
    '🟢 Verde'  : Color(0xFF6BAA7A),
    '🟡 Dorado' : Color(0xFFD4A843),
    '🟣 Violeta': Color(0xFF9E7DC8),
  };

  // ─── Estado ───────────────────────────────────────────────────────────────
  int _difficultyLevel = 1;
  List<String> _sequence = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _totalAttempts = 0;
  bool _isPlaying = false;
  String? _feedbackMessage;
  bool? _lastAnswerCorrect;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTraining(1);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Lógica N-Back ────────────────────────────────────────────────────────
  void _startTraining(int level) {
    final sequenceLength = 5 + (level * 3);
    final random = Random();
    final newSequence = List<String>.generate(
      sequenceLength,
      (_) => _stimuliPool[random.nextInt(_stimuliPool.length)],
    );
    setState(() {
      _difficultyLevel = level;
      _sequence = newSequence;
      _currentIndex = level;
      _correctAnswers = 0;
      _totalAttempts = 0;
      _isPlaying = true;
      _feedbackMessage = 'Observa el estímulo inicial...';
      _lastAnswerCorrect = null;
    });
  }

  void _evaluateAnswer(bool isMatch) {
    if (!_isPlaying) return;
    final targetIndex = _currentIndex - _difficultyLevel;
    final isActuallyMatch = _sequence[_currentIndex] == _sequence[targetIndex];
    final isCorrect = isMatch == isActuallyMatch;

    _pulseController.forward(from: 0);

    setState(() {
      if (isCorrect) _correctAnswers++;
      _totalAttempts++;
      _lastAnswerCorrect = isCorrect;
      _feedbackMessage = isCorrect
          ? '¡Excelente! Protocolo memorizado.'
          : 'Atención: Revisa la secuencia.';
    });

    Future.delayed(const Duration(milliseconds: 700), _advanceSequence);
  }

  void _advanceSequence() {
    if (!mounted) return;
    if (_currentIndex >= _sequence.length - 1) {
      _finishTraining();
    } else {
      setState(() {
        _currentIndex++;
        _feedbackMessage = null;
        _lastAnswerCorrect = null;
      });
    }
  }

  void _finishTraining() {
    final accuracy = _totalAttempts > 0
        ? (_correctAnswers / _totalAttempts * 100).round()
        : 0;
    setState(() {
      _isPlaying = false;
      _feedbackMessage = 'Ejercicio completado. Precisión: $accuracy%';
      _lastAnswerCorrect = null;
    });
  }

  int get _accuracy => _totalAttempts > 0
      ? (_correctAnswers / _totalAttempts * 100).round()
      : 0;

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentStimulus =
        _isPlaying && _sequence.isNotEmpty ? _sequence[_currentIndex] : null;
    final stimulusColor =
        _stimuliColors[currentStimulus] ?? AppTheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Entrenamiento N-Back',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1A15),
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        foregroundColor: const Color(0xFF1F1A15),
        elevation: 0,
        actions: [
          // Selector de nivel
          ...[1, 2, 3].map((level) => GestureDetector(
                onTap: () => _startTraining(level),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 3, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _difficultyLevel == level
                        ? AppTheme.primary
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${level}‑Back',
                      style: TextStyle(
                        color: _difficultyLevel == level
                            ? Colors.white
                            : AppTheme.text,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
          children: [
            // ── Barra de progreso ──────────────────────────────────────────
            if (_sequence.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paso ${_currentIndex + 1} de ${_sequence.length}',
                    style: const TextStyle(
                        color: Color(0xFF8E7D7A), fontSize: 12),
                  ),
                  Text(
                    'Precisión: $_accuracy%',
                    style: TextStyle(
                      color: _accuracy >= 70
                          ? AppTheme.success
                          : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _sequence.isEmpty
                      ? 0
                      : (_currentIndex + 1) / _sequence.length,
                  backgroundColor: AppTheme.surface,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Tarjeta de estímulo ────────────────────────────────────────
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
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
                            color: stimulusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: stimulusColor, width: 3),
                          ),
                          child: Icon(Icons.circle,
                              color: stimulusColor, size: 60),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentStimulus ?? '',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_feedbackMessage != null)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _feedbackMessage!,
                            key: ValueKey(_feedbackMessage),
                            style: TextStyle(
                              color: _lastAnswerCorrect == true
                                  ? AppTheme.success
                                  : _lastAnswerCorrect == false
                                      ? AppTheme.error
                                      : const Color(0xFF8E7D7A),
                              fontSize: 13,
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

            const SizedBox(height: 20),

            // ── Marcador ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statChip(Icons.check_circle_outline,
                      '$_correctAnswers', AppTheme.success, 'Aciertos'),
                  Container(width: 1, height: 30, color: AppTheme.surface),
                  _statChip(
                      Icons.cancel_outlined,
                      '${_totalAttempts - _correctAnswers}',
                      AppTheme.error,
                      'Errores'),
                  Container(width: 1, height: 30, color: AppTheme.surface),
                  _statChip(Icons.flag_outlined, '$_totalAttempts',
                      AppTheme.primary, 'Intentos'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Botones de acción ──────────────────────────────────────────
            if (_isPlaying) ...[
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: '✅  Sí coincide',
                      color: AppTheme.success,
                      onPressed: () => _evaluateAnswer(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      label: '❌  No coincide',
                      color: AppTheme.error,
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
                  color: AppTheme.primary,
                  onPressed: () => _startTraining(_difficultyLevel),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    ),
  );
}

  Widget _statChip(
      IconData icon, String value, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8E7D7A), fontSize: 9)),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
