import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';

/// Tema personalizado para el módulo Nia Beauty de GlowApp,
/// construido sobre la paleta de tokens [GlowTokens].
class NiaTheme {
  NiaTheme._();

  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.light(
      primary: GlowTokens.terracota,
      primaryContainer: GlowTokens.terracota.withValues(alpha: 0.15),
      secondary: GlowTokens.roseGold,
      secondaryContainer: GlowTokens.roseGold.withValues(alpha: 0.15),
      surface: GlowTokens.creamSilk,
      error: const Color(0xFFB00020),
      onPrimary: GlowTokens.creamSilk,
      onSecondary: GlowTokens.nightAndean,
      onSurface: GlowTokens.nightAndean,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: GlowTokens.creamSilk,
      fontFamily: GlowTokens.fontInter,
      
      // Configuración de AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: GlowTokens.creamSilk,
        foregroundColor: GlowTokens.nightAndean,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: GlowTokens.fontPlayfairDisplay,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: GlowTokens.nightAndean,
        ),
      ),

      // Configuración de Tarjetas
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: GlowTokens.nightAndean.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: GlowTokens.terracota.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),

      // Botones Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GlowTokens.terracota,
          foregroundColor: GlowTokens.creamSilk,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: GlowTokens.fontInter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones Outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GlowTokens.terracota,
          side: const BorderSide(color: GlowTokens.terracota, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: GlowTokens.fontInter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuración de Textos
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontFamily: GlowTokens.fontPlayfairDisplay,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: GlowTokens.nightAndean,
        ),
        displayMedium: const TextStyle(
          fontFamily: GlowTokens.fontPlayfairDisplay,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: GlowTokens.nightAndean,
        ),
        headlineMedium: const TextStyle(
          fontFamily: GlowTokens.fontPlayfairDisplay,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: GlowTokens.nightAndean,
        ),
        bodyLarge: const TextStyle(
          fontFamily: GlowTokens.fontInter,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: GlowTokens.nightAndean,
        ),
        bodyMedium: TextStyle(
          fontFamily: GlowTokens.fontInter,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: GlowTokens.nightAndean.withValues(alpha: 0.8),
        ),
        labelLarge: const TextStyle(
          fontFamily: GlowTokens.fontInter,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: GlowTokens.nightAndean,
        ),
        bodySmall: const TextStyle(
          fontFamily: GlowTokens.fontJetBrainsMono,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: GlowTokens.nightAndean,
        ),
      ),
    );
  }
}
