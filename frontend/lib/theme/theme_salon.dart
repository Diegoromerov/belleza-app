// lib/theme/theme_salon.dart
// Tema visual para la sección Salon siguiendo la línea base de diseño
// *Governanza* + *Soul*.

import 'package:flutter/material.dart';

class SalonTheme {
  // Paleta de colores (ver plan de integración)
  static const Color primary = Color(0xFFD81B60); // rosa vibrante
  static const Color secondary = Color(0xFF4A148C); // violeta profundo
  static const Color background = Color(0xFFFFF5F7); // off‑white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Colors.black87;
  static const Color onSurface = Colors.black87;

  // Tipografía: Inter para cuerpo, Playfair Display para encabezados.
  static const String bodyFontFamily = 'Inter';
  static const String headlineFontFamily = 'PlayfairDisplay';

  static ThemeData get themeData {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onBackground: onBackground,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: headlineFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: onPrimary,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: bodyFontFamily, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: bodyFontFamily, fontSize: 14),
        titleLarge: TextStyle(fontFamily: headlineFontFamily, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: headlineFontFamily, fontSize: 18, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(fontFamily: headlineFontFamily, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: surface,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }
}
