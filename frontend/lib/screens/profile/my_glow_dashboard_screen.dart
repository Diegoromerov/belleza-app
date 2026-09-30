import 'package:flutter/material.dart';
import '../glow_cycle/glow_cycle_journey_screen.dart';
import '../glow_cycle/glow_cycle_adaptation_screen.dart';

class MyGlowDashboardScreen extends StatelessWidget {
  const MyGlowDashboardScreen({super.key});

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

                  // Tarjeta Interactiva de Seguimiento Glow Cycle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC5A052).withValues(alpha: 0.5), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFC5A052), size: 20),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'GLOW CYCLE ACTIVO',
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF81C784), width: 0.8),
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
                        const SizedBox(height: 14),
                        const Text(
                          'Transformación Cutánea — Hidratación',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1A15),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Día 15 de 30 · Adherencia 87% (Alta)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF7A6E65),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '87%',
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
                            value: 0.87,
                            minHeight: 6,
                            backgroundColor: Color(0xFFEFE8DE),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A052)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFFC5A052)),
                                label: const Text(
                                  'Check-in AM/PM',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F1A15)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GlowCycleJourneyScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.camera_front_rounded, size: 16, color: Colors.white),
                                label: const Text(
                                  'Re-Scan Hito 15d',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF261E17),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

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
                  const SizedBox(height: 14),

                  _buildActionTile(
                    context,
                    title: 'Ver Historial de Citas y Rituales',
                    subtitle: 'Consulta el estado y seguimiento en vivo',
                    icon: Icons.history_rounded,
                    route: '/client-bookings',
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
          const SizedBox(height: 4),
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
      ),
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}
