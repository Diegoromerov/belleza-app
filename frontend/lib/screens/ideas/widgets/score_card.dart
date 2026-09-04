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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}

/// Evimetra-style 0-100 Global Skin Index Circular Gauge
class GlowScoreGaugeWidget extends StatelessWidget {
  final int glowScore;
  final VoidCallback? onCompareTap;

  const GlowScoreGaugeWidget({
    super.key,
    required this.glowScore,
    this.onCompareTap,
  });

  String get _qualityLabel {
    if (glowScore >= 85) return 'Radiante & Equilibrada';
    if (glowScore >= 70) return 'Saludable / Buen Estado';
    if (glowScore >= 50) return 'Requiere Hidratación Activa';
    return 'Atención Dermatológica Sugerida';
  }

  Color get _scoreColor {
    if (glowScore >= 80) return const Color(0xFFC5A052);
    if (glowScore >= 65) return const Color(0xFF2E7D32);
    if (glowScore >= 45) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3D59B).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EVIMETRA METRICS • GLOWSCORE IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF8B6B23),
                  ),
                ),
              ),
              const Spacer(),
              if (onCompareTap != null)
                TextButton.icon(
                  onPressed: onCompareTap,
                  icon: const Icon(Icons.compare_arrows, size: 14, color: Color(0xFFC5A052)),
                  label: const Text(
                    'A/B Histórico',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC5A052)),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (glowScore.clamp(0, 100)) / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$glowScore',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _qualityLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1A15),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Índice biométrico cuantificado estandarizado bajo sensor de iluminación Y-Luma.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
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

/// Bioderma-style 4 Clinical Dermatological Families
class DermoFamiliesWidget extends StatelessWidget {
  final Map<String, dynamic> dermoFamilies;

  const DermoFamiliesWidget({
    super.key,
    required this.dermoFamilies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Color(0xFF0072CE), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Prescripción Clínica Dermatológica',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1A15),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BIODERMA AI SPEC',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0072CE)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Diagnóstico por familias biológicas con activos sugeridos y protocolos profesionales en salón:',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          _buildFamilyTile(
            title: 'Sebo y Poros',
            score: dermoFamilies['sebumPores']?['score'] ?? 0,
            treatment: dermoFamilies['sebumPores']?['suggestedTreatment'] ?? 'Limpieza profunda ultrasonido',
            active: dermoFamilies['sebumPores']?['suggestedActive'] ?? 'Niacinamida 5% + Ácido Salicílico',
            icon: Icons.bubble_chart_outlined,
            accentColor: const Color(0xFF00897B),
          ),
          const SizedBox(height: 8),
          _buildFamilyTile(
            title: 'Pigmentación & Tono',
            score: dermoFamilies['pigmentationClarity']?['score'] ?? 0,
            treatment: dermoFamilies['pigmentationClarity']?['suggestedTreatment'] ?? 'Peeling despigmentante suave',
            active: dermoFamilies['pigmentationClarity']?['suggestedActive'] ?? 'Vitamina C pura + Ácido Azelaico',
            icon: Icons.wb_sunny_outlined,
            accentColor: const Color(0xFFF57C00),
          ),
          const SizedBox(height: 8),
          _buildFamilyTile(
            title: 'Firmeza & Líneas',
            score: dermoFamilies['firmnessLines']?['score'] ?? 0,
            treatment: dermoFamilies['firmnessLines']?['suggestedTreatment'] ?? 'Radiofrecuencia facial + Masaje Kobido',
            active: dermoFamilies['firmnessLines']?['suggestedActive'] ?? 'Péptidos pro-colágeno + Retinol 0.3%',
            icon: Icons.auto_awesome,
            accentColor: const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 8),
          _buildFamilyTile(
            title: 'Barrera & Hidratación',
            score: dermoFamilies['barrierHydration']?['score'] ?? 0,
            treatment: dermoFamilies['barrierHydration']?['suggestedTreatment'] ?? 'Velo de colágeno + Oxigenoterapia',
            active: dermoFamilies['barrierHydration']?['suggestedActive'] ?? 'Ácido Hialurónico multimolecular + Ceramidas',
            icon: Icons.water_drop_outlined,
            accentColor: const Color(0xFF0288D1),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTile({
    required String title,
    required dynamic score,
    required String treatment,
    required String active,
    required IconData icon,
    required Color accentColor,
  }) {
    final intScore = (score is num) ? score.toInt() : (int.tryParse(score?.toString() ?? '') ?? 0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[900]),
              ),
              const Spacer(),
              Text(
                '$intScore%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💆 Tratamiento: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
              Expanded(
                child: Text(
                  treatment,
                  style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧪 Activo: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
              Expanded(
                child: Text(
                  active,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

