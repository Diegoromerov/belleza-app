// frontend/lib/screens/glow_cycle/glow_cycle_adaptation_screen.dart
import 'package:flutter/material.dart';
import 'glow_cycle_graduation_screen.dart';

class GlowCycleAdaptationScreen extends StatelessWidget {
  const GlowCycleAdaptationScreen({super.key});

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
          'ADAPTACIÓN DEL CICLO',
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
                  // Provenance & Quality Badge (CONTRACT_03)
                  _buildProvenanceQualityCard(),
                  const SizedBox(height: 20),

                  // Semantic Delta Comparison (CONTRACT_01 & 02)
                  _buildDeltaComparisonCard(),
                  const SizedBox(height: 20),

                  // Atena Multidimensional Decision & RAG Evidence (CONTRACT_08, 09, 10 & 04)
                  _buildAtenaDecisionCard(),
                  const SizedBox(height: 20),

                  // Protocol Changes Breakdown
                  _buildProtocolChangesCard(),
                  const SizedBox(height: 28),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Aceptar Protocolo Adaptado y Continuar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
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
                            content: Text('✨ Protocolo adaptado guardado con éxito. ¡Rumbo al Día 30!'),
                            backgroundColor: Color(0xFF261E17),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GlowCycleGraduationScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver Simulación de Graduación (Día 30)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC5A052),
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

  Widget _buildProvenanceQualityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFEA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DAD0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PROVENIENCIA & CALIDAD DE ESCANEO',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1A15),
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81C784), width: 0.6),
                ),
                child: const Text(
                  'Calidad 94% (Óptima)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Re-Scan validado mediante visión biométrica facial. Iluminación calibrada a 5500K y ángulo simétrico frontal 0° verificado.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF7A6E65),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaComparisonCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'COMPARATIVA LÍNEA BASE VS RE-SCAN',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1A15),
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+15 pts Delta',
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
          const SizedBox(height: 16),

          // Métrica 1: Hidratación
          _buildMetricRow(
            metricName: 'Nivel de Hidratación Dérmica',
            baseline: '50 pts',
            rescan: '65 pts',
            deltaText: '+15 pts (+30%)',
            isPositive: true,
            progress: 0.65,
          ),
          const Divider(height: 24, color: Color(0xFFEFE8DE)),

          // Métrica 2: TEWL
          _buildMetricRow(
            metricName: 'Pérdida Transepidérmica (TEWL)',
            baseline: '42 pts',
            rescan: '31 pts',
            deltaText: '-11 pts (-26%)',
            isPositive: true,
            progress: 0.31,
          ),
          const Divider(height: 24, color: Color(0xFFEFE8DE)),

          // Métrica 3: Uniformidad de Textura
          _buildMetricRow(
            metricName: 'Suavidad y Elasticidad',
            baseline: '55 pts',
            rescan: '68 pts',
            deltaText: '+13 pts (+23%)',
            isPositive: true,
            progress: 0.68,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String metricName,
    required String baseline,
    required String rescan,
    required String deltaText,
    required bool isPositive,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                metricName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1A15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                deltaText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Línea Base: $baseline',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF7A6E65),
                ),
              ),
            ),
            Text(
              'Actual (15d): $rescan',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC5A052),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFEFE8DE),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
          ),
        ),
      ],
    );
  }

  Widget _buildAtenaDecisionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF261E17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                        'DECISIÓN MULTIDIMENSIONAL ATENA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
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
                  border: Border.all(color: const Color(0xFFC5A052), width: 0.8),
                ),
                child: const Text(
                  'INTENSIFICAR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D59B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Dictamen de Adaptación Clínica (Atena Engine)',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Con una adherencia del 87% y una mejoría significativa de +15 pts en la barrera lipídica sin signos de eritema, tu piel está preparada para recibir activos potenciados.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFDCD2C7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A140F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4A3B2C), width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.library_books_rounded, color: Color(0xFFC5A052), size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fuente RAG: 20,412 fragmentos clínicos y protocolos dérmicos validados.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFFB5A89B),
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

  Widget _buildProtocolChangesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE2D7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AJUSTES A TU PROTOCOLO (DÍAS 16 A 30)',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1A15),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildChangeTile(
            phase: 'Matutina (AM)',
            action: 'Mantener Protocolo',
            detail: 'Continuar con Sérum Ácido Hialurónico Puro + FPS 50+ UVA/UVB.',
            badgeColor: const Color(0xFFE8F5E9),
            textColor: const Color(0xFF2E7D32),
          ),
          const Divider(height: 20, color: Color(0xFFEFE8DE)),
          _buildChangeTile(
            phase: 'Nocturna (PM)',
            action: 'Potenciar Activo',
            detail: 'Aumentar Niacinamida al 10% e incorporar Complejo de Péptidos de Cobre 2 noches por semana.',
            badgeColor: const Color(0xFFFFF8E7),
            textColor: const Color(0xFF8D6816),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeTile({
    required String phase,
    required String action,
    required String detail,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            action,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1A15),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF7A6E65),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
