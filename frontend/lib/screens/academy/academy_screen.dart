// frontend/lib/screens/academy/academy_screen.dart
// Hub principal de GlowAcademy — conecta NBack y Beauty migrados de glowapp_frontend
import 'package:flutter/material.dart';
import 'glow_nback_screen.dart';
import 'glow_beauty_screen.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static const Color _primary    = Color(0xFFC89D93);
  static const Color _background = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories, color: _primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GlowAcademy',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Aprende · Crece · Brilla',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Tarjeta: Juego N-Back ────────────────────────────────────
              _ModuleCard(
                icon: Icons.psychology_outlined,
                color: const Color(0xFF6366F1),
                title: 'Entrenamiento Cognitivo',
                subtitle: 'Juego N‑Back',
                description:
                    'Mejora tu memoria de trabajo y concentración con ejercicios N‑Back de dificultad progresiva.',
                tag: 'NEUROCIENCIA',
                tagColor: const Color(0xFF6366F1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlowNBackScreen()),
                ),
              ),

              const SizedBox(height: 16),

              // ── Tarjeta: Belleza & Educación ─────────────────────────────
              _ModuleCard(
                icon: Icons.spa_outlined,
                color: _primary,
                title: 'Belleza & Educación',
                subtitle: 'Tutoriales y guías',
                description:
                    'Explora rutinas de cuidado de piel, maquillaje, color de cabello, wellness y más.',
                tag: 'BELLEZA',
                tagColor: _primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlowBeautyScreen()),
                ),
              ),

              const Spacer(),

              // ── Footer ───────────────────────────────────────────────────
              Center(
                child: Text(
                  'GlowAcademy • Formación profesional para estilistas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget de tarjeta de módulo ─────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String description;
  final String tag;
  final Color tagColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tag,
    required this.tagColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            // Ícono
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }
}
