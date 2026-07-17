import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:glowapp_frontend/core/theme/app_theme.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/ui/widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _navigateTo(WidgetRef ref, BuildContext context, String route) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30);
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${user?.name.split(' ').first ?? 'Glow'}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const Text('¿Listo para entrenar hoy?', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: GlowTheme.secondary,
                          backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                          child: user?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Grid de opciones
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _MenuCard(
                          icon: Icons.psychology_outlined,
                          title: 'Juego N-Back',
                          subtitle: 'Entrena tu memoria',
                          color: GlowTheme.primary,
                          onTap: () => _navigateTo(ref, context, '/home/game'),
                        ),
                        _MenuCard(
                          icon: Icons.bar_chart_outlined,
                          title: 'Estadísticas',
                          subtitle: 'Tu progreso',
                          color: GlowTheme.secondary,
                          onTap: () => _navigateTo(ref, context, '/home/stats'),
                        ),
                        _MenuCard(
                          icon: Icons.volunteer_activism_outlined,
                          title: 'Alertas SOS',
                          subtitle: 'Seguridad en tiempo real',
                          color: Colors.redAccent,
                          onTap: () => _navigateTo(ref, context, '/home/sos'),
                        ),
                        _MenuCard(
                          icon: Icons.settings_outlined,
                          title: 'Ajustes',
                          subtitle: 'Configuración',
                          color: Colors.grey.shade700,
                          onTap: () => _navigateTo(ref, context, '/home/settings'),
                        ),
                      ],
                    ),
                  ),
                  // Logout button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
