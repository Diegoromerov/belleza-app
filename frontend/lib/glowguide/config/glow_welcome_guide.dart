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
      videoAssetId: 'assets/glowguide/videos/step_01_welcome.webm',
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
      videoAssetId: 'assets/glowguide/videos/step_02_citas.webm',
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
      videoAssetId: 'assets/glowguide/videos/step_03_glowshop.webm',
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
      videoAssetId: 'assets/glowguide/videos/step_04_glowia.webm',
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
      videoAssetId: 'assets/glowguide/videos/step_05_perfil.webm',
      action: GlowGuideAction.navigate(
        route: '/profile',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'profile_tab',
      nextStepId: 'step_06_aurachat',
      metadata: {'screen': '/profile', 'description': 'User profile'},
    ),

    // PASO 06 — Chat de Aura
    GlowGuideStep(
      id: 'step_06_aurachat',
      order: 5,
      estimatedDurationMs: 7000,
      auraContent: GlowGuideAuraContent(
        text: 'Abre y despliega la barra de búsqueda en la parte superior de Home para consultar servicios y prestadores.',
        position: AuraPosition.center,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_06_aurachat.mp3',
      videoAssetId: 'assets/glowguide/videos/step_06_aurachat.webm',
      action: GlowGuideAction.navigate(
        route: '/home',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'search_bar_target',
      nextStepId: 'step_07_mapa',
      metadata: {'screen': '/home', 'description': 'Aura Chat search bar display'},
    ),

    // PASO 07 — Proveedores en el Mapa
    GlowGuideStep(
      id: 'step_07_mapa',
      order: 6,
      estimatedDurationMs: 8000,
      auraContent: GlowGuideAuraContent(
        text: 'Toca cualquier globo de proveedor en el mapa para ver sus detalles y acceder a su perfil.',
        position: AuraPosition.defaultBottom,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.slide,
      ),
      audioAssetId: 'assets/glowguide/audio/step_07_mapa.mp3',
      videoAssetId: 'assets/glowguide/videos/step_07_mapa.webm',
      action: GlowGuideAction.navigate(
        route: '/home',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'map_provider_target',
      nextStepId: 'step_08_despedida',
      metadata: {'screen': '/home', 'description': 'Map provider details'},
    ),

    // PASO 08 — Menú Lateral y Despedida
    GlowGuideStep(
      id: 'step_08_despedida',
      order: 7,
      estimatedDurationMs: 8000,
      auraContent: GlowGuideAuraContent(
        text: 'Despliega el menú lateral por capas y explora las funciones. ¡Disfruta tu experiencia en GlowApp!',
        position: AuraPosition.center,
        visualState: AuraVisualState.speaking,
        visible: true,
        transitionStyle: AuraTransitionStyle.fade,
      ),
      audioAssetId: 'assets/glowguide/audio/step_08_despedida.mp3',
      videoAssetId: 'assets/glowguide/videos/step_08_despedida.webm',
      action: GlowGuideAction.navigate(
        route: '/home',
        estimatedDurationMs: 2000,
        blocking: true,
      ),
      uiTargetKey: 'side_menu_target',
      nextStepId: null, // Cierre del tour
      metadata: {'screen': '/home', 'description': 'Side menu and farewell'},
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