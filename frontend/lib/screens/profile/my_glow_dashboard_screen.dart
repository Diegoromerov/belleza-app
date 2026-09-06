import 'package:flutter/material.dart';

class MyGlowDashboardScreen extends StatelessWidget {
  const MyGlowDashboardScreen({super.key});

  @override
<<<<<<< HEAD
  State<MyGlowDashboardScreen> createState() => _MyGlowDashboardScreenState();
}

class _MyGlowDashboardScreenState extends State<MyGlowDashboardScreen> {
  bool _isLoading = true;
  GlowCycle? _activeCycle;
  String? _errorMessage;
  bool _isCheckinLogged = false;

  @override
  void initState() {
    super.initState();
    _loadActiveCycle();
  }

  Future<void> _loadActiveCycle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.getActiveGlowCycle();
      if (res['hasActiveCycle'] == true && res['cycle'] != null) {
        setState(() {
          _activeCycle = GlowCycle.fromJson(res['cycle']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _activeCycle = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar el Glow Cycle activo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCheckin() async {
    if (_activeCycle == null) return;
    try {
      await ApiService.logCycleCheckin(_activeCycle!.id, amCompleted: true, pmCompleted: true);
      setState(() {
        _isCheckinLogged = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Excelente! Check-in de rutina registrado exitosamente.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar check-in: $e')),
      );
    }
  }

  Future<void> _handleRescanDialog(BuildContext context) async {
    if (_activeCycle == null) return;
    
    // Simular medición de progreso intermedia (+12 en hidratación)
    final newScore = (_activeCycle!.currentValue + 12.0).clamp(0.0, 100.0);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'RE-ESCANEO BIOMÉTRICO (DÍA 15)',
          style: TextStyle(fontFamily: 'Didot', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se simulará la captura bio-óptica para evaluar tu progreso en ${_activeCycle!.targetMetricKey}.\n\nPuntaje anterior: ${_activeCycle!.currentValue.toStringAsFixed(0)}\nNuevo puntaje detectado: ${newScore.toStringAsFixed(0)}',
          style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2623),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await ApiService.submitCycleRescan(
                  _activeCycle!.id,
                  dayNumber: 15,
                  faceScores: { _activeCycle!.targetMetricKey: newScore },
                );
                await _loadActiveCycle();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Re-escaneo completado. Delta: +${res['delta'] ?? 12} puntos. ${res['adaptationReason'] ?? ''}'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error en re-escaneo: $e')),
                );
              }
            },
            child: const Text('CONFIRMAR ESCANEO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
=======
>>>>>>> origin/main
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
          'MI TABLERO GLOW CONCIERGE',
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta VIP Resumen
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF261E17), Color(0xFF15100C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 18,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A052).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC5A052), width: 0.8),
                              ),
                              child: const Text(
                                'MEMBRESÍA ACTIVA VIP',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF3D59B),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const Icon(Icons.stars_rounded, color: Color(0xFFC5A052), size: 26),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bienvenido a tu Espacio Personal',
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Gestiona tus citas, seguimiento de pedidos y salud dérmica con Inteligencia Artificial.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFFC4B8AA),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'MÉTRICAS DEL RITUAL',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1A15),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Rituales Activos',
                          value: '2',
                          subtitle: 'Próxima cita hoy',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Puntos Glow XP',
                          value: '350',
                          subtitle: 'Nivel Oro 871',
                          icon: Icons.workspace_premium_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'ACCIONES DIRECTAS',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1A15),
                      letterSpacing: 0.8,
                    ),
                  ),
<<<<<<< HEAD
                ),
                const SizedBox(height: 12),
                Text(
                  'Valor actual: ${cycle.currentValue.toStringAsFixed(0)} • Progreso hacia la meta: ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    color: LuxeColors.nude600,
=======
                  const SizedBox(height: 14),

                  _buildActionTile(
                    context,
                    title: 'Ver Historial de Citas y Rituales',
                    subtitle: 'Consulta el estado y seguimiento en vivo',
                    icon: Icons.history_rounded,
                    route: '/client-bookings',
>>>>>>> origin/main
                  ),
                  _buildActionTile(
                    context,
                    title: 'Billetera Glow & Medios de Pago',
                    subtitle: 'Glow Black VIP y transferencias Nequi',
                    icon: Icons.account_balance_wallet_outlined,
                    route: '/wallet',
                  ),
                  _buildActionTile(
                    context,
                    title: 'Configuración & Privacidad',
                    subtitle: 'Biometría, seguridad y notificaciones',
                    icon: Icons.tune_rounded,
                    route: '/settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC5A052), size: 24),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1A15),
            ),
          ),
