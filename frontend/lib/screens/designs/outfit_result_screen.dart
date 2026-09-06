// frontend/lib/screens/designs/outfit_result_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class OutfitResultScreen extends StatefulWidget {
  const OutfitResultScreen({super.key});

  @override
  State<OutfitResultScreen> createState() => _OutfitResultScreenState();
}

class _OutfitResultScreenState extends State<OutfitResultScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _matchingGarments = [];
  List<Map<String, dynamic>> _referenceImages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Usar Future.microtask para diferir setState síncronos en didChangeDependencies y evitar bloqueos en Flutter Web
    Future.microtask(() => _loadOutfitDetails());
  }

  Future<void> _loadOutfitDetails() async {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _error = 'No se recibieron datos de combinación válidos.';
      });
      return;
    }

    final List<dynamic> ids = args['prendas_ids'] ?? [];
    final String query = args['pinterest_query'] ?? 'outfit casual moda';

    try {
      // 1. Cargar todas las prendas del clóset para cruzarlas por ID
      final wardrobe = await ApiService.fetchWardrobe();
      final matched = wardrobe.where((item) => ids.contains(item['id'])).toList();

      // 2. Cargar imágenes de referencia de Pinterest usando la query de Gemini
      final refs = await ApiService.fetchDesignIdeas(query);

      setState(() {
        _matchingGarments = matched;
        _referenceImages = refs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  ImageProvider _getImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage('images/logo_maestro_v5.webp');
    }
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    if (url.startsWith('images/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is! Map<String, dynamic>) {
      return Scaffold(
        appBar: AppBar(title: const Text('Outfit IA')),
        body: const Center(child: Text('Datos del outfit no encontrados.')),
      );
    }

    final String name = args['nombre'] ?? 'Mi Look Especial';
    final String suggestion = args['sugerencia_texto'] ?? '';
    final String estilo = args['estilo'] ?? 'casual';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Mi Outfit Sugerido',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A052)))
              : _error != null
                  ? Center(child: Text('Error al procesar outfit: $_error'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado del Look
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              estilo.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 11),
                            ),
                            const Text('GlowStyle Personal Stylist ✨',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.text, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 20),

                      // Collage del look (las prendas reales combinadas)
                      const Text(
                        'Prendas de tu Clóset Seleccionadas:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _matchingGarments.length,
                          itemBuilder: (context, index) {
                            final item = _matchingGarments[index];
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF3EAE8), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image(
                                        image: _getImageProvider(item['image_url']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item['nombre'] ?? 'Prenda',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.text),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Explicación de la IA
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF3EAE8), width: 1.2),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  '¿Por qué combina este outfit?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.text),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            Text(
                              suggestion,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Galería de Referencia (Pinterest Lookbook)
                      if (_referenceImages.isNotEmpty) ...[
                        const Text(
                          'Visualiza el Estilo (Lookbook de Referencia):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _referenceImages.length.clamp(0, 4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final ref = _referenceImages[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                ref['image'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: Colors.grey.shade200);
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Botones de acción
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
                            final text = '¡Mira el outfit que me recomendó la IA de GlowStyle! Look: $name. Explicación: $suggestion';
                            await Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 Combinación de outfit copiado al portapapeles.'),
                                backgroundColor: Color(0xFF1F1A15),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, color: Color(0xFF1F1A15)),
                          label: const Text(
                            'Compartir Outfit con Amigos',
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
