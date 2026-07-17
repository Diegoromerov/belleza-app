import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowTheme {
  // Primary and secondary brand colors
  static const Color primary = Color(0xFF4F46E5); // Indigo-600
  static const Color secondary = Color(0xFF6366F1); // Indigo-500

  // Dark theme baseline with glassmorphism-friendly background
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: primary,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
