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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.face, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Rostro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ScoreCard(
                    label: 'Hidratación',
                    value: face.hydration,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: ScoreCard(
                    label: 'Arrugas',
                    value: face.wrinkles,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ScoreCard(
                    label: 'Manchas',
                    value: face.spots,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: ScoreCard(
                    label: 'Poros',
                    value: face.pores,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Subtono: ${face.subtono}  |  Edad biológica: ${face.bioAge} años',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pan_tool, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Manos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDiagnosticRow('Manchas solares', hands.manchasSolares),
            _buildDiagnosticRow('Sequedad', hands.sequedad),
            _buildDiagnosticRow('Cutículas', hands.cuticulas),
            _buildDiagnosticRow('Uñas', hands.unas),
            const SizedBox(height: 4),
            Text(
              'Edad aparente: ${hands.edadAparente} años',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    final color = value == 'leve' || value == 'sanas'
        ? Colors.green
        : value == 'moderado' || value == 'dañadas'
            ? Colors.orange
            : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
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
