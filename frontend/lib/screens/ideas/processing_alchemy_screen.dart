import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/glow_tokens.dart';
import '../../widgets/glow_glass_card.dart';

/// Pantalla de Alquimia / Procesamiento de Diagnóstico Facial.
/// Muestra un spinner giratorio con destellos dorados y una secuencia animada de textos
/// informativos que simulan el análisis biométrico y cromático.
class ProcessingAlchemyScreen extends StatefulWidget {
  final VoidCallback? onProcessingComplete;

  const ProcessingAlchemyScreen({
    super.key,
    this.onProcessingComplete,
  });

  @override
  State<ProcessingAlchemyScreen> createState() => _ProcessingAlchemyScreenState();
}

class _ProcessingAlchemyScreenState extends State<ProcessingAlchemyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  int _currentTextIndex = 0;
  Timer? _sequenceTimer;

  static const List<String> _analysisMessages = [
    'Analizando subtonos de piel...',
    'Detectando textura y densidad de poros...',
    'Mapeando simetría facial y contraste...',
    'Decodificando tu ADN Cromático...',
    'Sintetizando tu ritual personalizado...',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startTextSequence();
  }

  void _startTextSequence() {
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) return;
      if (_currentTextIndex < _analysisMessages.length - 1) {
        setState(() {
          _currentTextIndex++;
        });
      } else {
        _sequenceTimer?.cancel();
        widget.onProcessingComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _sequenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Spinner Giratorio con Partículas Doradas
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFF3D59B).withValues(alpha: 0.2),
                            const Color(0xFFF3D59B),
                            const Color(0xFFC5A052),
                            const Color(0xFFD4AF37),
                            const Color(0xFFF3D59B).withValues(alpha: 0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC5A052).withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFAF8F5),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFC5A052),
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Card Informativa con Texto Secuencial
                  GlowGlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _analysisMessages[_currentTextIndex],
                        key: ValueKey<int>(_currentTextIndex),
                        style: const TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1A15),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const CircularProgressIndicator(
                    color: Color(0xFFC5A052),
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ALQUIMIA GLOWAPP IA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5A052),
                      letterSpacing: 2.0,
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
