// frontend/lib/screens/designs/glowup_card_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class GlowUpCardScreen extends StatefulWidget {
  const GlowUpCardScreen({super.key});

  @override
  State<GlowUpCardScreen> createState() => _GlowUpCardScreenState();
}

class _GlowUpCardScreenState extends State<GlowUpCardScreen> {
  String? _favoriteUrl;
  String _track = 'piel';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _cardData;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final route = ModalRoute.of(context);
      if (route != null && route.settings.arguments is Map<String, dynamic>) {
        final args = route.settings.arguments as Map<String, dynamic>;
        _favoriteUrl = args['favorite_url'];
        _track = args['track'] ?? 'piel';
      }
      _initialized = true;
      Future.microtask(() => _generateCard());
    }
  }

  Future<void> _generateCard() async {
    if (_favoriteUrl == null) {
      setState(() {
        _error = 'URL del diseño favorito no proporcionada.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.generateGlowUpCard(_favoriteUrl!, _track);
      setState(() {
        _cardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCardImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey, size: 48),
      );
    }
    if (url.startsWith('data:')) {
      try {
        final parts = url.split(',');
        if (parts.length > 1) {
          return Image.memory(
            base64Decode(parts.last),
            fit: BoxFit.cover,
          );
        }
      } catch (e) {
        debugPrint('Error parsing base64 image: $e');
      }
    }
    return Image.network(
      ApiService.normalizeUrl(url),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Mi Tarjeta Glow Up', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      // 402 / Suscripción requerida
      final is402 = _error!.contains('402') || _error!.contains('glowai_plan');
      return Scaffold(
        backgroundColor: const Color(0xFFFCF9F7),
        appBar: AppBar(
          title: const Text('GlowAI Premium', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.orange.shade200, width: 1.5),
              ),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.orange, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Característica Premium',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.text),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      is402
                          ? 'La Tarjeta Glow Up combina tu diseño favorito con tus progresos reales de hidratación e impurezas. Disponible exclusivamente para usuarios Premium.'
                          : 'Ocurrió un error al generar la tarjeta:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        // Navega al panel de ideas para suscribirse
                        Navigator.pushNamed(context, '/ideas');
                      },
                      child: const Text('Obtener GlowAI Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final card = _cardData!;
    final name = card['user_name'] ?? 'Usuario GlowApp';
    final progress = card['progress_metric'] ?? '+0%';
    final metricName = card['metric_name'] ?? 'Hidratación';
    final imageUrl = card['favorite_image_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: const Text(
          'Mi Tarjeta Glow Up',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¡Listo para presumir tu cambio!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.text),
            ),
            const SizedBox(height: 6),
            const Text(
              'Esta tarjeta une el estilo que elegiste con tus mejoras reales en la piel.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 28),

            // CONTENEDOR DE LA TARJETA (GLOW UP CARD)
            Center(
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFF3EAE8), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header de la tarjeta
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primary.withValues(alpha: 0.04),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                                ),
                                const Text(
                                  'Glow Up Diagnosticado',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Imagen del Diseño de uñas
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: _buildCardImage(imageUrl),
                    ),

                    // Información del progreso clínico
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Progreso Clínico',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Incremento en la salud cutánea ($metricName).',
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              progress,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pie de la tarjeta
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      color: Colors.grey.shade50,
                      alignment: Alignment.center,
                      child: const Text(
                        '🌿 Diseñado con GlowAI Planner',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // BOTÓN COMPARTIR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () async {
                  final shareText = '¡Mira mi tarjeta Glow Up de GlowApp! Diseño favorito con un progreso de $progress en mi $metricName.';
                  await Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Tarjeta Glow Up copiada al portapapeles.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Compartir tarjeta Glow Up', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
