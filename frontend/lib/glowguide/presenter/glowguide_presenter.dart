// lib/glowguide/presenter/glowguide_presenter.dart
// Presentador visual para GlowGuide
// I1: Foundation Repair - usa AuraPosition canónico, Semantics, sin GlowGuidePosition.

import 'package:flutter/material.dart';
import '../engine/glowguide_engine.dart';
import '../state/glowguide_state.dart';
import '../model/glowguide_step.dart';

/// Ruta del asset de Aura Canónica
const String auraCanonicalAssetPath = 'assets/glowguide/aura_canonical.webp';

/// Callback para cuando el usuario interactúa con el presenter
typedef GlowGuidePresenterCallback = void Function(GlowGuidePresenterAction action);

/// Acciones que el presenter puede solicitar al Engine
enum GlowGuidePresenterAction {
  next,
  previous,
  dismiss,
  replay,
  pause,
  resume,
}

/// Presentador visual de GlowGuide
/// Recibe estado del Engine y define cómo se presenta visualmente.
/// SOLO responsabilidad visual: rendering, transiciones, visibilidad, semantics.
/// NO posee: Navigator, AudioPlayer, SharedPreferences, business logic.
class GlowGuidePresenter extends StatefulWidget {
  final GlowGuideEngine engine;
  final GlowGuidePresenterCallback? onAction;
  final Widget? child; // Para testing: widget hijo opcional

  const GlowGuidePresenter({
    super.key,
    required this.engine,
    this.onAction,
    this.child,
  });

  @override
  State<GlowGuidePresenter> createState() => _GlowGuidePresenterState();
}

class _GlowGuidePresenterState extends State<GlowGuidePresenter> with WidgetsBindingObserver {
  GlowGuideState _currentState = GlowGuideState.initial;
  GlowGuideStep? _currentStep;

  @override
  void initState() {
    super.initState();
    _currentState = widget.engine.state;
    _currentStep = widget.engine.currentStep;
    widget.engine.addListener(_onEngineStateChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onEngineStateChanged(GlowGuideState newState) {
    if (mounted) {
      setState(() {
        _currentState = newState;
        _currentStep = widget.engine.currentStep;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Notificar al engine de cambios de lifecycle si es necesario
    // El engine maneja pause/resume internamente
  }

  @override
  Widget build(BuildContext context) {
    // No mostrar nada si el engine no está activo ni completado
    if (!widget.engine.isActive && !widget.engine.isCompleted) {
      return widget.child ?? const SizedBox.shrink();
    }

    return _buildAuraCanonical(context);
  }

  Widget _buildAuraCanonical(BuildContext context) {
    // COMPLETED, DISMISSED, IDLE = hidden
    // Solo PLAYING, EXECUTING_ACTION, PAUSED = visible
    if (!_isVisibleState(_currentState.status)) {
      return const SizedBox.shrink();
    }

    if (_currentStep == null) {
      return const SizedBox.shrink();
    }

    final auraContent = _currentStep!.auraContent;
    if (!auraContent.visible) {
      return const SizedBox.shrink();
    }

    final position = auraContent.position;
    final screenSize = MediaQuery.of(context).size;
    final auraSize = screenSize.width * 0.35;

    // Convertir AuraPosition normalizado (x,y ∈ [0,1]) a Alignment (-1..1)
    // con un margen inferior para respetar safe areas y no cubrir nav/FAB.
    final alignment = _calculateAlignment(position);

    // Respetar reduced motion
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final stepNumber = (_currentStep!.order) + 1;
    final totalSteps = widget.engine.totalSteps > 0 ? widget.engine.totalSteps : 6;

    return AnimatedSwitcher(
      duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        if (disableAnimations) return child;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: SafeArea(
        key: ValueKey<GlowGuideStatus>(_currentState.status),
        child: Align(
          alignment: alignment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tarjeta Interactiva de Aura (Mensaje + Controles)
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1A15).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC5A052), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC5A052).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFFC5A052), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'AURA • PASO $stepNumber DE $totalSteps',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC5A052),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => widget.onAction?.call(GlowGuidePresenterAction.dismiss),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      auraContent.text,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => widget.onAction?.call(GlowGuidePresenterAction.dismiss),
                          child: const Text(
                            'Omitir',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5A052),
                            foregroundColor: const Color(0xFF1F1A15),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: () => widget.onAction?.call(GlowGuidePresenterAction.next),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: Text(
                            stepNumber == totalSteps ? 'Finalizar' : 'Siguiente',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Imagen Canónica de Aura
              SizedBox(
                width: auraSize,
                height: auraSize * 0.9,
                child: Image.asset(
                  auraCanonicalAssetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convierte AuraPosition (x,y normalizados) a Alignment Flutter.
  /// AuraPosition: x=0→izquierda..1→derecha, y=0→arriba..1→abajo.
  /// Alignment: (-1,-1)=arriba-izq .. (1,1)=abajo-der.
  /// Se aplica un ligero margen inferior para que defaultBottom no
  /// cubra la navegación inferior ni el FAB.
  Alignment _calculateAlignment(AuraPosition? position) {
    final x = (position?.x ?? AuraPosition.defaultBottom.x).clamp(0.0, 1.0);
    final y = (position?.y ?? AuraPosition.defaultBottom.y).clamp(0.0, 1.0);
    // Mapear [0,1] → [-1,1]
    final ax = (x * 2.0) - 1.0;
    final ay = (y * 2.0) - 1.0;
    // Margen interior: alejar ligeramente el aura del borde inferior/izquierdo
    // para evitar solapamiento con controles críticos del Home.
    return Alignment(ax * 0.9, ay * 0.9);
  }

  /// Determina si el estado debe mostrar UI visual
  /// playing, executingAction, paused = visible
  /// completed, dismissed, idle, starting = hidden
  bool _isVisibleState(GlowGuideStatus status) {
    return status == GlowGuideStatus.playing ||
           status == GlowGuideStatus.executingAction ||
           status == GlowGuideStatus.paused;
  }
}

/// Extension para saber si un estado debe mostrar UI (legacy compat)
extension GlowGuideStatusExtension on GlowGuideStatus {
  @Deprecated('Usar _isVisibleState en presenter. completed ya no es visible.')
  bool get isActiveAndVisible {
    return this == GlowGuideStatus.playing ||
           this == GlowGuideStatus.executingAction ||
           this == GlowGuideStatus.paused;
  }
}