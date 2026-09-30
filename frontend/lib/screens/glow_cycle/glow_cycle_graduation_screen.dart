// frontend/lib/screens/glow_cycle/glow_cycle_graduation_screen.dart
import 'package:flutter/material.dart';

class GlowCycleGraduationScreen extends StatelessWidget {
  const GlowCycleGraduationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F1A15), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GRADUACIÓN GLOW CYCLE',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1A15),
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero de Graduación y Reconocimiento
                  _buildGraduationHeroCard(),
                  const SizedBox(height: 20),

                  // Resumen de Transformación Acumulada (30 Días)
                  _buildCumulativeTransformationCard(),
                  const SizedBox(height: 20),

                  // Transición al Próximo Ciclo (CONTRACT_12)
                  _buildNextCycleRecommendationCard(context),
                  const SizedBox(height: 24),

                  // Botones de Acción
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Iniciar Siguiente Glow Cycle: Textura & Luminosidad',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF261E17),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFC5A052), width: 1),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 ¡Nuevo Glow Cycle iniciado! Atena ha calibrado tu plan.'),
                            backgroundColor: Color(0xFF261E17),
                          ),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined, color: Color(0xFFC5A052), size: 18),
                      label: const Text(
                        'Compartir Mi Transformación Dérmica',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1A15),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📸 Certificado de Graduación generado para compartir.'),
                            backgroundColor: Color(0xFF261E17),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraduationHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261E17), Color(0xFF18120D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A052).withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC5A052), width: 1),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF3D59B), size: 42),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡GRADUACIÓN COMPLETADA!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3D59B),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '30 Días de Transformación Cutánea',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Has completado tu ciclo con un 92% de adherencia y superado el objetivo clínico de restauración de barrera.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFC4B8AA),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeTransformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE2D7), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESULTADOS FINALES DEL CICLO',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1A15),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinalMetricCard(
                  title: 'Delta Acumulado',
                  value: '+22 pts',
                  subtitle: '50 → 72 pts',
                  badgeColor: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinalMetricCard(
                  title: 'Adherencia Total',
                  value: '92%',
                  subtitle: '28/30 Check-ins',
                  badgeColor: const Color(0xFFFFF8E7),
                  textColor: const Color(0xFF8D6816),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF81C784), width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estado de la Meta: ¡ALCANZADA Y SUPERADA (72 / 70 objetivo)!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE4DB), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF7A6E65),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF9E9186),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextCycleRecommendationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF261E17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFC5A052), size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'RECOMENDACIÓN ATENA (CONTRACT 12)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF3D59B),
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A052).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SIGUIENTE ETAPA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D59B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Glow Cycle: Textura, Poros y Luminosidad (30 Días)',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Con tu barrera cutánea reforzada al 72%, tu estrato córneo está preparado para tolerar exfoliación química suave (Ácido Mandélico + LHA) y potenciar la luminosidad sin riesgo de sobre-sensibilización.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFDCD2C7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
