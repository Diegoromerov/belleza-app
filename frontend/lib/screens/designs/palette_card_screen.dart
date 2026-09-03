// frontend/lib/screens/designs/palette_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme.dart';

class PaletteCardScreen extends StatelessWidget {
  const PaletteCardScreen({super.key});

  Color _parseHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildCategoryGrid(List<dynamic> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final String name = item['nombre'] ?? '';
        final String hex = item['hex'] ?? '#CCCCCC';
        final color = _parseHex(hex);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3EAE8), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.text),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hex,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is! Map<String, dynamic>) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Paleta Cromática')),
        body: const Center(child: Text('No hay datos disponibles para esta paleta.')),
      );
    }

    final String undertone = args['undertone'] ?? args['skin_undertone'] ?? 'No detectado';
    final String explanation = args['explanation'] ?? '';
    final recommendedColors = args['recommended_colors'] as List<dynamic>? ?? [];
    final fullPalette = args['paleta_completa'] as Map<String, dynamic>?;

    final bool isPremium = fullPalette != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Mi Paleta Cromática',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFFAF8F5),
        foregroundColor: const Color(0xFF1F1A15),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen de Subtono
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFEADCD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subtono de Piel', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    undertone,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.87), fontSize: 11.5, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Paleta Básica (Colores recomendados rápidos)
            const Text(
              'Colores Clave Recomendados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.text),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedColors.length,
                itemBuilder: (context, index) {
                  final colorName = recommendedColors[index] as String;
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3EAE8), width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      colorName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.text),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Si es PREMIUM, mostrar paleta completa por categorías
            if (isPremium) ...[
              const Text(
                'Mi Paleta de Temporada Completa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
              ),
              const SizedBox(height: 16),

              if (fullPalette['ropa'] != null) ...[
                const Row(
                  children: [
                    Icon(Icons.checkroom_rounded, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Paleta de Prendas y Ropa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.text)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategoryGrid(fullPalette['ropa'] as List<dynamic>),
                const SizedBox(height: 24),
              ],

              if (fullPalette['maquillaje'] != null) ...[
                const Row(
                  children: [
                    Icon(Icons.brush_rounded, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Paleta de Maquillaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.text)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategoryGrid(fullPalette['maquillaje'] as List<dynamic>),
                const SizedBox(height: 24),
              ],

              if (fullPalette['tinte_cabello'] != null) ...[
                const Row(
                  children: [
                    Icon(Icons.face_rounded, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Paleta de Tinte de Cabello', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.text)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategoryGrid(fullPalette['tinte_cabello'] as List<dynamic>),
                const SizedBox(height: 24),
              ],
            ] else ...[
              // Si es FREE, mostrar paywall discreto
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.amber.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.orange, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Desbloquea tu Paleta Completa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Obtén el análisis cromático extendido con paletas específicas para tu Ropa, Maquillaje y Tintes de Cabello. Disponible en GlowAI Premium.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          // Abre el bottom sheet de premium de manicure ideas
                          Navigator.pop(context);
                        },
                        child: const Text('Obtener GlowAI Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // BOTÓN COMPARTIR
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5A052).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: const Color(0xFF1F1A15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final shareText = '¡Mira mi diagnóstico de Colorimetría de GlowApp! Mi subtono es: $undertone. Colores clave: ${recommendedColors.join(", ")}.';
                  await Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Resumen de paleta cromática copiado al portapapeles.'),
                      backgroundColor: Color(0xFF1F1A15),
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF1F1A15)),
                label: const Text(
                  'Compartir mi Paleta',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1A15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
