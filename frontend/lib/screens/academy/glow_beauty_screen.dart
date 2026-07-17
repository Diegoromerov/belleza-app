// frontend/lib/screens/academy/glow_beauty_screen.dart
// BeautyScreen migrada de glowapp_frontend — adaptada a StatefulWidget puro (sin Riverpod)
import 'package:flutter/material.dart';
import 'glow_glass_card.dart';

// ─── Constantes de tema ───────────────────────────────────────────────────────
const Color _kBackground = Color(0xFF0F172A);
const Color _kPrimary    = Color(0xFFC89D93);

// ─── Modelo de item (portado de beauty_provider.dart) ────────────────────────
class _BeautyItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _BeautyItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Lista estática de contenidos educativos (portada de BeautyProvider)
const List<_BeautyItem> _beautyItems = [
  _BeautyItem(
    title: 'Cuidado de la piel',
    description: 'Rutinas y tips para una piel radiante.',
    icon: Icons.spa,
    color: Color(0xFFC89D93),
  ),
  _BeautyItem(
    title: 'Maquillaje básico',
    description: 'Aprende los fundamentos del maquillaje.',
    icon: Icons.brush,
    color: Color(0xFFA855F7),
  ),
  _BeautyItem(
    title: 'Color de cabello',
    description: 'Tendencias y cuidados del color.',
    icon: Icons.palette,
    color: Color(0xFFF59E0B),
  ),
  _BeautyItem(
    title: 'Wellness',
    description: 'Ejercicio y nutrición para la belleza interior.',
    icon: Icons.self_improvement,
    color: Color(0xFF22C55E),
  ),
  _BeautyItem(
    title: 'Skincare avanzado',
    description: 'Ingredientes activos y protocolos profesionales.',
    icon: Icons.science,
    color: Color(0xFF3B82F6),
  ),
  _BeautyItem(
    title: 'Uñas & nail art',
    description: 'Técnicas de manicura y diseño artístico.',
    icon: Icons.back_hand,
    color: Color(0xFFEC4899),
  ),
];

// ─── Pantalla principal ───────────────────────────────────────────────────────
class GlowBeautyScreen extends StatelessWidget {
  const GlowBeautyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Belleza & Educación',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _kBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              'Aprende, mejora y brilla ✨',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ),

          // ── Grid de tarjetas ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: _beautyItems.length,
                itemBuilder: (context, index) {
                  final item = _beautyItems[index];
                  return GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Próximamente: ${item.title}'),
                          backgroundColor: _kPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: GlowGlassCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: item.color, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 100), // espacio para menú inferior flotante
        ],
      ),
    );
  }
}
