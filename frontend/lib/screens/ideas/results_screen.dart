// frontend/lib/screens/ideas/results_screen.dart
import 'package:flutter/material.dart';
import '../../models/biometric_result.dart';
import '../../services/biometric_service.dart';
import 'glowstore_recipe_screen.dart';
import 'product_scanner_screen.dart';
import 'vto_live_screen.dart';
import 'nail_vto_screen.dart';
import 'makeup_lookbook_screen.dart';
import 'widgets/score_card.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/product_card.dart';
import 'widgets/color_palette.dart';
import '../../services/social_share_service.dart';

// ---------------------------------------------------------------------------
// Tokens de marca para esta pantalla estilo Pasaporte Editorial
// ---------------------------------------------------------------------------
class _PassportColors {
  static const primary = Color(0xFFC5A052); // Haute Joaillerie Gold 871
  static const primaryLight = Color(0xFFF3D59B);
  static const background = Color(0xFFFAF8F5);
  static const surface = Colors.white;
  static const textAccent = Color(0xFF1F1A15);
  static const textEyebrow = Color(0xFF8E7D7A);
}

enum _PassportFilter { rostro, manos }

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

  _PassportFilter _filter = _PassportFilter.rostro;

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
      if (mounted) setState(() => _isLoadingUV = false);
    }
  }

  String _getHexColorFromSubtono(String subtono) {
    switch (subtono.toLowerCase()) {
      case 'cálido':
        return 'F4A460';
      case 'frío':
        return 'B0C4DE';
      case 'neutro':
      default:
        return 'D4A574';
    }
  }

  void _goBackToIdeas() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final face = widget.result.face;
    final hands = widget.result.hands;

    return Scaffold(
      backgroundColor: _PassportColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (face != null) _buildHero(face),
                    const SizedBox(height: 16),
                    _buildFilterPills(),
                    const SizedBox(height: 14),
                    if (_filter == _PassportFilter.rostro && face != null)
                      _buildFaceScores(face)
                    else if (_filter == _PassportFilter.manos && hands != null)
                      _buildHandsScores(hands),
                    const SizedBox(height: 20),
                    RecommendationCard(
                      recommendation: widget.result.recommendation ??
                          'No se generaron recomendaciones específicas.',
                    ),
                    const SizedBox(height: 14),
                    if (!_isLoadingUV && _uvRecommendation != null) ...[
                      _buildUVBanner(),
                      const SizedBox(height: 20),
                    ],
                    if (face != null) ...[
                      ColorPaletteWidget(
                        hexColor: _getHexColorFromSubtono(face.subtono),
                      ),
                      const SizedBox(height: 16),
                      _buildServicesHub(),
                      const SizedBox(height: 14),
                      _buildSocialShareSection(),
                      const SizedBox(height: 20),
                    ],
                    _buildProductsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomCta(),
          ],
        ),
      ),
    ),
  ),
);
  }

  // ---------------------------------------------------------------------
  // Header simple: back + título, reemplaza el AppBar + TabBar de Material
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _PassportColors.textAccent),
            onPressed: _goBackToIdeas,
          ),
          const Text(
            'Tu pasaporte',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _PassportColors.textEyebrow,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.ios_share, size: 18, color: _PassportColors.textAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pasaporte listo para compartir'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero: Pasaporte Biométrico sin doble anillo de score redundante
  // ---------------------------------------------------------------------
  Widget _buildHero(FaceScores face) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A052).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFAF5ED),
              border: Border.all(color: _PassportColors.primaryLight, width: 1),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: _PassportColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PASAPORTE BIOMÉTRICO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _PassportColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _PassportColors.primaryLight.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'EDAD BIO: ${face.bioAge} AÑOS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _PassportColors.textAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtono ${face.subtono} · Armonía Visagista',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _PassportColors.textAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pills rostro/manos: reemplazan las tabs, solo filtran las score cards.
  // ---------------------------------------------------------------------
  Widget _buildFilterPills() {
    Widget pill(String label, _PassportFilter value) {
      final selected = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _PassportColors.primaryLight.withValues(alpha: 0.35) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.black12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? _PassportColors.textAccent : Colors.grey[600],
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Rostro', _PassportFilter.rostro),
        const SizedBox(width: 8),
        pill('Manos', _PassportFilter.manos),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Scores: Evimetra Gauge + GridView 2x2 + Bioderma Clinical Families
  // ---------------------------------------------------------------------
  Widget _buildFaceScores(FaceScores face) {
    final computedGlowScore = widget.result.glowScore ??
        ((face.hydration * 0.35) + ((100 - face.spots) * 0.25) + ((100 - face.pores) * 0.25) + ((100 - face.wrinkles) * 0.15)).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowScoreGaugeWidget(
          glowScore: computedGlowScore,
          onCompareTap: () {
            Navigator.pushNamed(context, '/evolution');
          },
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            ScoreCard(
              label: 'Hidratación',
              value: face.hydration,
              color: _PassportColors.primary,
              icon: Icons.water_drop_outlined,
            ),
            ScoreCard(
              label: 'Arrugas',
              // Menor es mejor: se invierte para que la barra comunique "salud".
              value: 100 - face.wrinkles,
              color: _PassportColors.primary,
              icon: Icons.auto_awesome_outlined,
            ),
            ScoreCard(
              label: 'Manchas',
              value: 100 - face.spots,
              color: _PassportColors.primary,
              icon: Icons.blur_on,
            ),
            ScoreCard(
              label: 'Poros',
              value: 100 - face.pores,
              color: _PassportColors.primary,
              icon: Icons.center_focus_strong_outlined,
            ),
          ],
        ),
        if (widget.result.dermoFamilies != null) ...[
          const SizedBox(height: 14),
          DermoFamiliesWidget(dermoFamilies: widget.result.dermoFamilies!),
        ],
      ],
    );
  }

  Widget _buildHandsScores(HandsDiagnosis hands) {
    Widget row(String label, String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _PassportColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _PassportColors.textEyebrow),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _PassportColors.textAccent,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('Manchas solares', hands.manchasSolares, Icons.wb_sunny_outlined),
        row('Sequedad', hands.sequedad, Icons.water_drop_outlined),
        row('Cutículas', hands.cuticulas, Icons.back_hand_outlined),
        row('Uñas', hands.unas, Icons.brush_outlined),
        row('Edad aparente', '${hands.edadAparente} años', Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _buildUVBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _PassportColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 18, color: Color(0xFF854F0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _uvRecommendation!,
              style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hub de Servicios y Experiencias Virtuales (2 columnas Haute Beauté)
  // ---------------------------------------------------------------------
  Widget _buildServicesHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: _PassportColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SERVICIOS & SIMULADORES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: _PassportColors.textEyebrow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _buildServiceCard(
              title: 'VTO Maquillaje',
              subtitle: 'Simulación de tonos y texturas en vivo',
              icon: Icons.face_retouching_natural,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VtoLiveScreen(biometricResult: widget.result),
                  ),
                );
              },
            ),
            _buildServiceCard(
              title: 'VTO Manicura',
              subtitle: 'Esmaltado virtual y diseño de uñas',
              icon: Icons.back_hand_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NailVtoScreen(biometricResult: widget.result),
                  ),
                );
              },
            ),
            _buildServiceCard(
              title: 'Lookbook Editorial',
              subtitle: 'Estilismos y armonía cromática',
              icon: Icons.auto_awesome_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MakeupLookbookScreen(biometricResult: widget.result),
                  ),
                );
              },
            ),
            _buildServiceCard(
              title: 'Receta GlowStore',
              subtitle: 'Fórmulas y rutina a medida',
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GlowstoreRecipeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _PassportColors.primaryLight.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, color: _PassportColors.primary, size: 18),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 11,
                    color: _PassportColors.primary,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _PassportColors.textAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: _PassportColors.textEyebrow,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Compartir Pasaporte (TikTok / Instagram) en estilo editorial sobrio
  // ---------------------------------------------------------------------
  Widget _buildSocialShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: _PassportColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'COMPARTIR PASAPORTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: _PassportColors.textEyebrow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final consent = await SocialShareService.showConsentModal(
                    context,
                    platformName: 'TikTok',
                    contentTypeLabel: 'Colorimetría IA',
                  );
                  if (consent && mounted) {
                    final res = await SocialShareService.logShare(
                      platform: 'TIKTOK',
                      contentType: 'AI_COLORIMETRY',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Pasaporte compartido en TikTok'),
                          backgroundColor: _PassportColors.textAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share_outlined, size: 16, color: _PassportColors.textAccent),
                label: const Text(
                  'TikTok Stories',
                  style: TextStyle(
                    color: _PassportColors.textAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final consent = await SocialShareService.showConsentModal(
                    context,
                    platformName: 'Instagram Stories',
                    contentTypeLabel: 'Colorimetría IA',
                  );
                  if (consent && mounted) {
                    final res = await SocialShareService.logShare(
                      platform: 'INSTAGRAM',
                      contentType: 'AI_COLORIMETRY',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Pasaporte compartido en Instagram Stories'),
                          backgroundColor: _PassportColors.textAccent,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: _PassportColors.textAccent),
                label: const Text(
                  'Instagram Stories',
                  style: TextStyle(
                    color: _PassportColors.textAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: _PassportColors.primary),
        ),
      );
    }
    if (_productLoadError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No pudimos cargar tus productos recomendados.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadRecommendedProducts,
              child: const Text('Reintentar', style: TextStyle(color: _PassportColors.primary)),
            ),
          ],
        ),
      );
    }
    if (_recommendedProducts.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: _PassportColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PRODUCTOS RECOMENDADOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: _PassportColors.textEyebrow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recommendedProducts.map((p) => ProductCard(product: p)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CTA fijo: botón único sólido "Ver rutina recomendada"
  // ---------------------------------------------------------------------
  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _PassportColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _PassportColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductScannerScreen()),
            );
          },
          child: const Text(
            'EXPLORAR RUTINA RECOMENDADA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
