// frontend/lib/screens/academy/academy_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA LIMPIA — Lista para migración de GlowAcademy
// El contenido anterior fue archivado antes de esta limpieza.
// Próximo paso: migrar NBackScreen, BeautyScreen y TrainingScreen
// desde glowapp_frontend/ adaptados a StatefulWidget (sin Riverpod).
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static const Color _primary = Color(0xFFC89D93);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 64,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GlowAcademy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
