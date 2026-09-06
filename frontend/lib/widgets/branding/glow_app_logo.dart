// frontend/lib/widgets/branding/glow_app_logo.dart
import 'package:flutter/material.dart';

/// Componente reutilizable para el logo horizontal principal de GlowApp.
///
/// Utiliza exactamente el asset aprobado:
/// assets/images/branding/glowapp_logo_horizontal_primary.png
///
/// No contiene lógica de navegación, estado, ni funcionalidad comercial.
/// Solo representa el asset de branding.
///
/// El asset tiene una proporción 3:1 (width:height).
/// Este componente garantiza esa proporción explícitamente mediante
/// width = height × 3 para evitar problemas de constraints en AppBar.title.
class GlowAppLogo extends StatelessWidget {
  /// Altura del logo en píxeles lógicos.
  /// El ancho se calcula automáticamente manteniendo la proporción 3:1.
  final double height;

  /// Si se debe aplicar un filtro de color (ej. para modo oscuro/oscuro).
  /// Por defecto null (usa el asset tal cual).
  final Color? colorFilter;

  const GlowAppLogo({
    super.key,
    required this.height,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 3, // Ratio 3:1 del asset (2172 × 724)
      child: Image.asset(
        'images/branding/glowapp_logo_horizontal_primary.webp',
        fit: BoxFit.contain,
        color: colorFilter,
        semanticLabel: 'GlowApp',
        excludeFromSemantics: false,
      ),
    );
  }
}