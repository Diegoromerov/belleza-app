import 'package:flutter/material.dart';
import '../../models/biometric_result.dart';
import '../../services/biometric_service.dart';
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // En un catálogo real aquí dispararíamos la paginación incrementando la página.
        // Simulamos completado o aviso de scroll
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasaporte de Belleza'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _goBackToIdeas(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎉 ¡Listo! Este es tu Pasaporte de Belleza',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFaceSection(),
            const SizedBox(height: 24),
            _buildHandsSection(),
            const SizedBox(height: 24),
            RecommendationCard(
              recommendation: widget.result.recommendation ??
                  'No se generaron recomendaciones específicas.',
            ),
            const SizedBox(height: 24),
            if (!_isLoadingUV && _uvRecommendation != null) ...[
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '☀️ $_uvRecommendation',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.result.face != null) ...[
              ColorPaletteWidget(
                hexColor: _getHexColorFromSubtono(widget.result.face!.subtono),
              ),
              const SizedBox(height: 24),
            ],
            _buildProductsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Análisis Facial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    color: const Color(0xFF10B981),
                    icon: Icons.grain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.palette, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Subtono: ${face.subtono}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cake_outlined, size: 16, color: Colors.purple),
                        const SizedBox(width: 6),
                        Text(
                          'Edad piel: ${face.bioAge} años',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pan_tool, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Análisis de Manos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDiagnosticRow('Manchas solares', hands.manchasSolares, Icons.wb_sunny_outlined),
            _buildDiagnosticRow('Sequedad', hands.sequedad, Icons.water_drop_outlined),
            _buildDiagnosticRow('Cutículas', hands.cuticulas, Icons.clean_hands),
            _buildDiagnosticRow('Uñas', hands.unas, Icons.back_hand_outlined),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '🖐️ Edad aparente de manos: ${hands.edadAparente} años',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, IconData icon) {
    final color = value == 'leve' || value == 'sanas'
        ? Colors.green[700]!
        : value == 'moderado' || value == 'dañadas'
            ? Colors.orange[800]!
            : Colors.red[700]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
          '🛍️ Productos Sugeridos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isLoadingProducts)
          const Center(child: CircularProgressIndicator())
        else if (_productLoadError)
          Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
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
        ElevatedButton.icon(
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
            backgroundColor: Colors.purple[50],
            foregroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'action': 'apply_filters',
                'subtono': widget.result.face?.subtono,
                'nails': widget.result.hands?.unas,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              '✨ Ver Ideas Relacionadas',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => _goBackToIdeas(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text('↩ Volver a Ideas sin filtros'),
          ),
        ),
      ],
    );
  }

  void _goBackToIdeas() {
    Navigator.pop(context, {'action': 'no_filters'});
  }
}
