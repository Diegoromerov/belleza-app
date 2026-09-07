// frontend/lib/screens/ideas/widgets/score_card.dart
import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const ScoreCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon = Icons.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFFC5A052)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F1A15),
                  ),
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC5A052),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              backgroundColor: const Color(0xFFFAF5ED),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Medallón Biométrico Exclusivo GlowScore 0-100 (Haute Beauté)
class GlowScoreGaugeWidget extends StatelessWidget {
  final int glowScore;
  final VoidCallback? onCompareTap;

  const GlowScoreGaugeWidget({
    super.key,
    required this.glowScore,
    this.onCompareTap,
  });

  String get _qualityLabel {
    if (glowScore >= 85) return 'Piel Radiante & Equilibrada';
    if (glowScore >= 70) return 'Piel Saludable en Buen Estado';
    if (glowScore >= 50) return 'Requiere Hidratación Activa';
    return 'Atención Especializada Sugerida';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF3D59B), width: 0.8),
                ),
                child: const Text(
                  'GLOWSCORE BIOMÉTRICO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Color(0xFF8B6B23),
                  ),
                ),
              ),
              const Spacer(),
              if (onCompareTap != null)
                TextButton.icon(
                  onPressed: onCompareTap,
                  icon: const Icon(Icons.history_rounded, size: 14, color: Color(0xFFC5A052)),
                  label: const Text(
                    'Histórico A/B',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC5A052)),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Medallón Central Dorado
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF0EAE1)),
                    ),
                    CircularProgressIndicator(
                      value: (glowScore.clamp(0, 100)) / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$glowScore',
                            style: const TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1A15),
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _qualityLabel,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1A15),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Evaluación armónica integral de hidratación, tono y firmeza dérmica.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diagnóstico por Áreas Biológicas (Sin marcas externas, sin emojis)
class DermoFamiliesWidget extends StatelessWidget {
  final Map<String, dynamic> dermoFamilies;

  const DermoFamiliesWidget({
    super.key,
    required this.dermoFamilies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa_outlined, color: Color(0xFFC5A052), size: 18),
              SizedBox(width: 8),
              Text(
                'Diagnóstico por Áreas Biológicas',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1A15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Activos botánico-clínicos y protocolos de cabina sugeridos:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          _buildAreaTile(
            title: 'Equilibrio de Sebo y Poros',
            score: dermoFamilies['sebumPores']?['score'] ?? 0,
            treatment: dermoFamilies['sebumPores']?['suggestedTreatment'] ?? 'Limpieza profunda ultrasónica y exfoliación suave',
            active: dermoFamilies['sebumPores']?['suggestedActive'] ?? 'Niacinamida y Ácido Salicílico',
          ),
          const SizedBox(height: 10),
          _buildAreaTile(
            title: 'Claridad & Uniformidad de Tono',
            score: dermoFamilies['pigmentationClarity']?['score'] ?? 0,
            treatment: dermoFamilies['pigmentationClarity']?['suggestedTreatment'] ?? 'Velo antioxidante iluminador con microcorrientes',
            active: dermoFamilies['pigmentationClarity']?['suggestedActive'] ?? 'Vitamina C pura y Ácido Azelaico',
          ),
          const SizedBox(height: 10),
          _buildAreaTile(
            title: 'Firmeza & Elasticidad Facial',
            score: dermoFamilies['firmnessLines']?['score'] ?? 0,
            treatment: dermoFamilies['firmnessLines']?['suggestedTreatment'] ?? 'Radiofrecuencia reafirmante y masaje Miofascial Kobido',
            active: dermoFamilies['firmnessLines']?['suggestedActive'] ?? 'Péptidos bio-idénticos y Ácido Hialurónico',
          ),
          const SizedBox(height: 10),
          _buildAreaTile(
            title: 'Hidratación & Barrera Cutánea',
            score: dermoFamilies['barrierHydration']?['score'] ?? 0,
            treatment: dermoFamilies['barrierHydration']?['suggestedTreatment'] ?? 'Velo de colágeno marino con infusión de oxígeno',
            active: dermoFamilies['barrierHydration']?['suggestedActive'] ?? 'Ácido Hialurónico multimolecular y Ceramidas',
          ),
        ],
      ),
    );
  }

  Widget _buildAreaTile({
    required String title,
    required dynamic score,
    required String treatment,
    required String active,
  }) {
    final intScore = (score is num) ? score.toInt() : (int.tryParse(score?.toString() ?? '') ?? 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCE), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F1A15)),
              ),
              const Spacer(),
              Text(
                '$intScore%',
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC5A052),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Protocolo: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F1A15))),
              Expanded(
                child: Text(
                  treatment,
                  style: TextStyle(fontSize: 11, height: 1.3, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activo clave: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F1A15))),
              Expanded(
                child: Text(
                  active,
                  style: TextStyle(fontSize: 11, height: 1.3, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
