// frontend/lib/screens/academy/glow_color_screen.dart
// Pantalla de detalle para el curso "Colorimetría Capilar" en GlowAcademy
import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class GlowColorScreen extends StatelessWidget {
  const GlowColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Colorimetría Capilar',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text, fontSize: 17),
        ),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Header descriptivo
            Text(
              'Domina el arte del color en el cabello',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Este curso profesional cubre fundamentos científicos, técnicas avanzadas de coloración, decoloración y corrección de tonos.\n\nAprende paso a paso y conviértete en un colorista certificado.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E7D7A),
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
            // Placeholder de listado de módulos (se pueden añadir widgets más detallados)
            Text(
              'Módulos del curso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 12),
            // Cada módulo como tarjeta simple
            _ModuleCard(title: 'Fundamentos de Colorimetría'),
            SizedBox(height: 12),
            _ModuleCard(title: 'Técnicas de Aplicación'),
            SizedBox(height: 12),
            _ModuleCard(title: 'Nivelación y Matización'),
            SizedBox(height: 12),
            _ModuleCard(title: 'Técnicas Avanzadas'),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de módulo reutilizable dentro de la pantalla de curso
class _ModuleCard extends StatelessWidget {
  final String title;
  const _ModuleCard({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.palette_outlined, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.text),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 13, color: AppTheme.primary),
        ],
      ),
    );
  }
}
