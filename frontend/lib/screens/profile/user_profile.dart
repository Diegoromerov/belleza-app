// lib/screens/profile/user_profile.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/luxe_list_tile.dart';
import '../../services/auth_service.dart';
import 'settings_screen.dart';
import 'biometric_history_screen.dart';
import 'glowstore_orders_screen.dart';
import 'rewards_xp_screen.dart';
import 'habeas_data_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onLogout;

  const UserProfileScreen({
    super.key,
    this.userName = 'Valeria Gómez',
    this.userEmail = 'valeria.gomez@glowapp.com',
    this.onLogout,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        title: const Text(
          'MI PERFIL CONCIERGE',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER DE PERFIL PREMIUM
              ProfileHeader(
                userName: widget.userName,
                userEmail: widget.userEmail,
                membershipLevel: 'SOCIO CLUB GLOW LUXE',
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // GRUPO 1: RITUAL BIOMÉTRICO Y COMPRAS
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: LuxeSpacing.xl),
                child: Text(
                  'MI HISTORIAL Y COMPRAS',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              LuxeProfileTile(
                icon: Icons.history_edu_outlined,
                title: 'Historial de Diagnósticos Biométricos',
                subtitle: 'Revisa tus escaneos faciales y análisis de piel',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BiometricHistoryScreen()),
                  );
                },
              ),
              LuxeProfileTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Mis Pedidos GlowStore',
                subtitle: 'Seguimiento de compras y envíos directos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlowStoreOrdersScreen()),
                  );
                },
              ),
              LuxeProfileTile(
                icon: Icons.card_membership_outlined,
                title: 'Beneficios y Puntos de Experiencia (XP)',
                subtitle: '350 XP acumulados este mes',
                showDivider: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsXpScreen()),
                  );
                },
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // GRUPO 2: PREFERENCIAS Y SEGURIDAD
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: LuxeSpacing.xl),
                child: Text(
                  'PREFERENCIAS Y PRIVACIDAD',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              LuxeProfileTile(
                icon: Icons.settings_outlined,
                title: 'Configuración de la Cuenta',
                subtitle: 'Notificaciones, datos personales y seguridad',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        userEmail: widget.userEmail,
                        onLogout: widget.onLogout,
                      ),
                    ),
                  );
                },
              ),
              LuxeProfileTile(
                icon: Icons.security_outlined,
                title: 'Consentimiento Biométrico y Habeas Data',
                subtitle: 'Gestión de datos sensibles (Ley 1581)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HabeasDataScreen()),
                  );
                },
              ),
              LuxeProfileTile(
                icon: Icons.headset_mic_outlined,
                title: 'Centro de Soporte y PQRSF',
                subtitle: 'Atención a peticiones, quejas y reclamos',
                onTap: () => Navigator.pushNamed(context, '/support'),
              ),
              LuxeProfileTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Preguntas Frecuentes (FAQ)',
                              subtitle: 'Respuestas claras sobre pagos, seguridad y citas',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FaqScreen()),
                                );
                              },
              ),
              LuxeProfileTile(
                icon: Icons.gavel_outlined,
                title: 'Mis Disputas de Servicio',
                subtitle: 'Gestión y seguimiento de arbitrajes de pago',
                showDivider: false,
                onTap: () => Navigator.pushNamed(context, '/disputes'),
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // BOTÓN CERRAR SESIÓN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LuxeSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onLogout ?? () async { await AuthService.logout(); if (context.mounted) { Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); } },
                    icon: const Icon(Icons.logout, color: LuxeColors.nude500, size: 18),
                    label: const Text(
                      'Cerrar Sesión Concierge',
                      style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 16,
                        color: LuxeColors.nude700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
