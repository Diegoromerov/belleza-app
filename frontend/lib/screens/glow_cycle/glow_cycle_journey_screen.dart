// frontend/lib/screens/glow_cycle/glow_cycle_journey_screen.dart
import 'package:flutter/material.dart';
import 'glow_cycle_adaptation_screen.dart';
import 'glow_cycle_graduation_screen.dart';

class GlowCycleJourneyScreen extends StatefulWidget {
  const GlowCycleJourneyScreen({super.key});

  @override
  State<GlowCycleJourneyScreen> createState() => _GlowCycleJourneyScreenState();
}

class _GlowCycleJourneyScreenState extends State<GlowCycleJourneyScreen> {
  // Estado local para hábitos AM y PM
  bool amCleanser = true;
  bool amSerum = true;
  bool amSunscreen = true;

  bool pmDoubleCleanse = false;
  bool pmTreatment = false;
  bool pmBarrierCream = false;

  bool isCheckedInToday = false;

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
          'MI VIAJE GLOW CYCLE',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1A15),
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFC5A052)),
            tooltip: 'Graduación',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GlowCycleGraduationScreen()),
              );
            },
          ),
        ],
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
                  // Banner Hero del Ciclo Activo
                  _buildCycleHeroCard(),
                  const SizedBox(height: 20),

                  // Alerta de Hito de Re-Scan alcanzado (Día 15)
                  _buildMilestoneAlertCard(),
                  const SizedBox(height: 24),

                  // Sección de Hábitos Diarios AM / PM
                  _buildDailyRoutineSection(),
                  const SizedBox(height: 24),

                  // Métricas longitudinales y Delta Semántico
                  _buildMetricsSummaryCard(),
                  const SizedBox(height: 28),

                  // Botón CTA de Re-Scan / Adaptación
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Ver Adaptación y Resultados Re-Scan (Hito 15d)',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GlowCycleAdaptationScreen(),
                          ),
                        );
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
                        'Ver Simulación de Graduación y Próximo Ciclo',
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

  Widget _buildCycleHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261E17), Color(0xFF15100C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A052).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC5A052), width: 0.8),
                  ),
                  child: const Text(
                    'GLOW CYCLE · FASE DE ADAPTACIÓN',
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                ),
                child: const Text(
                  '+15 pts Delta',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF81C784),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Transformación Cutánea: Hidratación',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fortalecimiento de la barrera dérmica y retención lipídica celular.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFFC4B8AA),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso: Día 15 de 30',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '50% del Ciclo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC5A052),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.50,
              minHeight: 7,
              backgroundColor: Color(0xFF3B3128),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFC5A052)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Zona Horaria Local: América/Bogotá (Check-in activo)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFFF3D59B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0C475), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A052).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_front_rounded, color: Color(0xFF8D6816), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '¡Hito de 15 Días Completado!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C450E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tu piel ha evolucionado positivamente (+15 pts). Hemos recalculado tu fórmula de adaptación con Atena IA.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF705615),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRoutineSection() {
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
                  'RITUAL DIARIO (HÁBITOS)',
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
                  color: const Color(0xFFF4EFEA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Adherencia 87%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8D6816),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rutina AM
          _buildRoutineHeader(Icons.wb_sunny_outlined, 'Rutina Matutina (AM)', const Color(0xFFD97706)),
          const SizedBox(height: 8),
          _buildHabitTile(
            title: '1. Limpiador Suave pH 5.5',
            subtitle: 'Remueve impurezas nocturnas sin deshidratar',
            value: amCleanser,
            onChanged: (v) => setState(() => amCleanser = v ?? false),
          ),
          _buildHabitTile(
            title: '2. Sérum Hialurónico Puro + B5',
            subtitle: 'Aplicar sobre piel húmeda para hidratación profunda',
            value: amSerum,
            onChanged: (v) => setState(() => amSerum = v ?? false),
          ),
          _buildHabitTile(
            title: '3. Protector Solar FPS 50+ UVA/UVB',
            subtitle: 'Escudo diario contra fotoenvejecimiento',
            value: amSunscreen,
            onChanged: (v) => setState(() => amSunscreen = v ?? false),
          ),

          const Divider(height: 28, color: Color(0xFFEFE8DE)),

          // Rutina PM
          _buildRoutineHeader(Icons.nightlight_round_outlined, 'Rutina Nocturna (PM)', const Color(0xFF4338CA)),
          const SizedBox(height: 8),
          _buildHabitTile(
            title: '1. Doble Limpieza (Bálsamo + Gel)',
            subtitle: 'Disuelve polución y filtros solares acumulados',
            value: pmDoubleCleanse,
            onChanged: (v) => setState(() => pmDoubleCleanse = v ?? false),
          ),
          _buildHabitTile(
            title: '2. Booster de Niacinamida 5% (Adaptado)',
            subtitle: 'Regeneración celular nocturna y elasticidad',
            value: pmTreatment,
            onChanged: (v) => setState(() => pmTreatment = v ?? false),
          ),
          _buildHabitTile(
            title: '3. Crema Barrera con Ceramidas',
            subtitle: 'Sella la humedad y repara la matriz dérmica',
            value: pmBarrierCream,
            onChanged: (v) => setState(() => pmBarrierCream = v ?? false),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                isCheckedInToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isCheckedInToday ? const Color(0xFF2E7D32) : const Color(0xFFC5A052),
              ),
              label: Text(
                isCheckedInToday ? '¡Check-in Registrado Hoy en Bogotá!' : 'Registrar Check-in de Hoy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCheckedInToday ? const Color(0xFF2E7D32) : const Color(0xFF1F1A15),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isCheckedInToday ? const Color(0xFF81C784) : const Color(0xFFC5A052),
                  width: 1.2,
                ),
                backgroundColor: isCheckedInToday ? const Color(0xFFE8F5E9) : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  isCheckedInToday = true;
                  amCleanser = true;
                  amSerum = true;
                  amSunscreen = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Check-in verificado en Bogotá. ¡Adherencia +1.5%!'),
                    backgroundColor: Color(0xFF261E17),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineHeader(IconData icon, String title, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1A15),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                activeColor: const Color(0xFFC5A052),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: value ? const Color(0xFF1F1A15) : const Color(0xFF7A6E65),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DAD0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVOLUCIÓN DÉRMICA (DELTA SEMÁNTICO)',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1A15),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCol(
                  'Hidratación Dérmica',
                  '50 → 65 pts',
                  '+15 pts (Mejora)',
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricMiniCol(
                  'Barrera TEWL',
                  '42 → 31 pts',
                  '-11 pts (Óptimo)',
                  const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniCol(String label, String values, String delta, Color deltaColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE4DB), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF7A6E65),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            values,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1A15),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: deltaColor,
            ),
          ),
        ],
      ),
    );
  }
}
