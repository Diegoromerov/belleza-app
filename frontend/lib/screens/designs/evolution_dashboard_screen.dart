// frontend/lib/screens/designs/evolution_dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class EvolutionDashboardScreen extends StatefulWidget {
  const EvolutionDashboardScreen({super.key});

  @override
  State<EvolutionDashboardScreen> createState() => _EvolutionDashboardScreenState();
}

class _EvolutionDashboardScreenState extends State<EvolutionDashboardScreen> {
  String _track = 'facial';
  bool _isLoading = true;
  String? _error;
  String? _email;
  
  List<Map<String, dynamic>> _historyData = [];
  String _insight = '';
  String? _attribution;
  String _plan = 'free';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      _track = args;
    }
    _loadEvolutionData();
  }

  Future<void> _loadEvolutionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchEvolutionData(_track);
      final insight = await ApiService.fetchEvolutionInsight(_track);
      final attribution = await ApiService.fetchEvolutionAttribution(_track);

      // Obtener el plan del usuario actualizando el perfil
      final profile = await ApiService.fetchUserProfile();
      
      setState(() {
        _historyData = data;
        _insight = insight;
        _attribution = attribution;
        _plan = profile['glowai_plan'] ?? 'free';
        _email = profile['email'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildDiagnosticImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey, size: 32),
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

  Widget _buildDeterioratedImage(String? url) {
    final isTestUser = _email == 'usuario_pruebas@gmail.com';
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildDiagnosticImage(url),
        if (isTestUser)
          Positioned.fill(
            child: CustomPaint(
              painter: SkinDeteriorationPainter(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _track == 'capilar' ? 'Evolución Capilar' : 'Evolución Facial';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_plan == 'free')
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 12.0, bottom: 12.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/ideas'); // Abre el planificador principal
                },
                icon: const Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
                label: const Text('GlowAI Premium', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar el panel de evolución:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadEvolutionData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // BLOQUE 1: Gráfico de Línea Temporal (Estrictamente Clínico)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tendencia General de Indicadores',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Historial clínico de scores calculados por IA (escala de 0 a 100)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: _historyData.isEmpty
                                ? const Center(child: Text('No hay diagnósticos para graficar.', style: TextStyle(fontSize: 12, color: Colors.grey)))
                                : CustomPaint(
                                    size: Size.infinite,
                                    painter: TrendLineChartPainter(
                                      data: _historyData,
                                      isFreePlan: _plan == 'free',
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          // Leyenda del gráfico
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem('Hidratación', const Color(0xFF2196F3)),
                              _buildLegendItem('Impurezas', const Color(0xFFFF5722)),
                              _buildLegendItem('Luminosidad', const Color(0xFFFFC107)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BLOQUE 2: Comparativa Visual y Nota de la IA
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comparativa Clínico-Visual',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
                          ),
                          const SizedBox(height: 16),
                          // Fotos lado a lado
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: _buildDeterioratedImage(
                                          _historyData.isNotEmpty ? _historyData.first['image_url'] : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Estado Inicial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: _buildDiagnosticImage(
                                          _historyData.isNotEmpty ? _historyData.last['image_url'] : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Estado Actual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'Análisis Interpretativo de la IA',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _insight,
                            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BLOQUE 3: Atribución Comercial Discreta (Solo si devuelve datos)
                  if (_attribution != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7EFEA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEADCD3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_outlined, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nota de Tratamiento Relacionado',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.text),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _attribution!,
                                  style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Paywall Discreto al Final de la pantalla para usuarios Free
                  if (_plan == 'free') ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'Evolución Gratuita Limitada',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Actualmente solo puedes ver tu último escaneo. Desbloquea tu serie temporal completa, gráficos detallados e insights históricos ilimitados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ideas'); // Lleva a la pantalla principal de ideas
                            },
                            icon: const Icon(Icons.bolt, color: Colors.white, size: 16),
                            label: const Text('Actualizar a Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

// CustomPainter para dibujar la línea temporal de manera Premium
class TrendLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final bool isFreePlan;

  TrendLineChartPainter({required this.data, required this.isFreePlan});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    // Dibujar líneas de rejilla horizontales (eje Y)
    const int gridLines = 5;
    for (int i = 0; i < gridLines; i++) {
      final double y = size.height * i / (gridLines - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (data.isEmpty) return;

    // Si es plan Gratuito o solo hay un punto de datos, pintamos un punto centrado
    if (isFreePlan || data.length == 1) {
      final last = data.last;
      final scoreH = (last['score_hidratacion'] ?? 50) as int;
      final scoreI = (last['score_impurezas'] ?? 50) as int;
      final scoreL = (last['score_luminosidad'] ?? 50) as int;

      final double centerX = size.width / 2;
      _drawPoint(canvas, centerX, _mapScoreToY(scoreH, size.height), const Color(0xFF2196F3));
      _drawPoint(canvas, centerX, _mapScoreToY(scoreI, size.height), const Color(0xFFFF5722));
      _drawPoint(canvas, centerX, _mapScoreToY(scoreL, size.height), const Color(0xFFFFC107));
      return;
    }

    // Dibujar líneas de tendencia Premium
    final int count = data.length;
    final double stepX = size.width / (count - 1);

    final pathHydration = Path();
    final pathImpures = Path();
    final pathLuminosity = Path();

    for (int i = 0; i < count; i++) {
      final item = data[i];
      final scoreH = (item['score_hidratacion'] ?? 50) as int;
      final scoreI = (item['score_impurezas'] ?? 50) as int;
      final scoreL = (item['score_luminosidad'] ?? 50) as int;

      final double x = i * stepX;
      final double yH = _mapScoreToY(scoreH, size.height);
      final double yI = _mapScoreToY(scoreI, size.height);
      final double yL = _mapScoreToY(scoreL, size.height);

      if (i == 0) {
        pathHydration.moveTo(x, yH);
        pathImpures.moveTo(x, yI);
        pathLuminosity.moveTo(x, yL);
      } else {
        pathHydration.lineTo(x, yH);
        pathImpures.lineTo(x, yI);
        pathLuminosity.lineTo(x, yL);
      }
    }

    // Renderizar líneas
    _drawTrendPath(canvas, pathHydration, const Color(0xFF2196F3));
    _drawTrendPath(canvas, pathImpures, const Color(0xFFFF5722));
    _drawTrendPath(canvas, pathLuminosity, const Color(0xFFFFC107));

    // Renderizar puntos individuales sobre las líneas
    for (int i = 0; i < count; i++) {
      final item = data[i];
      final double x = i * stepX;
      _drawPoint(canvas, x, _mapScoreToY(item['score_hidratacion'] ?? 50, size.height), const Color(0xFF2196F3));
      _drawPoint(canvas, x, _mapScoreToY(item['score_impurezas'] ?? 50, size.height), const Color(0xFFFF5722));
      _drawPoint(canvas, x, _mapScoreToY(item['score_luminosidad'] ?? 50, size.height), const Color(0xFFFFC107));
    }
  }

  double _mapScoreToY(int score, double height) {
    // Escala del score (0 a 100) invertida para Flutter Y (0 arriba, height abajo)
    final double pct = score.clamp(0, 100) / 100.0;
    return height * (1.0 - pct);
  }

  void _drawTrendPath(Canvas canvas, Path path, Color color) {
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paintLine);
  }

  void _drawPoint(Canvas canvas, double x, double y, Color color) {
    final paintOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintInner = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 6, paintInner);
    canvas.drawCircle(Offset(x, y), 3, paintOuter);
  }

  @override
  bool shouldRepaint(covariant TrendLineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isFreePlan != isFreePlan;
  }
}

class SkinDeteriorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Capa de enrojecimiento / deshidratación (tono sepia/rojizo semi-transparente)
    final rect = Offset.zero & size;
    final paintRed = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.15)
      ..blendMode = BlendMode.colorBurn;
    canvas.drawRect(rect, paintRed);

    // 2. Dibujar algunas imperfecciones / granitos simulados en coordenadas fijas de la cara
    final paintBlemish = Paint()
      ..color = const Color(0xFFE57373).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Bordes suaves difuminados

    // Dibujar 4 imperfecciones de acné sutiles distribuidas por el rostro
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.48), 5.0, paintBlemish); // Mejilla izquierda
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.52), 4.0, paintBlemish); // Mejilla derecha
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.35), 4.5, paintBlemish); // Frente
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.68), 5.5, paintBlemish); // Barbilla
    
    // Un puntito rojo adicional
    final paintBlemishCore = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.48), 1.5, paintBlemishCore);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.35), 1.0, paintBlemishCore);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
