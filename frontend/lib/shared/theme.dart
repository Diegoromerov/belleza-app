// frontend/lib/shared/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales de la marca (Lujo Terroso)
  static const Color primary = Color(0xFFC89D93);
  static const Color primaryLight = Color(0xFFF5EBE6);
  static const Color background = Color(0xFFFAF6F5);
  static const Color surface = Colors.white;

  // Colores de estado contextuales armonizados
  static const Color success = Color(0xFF4A5D4E); // Verde Salvia
  static const Color successBg = Color(0xFFEAEFEA);
  static const Color error = Color(0xFF881337); // Carmín Terroso / Borgoña
  static const Color errorBg = Color(0xFFFDF2F4);
  static const Color warning = Color(0xFFB45309); // Terracota / Ámbar terroso
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF334155); // Pizarra / Carbón
  static const Color infoBg = Color(0xFFF1F5F9);

  // Sombras premium suaves
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F8E7D7A),
          blurRadius: 20,
          offset: Offset(0, 8),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x088E7D7A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  // Decoración genérica de inputs
  static InputDecoration inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? labelText,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: primary),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: primaryLight.withAlpha(128),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
