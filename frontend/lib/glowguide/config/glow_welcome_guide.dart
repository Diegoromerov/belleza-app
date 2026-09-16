// lib/glowguide/config/glow_welcome_guide.dart
// Configuración declarativa de la guía de bienvenida: glow_welcome_v1
// Contiene los 6 pasos canónicos con textos, acciones y referencias de audio

import '../model/glowguide_step.dart';
import '../model/glowguide_action.dart';

/// Configuración de la guía de bienvenida oficial de GlowApp
/// ID: glow_welcome_v1
/// 6 pasos: Welcome → Citas → GlowShop → Glow IA+ → Perfil → Close
class GlowWelcomeGuide {
  /// Identificador único de esta guía
  static const String guideId = 'glow_welcome_v1';

  /// Nombre legible
  static const String guideName = 'GlowApp Welcome Guide v1';

  /// Versión de la configuración
  static const int version = 1;

  /// Pasos declarativos de la guía
  static final List<GlowGuideStep> steps = [
    // PASO 01 — Welcome
    GlowGuideStep(
      id: 'step_01_welcome',
      order: 0,
      estimatedDurationMs: 5000,
      auraContent: GlowGuideAuraContent(
        text: 'Hola, soy Aura. Te voy a mostrar rápidamente cómo funciona GlowApp.',
        position: AuraPosition.center,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.fade,
      ),
      audioAssetId: 'assets/glowguide/audio/step_01_welcome.mp3',
      action: null, // Sin acción en welcome
      uiTargetKey: null,
      nextStepId: 'step_02_citas',
      metadata: {'screen': '/home', 'description': 'Welcome screen'},
    ),

    // PASO 02 — Citas
    GlowGuideStep(
      id: 'step_02_citas',
      order: 1,
      estimatedDurationMs: 6000,
      auraContent: GlowGuideAuraContent(
        text: 'En Citas podrás consultar y gestionar tus citas de manera sencilla.',
        position: AuraPosition.defaultBottom,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_02_citas.mp3',
      action: GlowGuideAction.navigate(
        route: '/client-bookings',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'appointments_tab',
      nextStepId: 'step_03_glowshop',
      metadata: {'screen': '/client-bookings', 'description': 'Appointments management'},
    ),

    // PASO 03 — GlowShop
    GlowGuideStep(
      id: 'step_03_glowshop',
      order: 2,
      estimatedDurationMs: 6000,
      auraContent: GlowGuideAuraContent(
        text: 'En GlowShop encontrarás los productos y servicios disponibles.',
        position: AuraPosition.defaultBottom,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_03_glowshop.mp3',
      action: GlowGuideAction.navigate(
        route: '/store',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'store_tab',
      nextStepId: 'step_04_glowia',
      metadata: {'screen': '/store', 'description': 'Products and services'},
    ),

    // PASO 04 — Glow IA+
    GlowGuideStep(
      id: 'step_04_glowia',
      order: 3,
      estimatedDurationMs: 7000,
      auraContent: GlowGuideAuraContent(
        text: 'Con Glow IA+ tendrás asistencia inteligente dentro de GlowApp.',
        position: AuraPosition.defaultBottom,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_04_glowia.mp3',
      action: GlowGuideAction.navigate(
        route: '/ideas',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'ai_tab',
      nextStepId: 'step_05_perfil',
      metadata: {'screen': '/ideas', 'description': 'AI assistant'},
    ),

    // PASO 05 — Perfil
    GlowGuideStep(
      id: 'step_05_perfil',
      order: 4,
      estimatedDurationMs: 6000,
      auraContent: GlowGuideAuraContent(
        text: 'Desde tu Perfil puedes gestionar tu información y tus preferencias.',
        position: AuraPosition.defaultBottom,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_05_perfil.mp3',
      action: GlowGuideAction.navigate(
        route: '/profile',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'profile_tab',
      nextStepId: 'step_06_close',
      metadata: {'screen': '/profile', 'description': 'User profile'},
    ),

    // PASO 06 — Close
    GlowGuideStep(
      id: 'step_06_close',
      order: 5,
      estimatedDurationMs: 4000,
      auraContent: GlowGuideAuraContent(
        text: 'Eso es todo. Ya estás listo para disfrutar GlowApp.',
        position: AuraPosition.center,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.fade,
      ),
      audioAssetId: 'assets/glowguide/audio/step_06_close.mp3',
      action: GlowGuideAction.navigate(
        route: '/home',
        estimatedDurationMs: 1500,
        blocking: true,
      ),
      uiTargetKey: null,
      nextStepId: null, // Último paso
      metadata: {'screen': '/home', 'description': 'Return to home'},
    ),
  ];

  /// Obtiene un paso por ID
  static GlowGuideStep? getStep(String stepId) {
    try {
      return steps.firstWhere((s) => s.id == stepId);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el primer paso
  static GlowGuideStep get firstStep => steps.first;

  /// Obtiene el último paso
  static GlowGuideStep get lastStep => steps.last;

  /// Total de pasos
  static int get totalSteps => steps.length;
}