<<<<<<< HEAD
          const SizedBox(height: 12),

          // Rutina Mañana
          _buildRoutineCard(
            title: '☀️ Rutina Matutina (AM)',
            steps: cycle.amRoutine,
          ),
          const SizedBox(height: 12),

          // Rutina Noche
          _buildRoutineCard(
            title: '🌙 Rutina Nocturna (PM)',
            steps: cycle.pmRoutine,
          ),

          const SizedBox(height: 20),

          // 4. BOTÓN DE CHECK-IN
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCheckinLogged ? const Color(0xFF059669) : const Color(0xFF2C2623),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isCheckinLogged ? null : _handleCheckin,
              icon: Icon(_isCheckinLogged ? Icons.check_circle : Icons.task_alt, color: Colors.white, size: 20),
              label: Text(
                _isCheckinLogged ? 'RUTINA DE HOY COMPLETADA' : 'REGISTRAR CHECK-IN DE HOY',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // BOTÓN DE RE-ESCANEO / REEVALUACIÓN
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC5A052), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _handleRescanDialog(context),
              icon: const Icon(Icons.camera_enhance_outlined, color: Color(0xFFC5A052), size: 20),
              label: const Text(
                'REALIZAR RE-ESCANEO (HITO DE PROGRESO)',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC5A052),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: LuxeSpacing.xxl),

          // 5. PRODUCTOS RECOMENDADOS DEL PLAN
          if (cycle.recommendedProducts.isNotEmpty) ...[
            const Text(
              'PRODUCTOS CONTEXTUALES DE GLOWSTORE',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: LuxeColors.nude500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...cycle.recommendedProducts.map((p) => _buildProductTile(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildEvolutionTimeline(GlowCycle cycle) {
    final currentDay = cycle.continuity?['currentDayNumber'] ?? 1;
    final isD1Done = true;
    final isD15Done = cycle.measurements.any((m) => (m is Map && (m['day_number'] == 15 || m['measurement_type']?.toString().contains('15') == true)));
    final isD30Done = cycle.status == 'completed' || cycle.measurements.any((m) => (m is Map && m['day_number'] >= 30));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxeColors.nude200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LÍNEA TEMPORAL DE EVOLUCIÓN',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A052).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DÍA $currentDay DE ${cycle.durationDays}',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC5A052),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // HITOS VISUALES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestoneNode(label: 'DÍA 1\nBaseline', isCompleted: isD1Done, isCurrent: currentDay < 15),
              _buildMilestoneLine(isPassed: currentDay >= 15),
              _buildMilestoneNode(label: 'DÍA 15\nRe-scan', isCompleted: isD15Done, isCurrent: currentDay >= 15 && currentDay < 30),
              _buildMilestoneLine(isPassed: currentDay >= 30),
              _buildMilestoneNode(label: 'DÍA 30\nGraduación', isCompleted: isD30Done, isCurrent: currentDay >= 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneNode({required String label, required bool isCompleted, required bool isCurrent}) {
    final color = isCompleted
        ? const Color(0xFF059669)
        : isCurrent
            ? const Color(0xFFC5A052)
            : LuxeColors.nude300;

    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          color: color,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isCompleted || isCurrent ? LuxeColors.nude900 : LuxeColors.nude600,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneLine({required bool isPassed}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
        color: isPassed ? const Color(0xFF059669) : LuxeColors.nude200,
      ),
    );
  }

  Widget _buildRoutineCard({required String title, required List<dynamic> steps}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxeColors.nude200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
=======
          const SizedBox(height: 4),
>>>>>>> origin/main
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1A15),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF8C7E74),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildNoCycleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFC5A052), size: 56),
            const SizedBox(height: 16),
            const Text(
              'AÚN NO TIENES UN GLOW CYCLE ACTIVO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Didot',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LuxeColors.nude900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Realiza tu primer diagnóstico facial o de manos para que Glow IA+ cree tu plan de transformación personalizado de 30 días.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 15,
                color: LuxeColors.nude600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2623),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'INICIAR DIAGNÓSTICO',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
=======
  static Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
>>>>>>> origin/main
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6EE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEFE8DE), width: 1),
          ),
          child: Icon(icon, color: const Color(0xFFC5A052), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1A15),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF8C7E74),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8C7E74)),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
