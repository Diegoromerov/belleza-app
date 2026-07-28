// frontend/lib/screens/ideas/results_screen.dart
import 'package:flutter/material.dart';
import '../../models/biometric_result.dart';
import '../../services/biometric_service.dart';
import '../../shared/theme.dart';
import 'product_scanner_screen.dart';
import 'widgets/score_card.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/product_card.dart';
import 'widgets/color_palette.dart';

class ResultsScreen extends StatefulWidget {
  final BiometricResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<ProductDetail> _recommendedProducts = [];
  bool _isLoadingProducts = true;
  bool _productLoadError = false;
  String? _uvRecommendation;
  bool _isLoadingUV = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
    _loadUV();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productLoadError = false;
    });
    try {
      final products = await BiometricService.getRecommendedProducts();
      if (mounted) {
        setState(() {
          _recommendedProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _productLoadError = true;
        });
      }
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _loadUV() async {
    try {
      final uvData = await BiometricService.getUV();
      if (!mounted) return;
      if (uvData != null && uvData['recommendation'] != null) {
        setState(() {
          _uvRecommendation = uvData['recommendation'];
          _isLoadingUV = false;
        });
      } else {
        setState(() => _isLoadingUV = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUV = false);
      }
    }
  }

  String _getHexColorFromSubtono(String subtono) {
    switch (subtono.toLowerCase()) {
      case 'cálido':
        return 'F4A460'; // Sand
      case 'frío':
        return 'B0C4DE'; // Light steel blue
      case 'neutro':
      default:
        return 'D4A574'; // Beige
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pasaporte de Belleza',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Análisis Biométrico de Rostro & Manos',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goBackToIdeas(),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.face_retouching_natural, size: 20),
                text: 'Análisis',
              ),
              Tab(
                icon: Icon(Icons.auto_awesome, size: 20),
                text: 'Recomendación',
              ),
              Tab(
                icon: Icon(Icons.palette_outlined, size: 20),
                text: 'Paleta & Productos',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // PESTAÑA 1: ANÁLISIS FACIAL Y DE MANOS
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CABECERA DE BIENVENIDA CON ESTILO SATINADO
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.terracottaMatteGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎉 Diagnosticado con Éxito',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tu pasaporte personalizado con IA ha sido actualizado.',
                                      style: TextStyle(fontSize: 13, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // SECCIÓN 1: ANÁLISIS FACIAL REESTRUCTURADO
                        _buildFaceSection(),
                        const SizedBox(height: 20),

                        // SECCIÓN 2: ANÁLISIS DE MANOS REESTRUCTURADO
                        _buildHandsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // PESTAÑA 2: RECOMENDACIÓN PERSONALIZADA DE IA Y ADVERTENCIA UV
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RecommendationCard(
                          recommendation: widget.result.recommendation ??
                              'No se generaron recomendaciones específicas.',
                        ),
                        const SizedBox(height: 20),

                        // ADVERTENCIA CLIMÁTICA Y UV
                        if (!_isLoadingUV && _uvRecommendation != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wb_sunny_rounded, color: AppTheme.warning, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '☀️ $_uvRecommendation',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),

                  // PESTAÑA 3: PALETA DE COLORES Y PRODUCTOS RECOMENDADOS
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.result.face != null) ...[
                          ColorPaletteWidget(
                            hexColor: _getHexColorFromSubtono(widget.result.face!.subtono),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildProductsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BARRA FIJA DE ACCIONES INFERIORES
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: _buildActionButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceSection() {
    final face = widget.result.face;
    if (face == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITULO DE SECCIÓN CON BADGE DE EDAD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.face_retouching_natural, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Análisis Facial',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Piel: ${face.bioAge} años',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // GRID 2X2 DE PUNTUACIONES MÉTRICAS
            Row(
              children: [
                Expanded(
                  child: ScoreCard(
                    label: 'Hidratación',
                    value: face.hydration,
                    color: const Color(0xFF2563EB),
                    icon: Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ScoreCard(
                    label: 'Arrugas',
                    value: face.wrinkles,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.auto_awesome,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ScoreCard(
                    label: 'Manchas',
                    value: face.spots,
                    color: const Color(0xFFEF4444),
                    icon: Icons.wb_sunny,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ScoreCard(
                    label: 'Poros',
                    value: face.pores,
                    color: AppTheme.success,
                    icon: Icons.grain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // PILL BADGE DE SUBTONO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Subtono de Piel: ', style: TextStyle(fontSize: 13, color: AppTheme.text)),
                  Text(
                    face.subtono,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandsSection() {
    final hands = widget.result.hands;
    if (hands == null) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITULO DE SECCIÓN CON BADGE DE EDAD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pan_tool_outlined, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Análisis de Manos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.back_hand_outlined, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Manos: ${hands.edadAparente} años',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DIAGNÓSTICOS EN PILL CHIPS
            _buildDiagnosticRow('Manchas solares', hands.manchasSolares, Icons.wb_sunny_outlined),
            _buildDiagnosticRow('Sequedad', hands.sequedad, Icons.water_drop_outlined),
            _buildDiagnosticRow('Cutículas', hands.cuticulas, Icons.clean_hands_outlined),
            _buildDiagnosticRow('Estado de uñas', hands.unas, Icons.back_hand_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, IconData icon) {
    final color = value == 'leve' || value == 'sanas'
        ? AppTheme.success
        : value == 'moderado' || value == 'dañadas'
            ? AppTheme.warning
            : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛍️ Productos Recomendados para tu Piel',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
        ),
        const SizedBox(height: 10),
        if (_isLoadingProducts)
          const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_productLoadError)
          Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.warning, size: 48),
              const SizedBox(height: 8),
              const Text('No pudimos cargar los productos sugeridos.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadRecommendedProducts,
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (_recommendedProducts.isEmpty)
          const Text(
            'No se encontraron productos recomendados en el catálogo en este momento.',
            style: TextStyle(color: Colors.grey),
          )
        else
          Column(
            children: _recommendedProducts
                .map((p) => ProductCard(product: p))
                .toList(),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductScannerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('📷 Escanear producto que ya tengo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.primary,
              elevation: 0,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.roseGoldSatinGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'action': 'apply_filters',
                  'subtono': widget.result.face?.subtono,
                  'nails': widget.result.hands?.unas,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                '✨ Ver Ideas Relacionadas para tu Piel',
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => _goBackToIdeas(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('↩ Volver a Ideas sin filtros', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _goBackToIdeas() {
    Navigator.pop(context, {'action': 'no_filters'});
  }
}
