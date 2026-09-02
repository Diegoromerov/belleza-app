// frontend/lib/screens/profile/my_glow_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../models/glow_cycle_model.dart';
import '../../services/api_service.dart';

class MyGlowDashboardScreen extends StatefulWidget {
  const MyGlowDashboardScreen({super.key});

  @override
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
              shape: BorderRadius.circular(8),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY GLOW — MI EVOLUCIÓN',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A052)))
            : _errorMessage != null
                ? _buildErrorState()
                : _activeCycle == null
                    ? _buildNoCycleState()
                    : _buildActiveCycleView(),
      ),
    );
  }

  Widget _buildActiveCycleView() {
    final cycle = _activeCycle!;
    final progress = (cycle.currentValue / cycle.targetValue).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(LuxeSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BADGE AUDITORÍA PRIVACIDAD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF059669), width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 8),
                Text(
                  'GLOW IA+ • EVOLUCIÓN EN BUCLE CERRADO (PHVA)',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. TARJETA PRINCIPAL DEL GLOW CYCLE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LuxeSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2623), Color(0xFF1E1A18)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CICLO: ${cycle.cycleType.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC5A052),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A052).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC5A052), width: 0.8),
                      ),
                      child: Text(
                        'ESTADO: ${cycle.status.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          color: Color(0xFFC5A052),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cycle.targetGoal,
                  style: const TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // BARRA DE PROGRESO DE LA MÉTRICA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Punto de Partida: ${cycle.baselineValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 14,
                        color: LuxeColors.nude300,
                      ),
                    ),
                    Text(
                      'Meta: ${cycle.targetValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC5A052),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Valor actual: ${cycle.currentValue.toStringAsFixed(0)} • Progreso hacia la meta: ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    color: LuxeColors.nude400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: LuxeSpacing.xxl),

          // 3. PLAN DE HOY & RUTINA AM / PM
          const Text(
            'PLAN DE HOY • RUTINA DIARIA',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: LuxeColors.nude500,
              letterSpacing: 1.2,
            ),
          ),
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
                shape: BorderRadius.circular(12),
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
          const SizedBox(height: 12),

          // BOTÓN DE RE-ESCANEO / REEVALUACIÓN
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC5A052), width: 1.5),
                shape: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Didot',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LuxeColors.nude900,
            ),
          ),
          const SizedBox(height: 10),
          if (steps.isEmpty)
            const Text(
              'No hay pasos específicos asignados.',
              style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 13, color: LuxeColors.nude600),
            )
          else
            ...steps.map((step) {
              final stepMap = step is Map ? step : {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFFC5A052)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepMap['action']?.toString() ?? 'Paso de cuidado',
                            style: const TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LuxeColors.nude900,
                            ),
                          ),
                          if (stepMap['reason'] != null)
                            Text(
                              stepMap['reason'].toString(),
                              style: const TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontSize: 12,
                                color: LuxeColors.nude600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProductTile(dynamic product) {
    final p = product is Map ? product : {};
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuxeColors.nude200),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: Color(0xFFC5A052), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name']?.toString() ?? 'Producto sugerido',
                  style: const TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude900,
                  ),
                ),
                Text(
                  p['reason']?.toString() ?? 'Complemento de rutina',
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 12,
                    color: LuxeColors.nude600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${p['price'] ?? 0}',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: LuxeColors.nude900,
            ),
          ),
        ],
      ),
    );
  }

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
                shape: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActiveCycle,
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
