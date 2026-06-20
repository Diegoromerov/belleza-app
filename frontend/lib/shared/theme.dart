import 'package:flutter/material.dart';

class AppTheme {
  static final ValueNotifier<bool> isModernTheme = ValueNotifier<bool>(true);

  static Future<void> loadThemePreference() async {}
  static Future<void> toggleTheme() async {}

  // Colores principales de la marca (GlowApp) - Fijos en Lujo Cálido
  static const Color primary = Color(0xFFC89D93);
  static const Color accent = Color(0xFFC89D93);
  static const Color text = Color(0xFF2D2C2A);
  static const Color background = Color(0xFFFDFBF7);
  static const Color surface = Color(0xFFF7F4EF);

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFCFBEB5), // Ocre arriba corregido (#CFBEB5)
      Color(0xFFCFBEB5), // Se mantiene sólido hasta cubrir la imagen del logo
      Color(0xFFFFF8F0), // Se desvanece a Crema de Seda hacia abajo
    ],
    stops: [
      0.0,
      0.45, // 45% de la pantalla mantiene el color ocre sólido
      1.0,
    ],
  );

  static const LinearGradient roseGoldSatinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8B6AD), // Oro Rosa Claro Satinado
      Color(0xFFB57E74), // Oro Rosa Profundo Satinado
    ],
  );

  static const LinearGradient terracottaMatteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC89D93), // Terracota Suave
      Color(0xFF8C6F65), // Terracota Profundo
    ],
  );

  // Colores de estado contextuales armonizados
  static const Color success = Color(0xFF4A5D4E); // Verde Salvia
  static const Color successBg = Color(0xFFEAEFEA);
  static const Color error = Color(0xFF881337); // Carmín Terroso
  static const Color errorBg = Color(0xFFFDF2F4);
  static const Color warning = Color(0xFFB45309); // Ámbar terroso
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF334155); // Carbón
  static const Color infoBg = Color(0xFFF1F5F9);

  // Sombras premium súper suaves y modernas
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0A5C4E4B),
          blurRadius: 24,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x065C4E4B),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glassShadow => const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 32,
          offset: Offset(0, 16),
        ),
      ];

  // Decoración genérica de inputs
  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: TextStyle(color: Color(0xFFB19F9C), fontSize: 14),
      labelStyle: TextStyle(color: Color(0xFF8E7D7A), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: primary, size: 22),
      suffixIcon: suffixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFEADCD6), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFFEADCD6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  // Especificación de Tipografía de la Guía Maestra
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    color: text,
    height: 1.25,
    fontFamily: 'serif',
    letterSpacing: 0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: text,
    height: 1.25,
    fontFamily: 'serif',
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: text,
    height: 1.25,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: text,
    letterSpacing: 0.5,
  );
}
