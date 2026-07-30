// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../widgets/profile/luxe_list_tile.dart';

class SettingsScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    required this.userEmail,
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricAuthEnabled = true;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  bool _anonymizedAnalytics = true;

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuxeColors.nude100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpacing.md),
          side: const BorderSide(color: LuxeColors.nude200),
        ),
        title: const Text(
          'Eliminar Cuenta Concierge',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
          ),
        ),
        content: const Text(
          'Esta acción purgará tu historial biométrico y registros de escaneo de forma irreversible de nuestros servidores cifrados.',
          style: LuxeTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: LuxeColors.nude900)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitud de eliminación registrada de acuerdo a Ley 1581.'),
                  backgroundColor: LuxeColors.nude900,
                ),
              );
            },
            child: const Text(
              'Confirmar Supresión',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                color: Color(0xFFB00020), // Rojo semántico sutil
                fontWeight: FontWeight.bold,
              ),
            ),
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
          'CONFIGURACIÓN & PRIVACIDAD',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxeSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECCIÓN 1: SEGURIDAD DE SESIÓN
              const Text(
                'SEGURIDAD & AUTENTICACIÓN',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              LuxeProfileTile(
                icon: Icons.fingerprint,
                title: 'Autenticación Biométrica',
                subtitle: 'Ingreso rápido con FaceID / Huella',
                trailing: LuxeToggle(
                  value: _biometricAuthEnabled,
                  onChanged: (val) => setState(() => _biometricAuthEnabled = val),
                ),
              ),
              LuxeProfileTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contraseña',
                showDivider: false,
                onTap: () {},
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // SECCIÓN 2: NOTIFICACIONES
              const Text(
                'COMUNICACIÓN CONCIERGE',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              LuxeProfileTile(
                icon: Icons.notifications_none,
                title: 'Notificaciones Push',
                subtitle: 'Recordatorios de rutina de piel',
                trailing: LuxeToggle(
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
              ),
              LuxeProfileTile(
                icon: Icons.mail_outline,
                title: 'Novedades y Novedades Luxe',
                subtitle: 'Boletín de lanzamientos de productos',
                trailing: LuxeToggle(
                  value: _marketingEmails,
                  onChanged: (val) => setState(() => _marketingEmails = val),
                ),
                showDivider: false,
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // SECCIÓN 3: PRIVACIDAD Y DATOS SENSIBLES
              const Text(
                'DATOS Y TELEMETRÍA',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              LuxeProfileTile(
                icon: Icons.analytics_outlined,
                title: 'Telemetría Anónima de Uso',
                subtitle: 'Ayuda a mejorar los modelos de escaneo de Aura',
                trailing: LuxeToggle(
                  value: _anonymizedAnalytics,
                  onChanged: (val) => setState(() => _anonymizedAnalytics = val),
                ),
                showDivider: false,
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // ACCIÓN DESTRUCTIVA: ELIMINAR CUENTA (CON TIPOGRAFÍA SERIF ROJA SUTIL)
              ListTile(
                onTap: () => _showDeleteAccountConfirmation(context),
                leading: const Icon(Icons.delete_outline, color: Color(0xFFB00020)),
                title: const Text(
                  'Solicitar Supresión de Datos (ARCO)',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 16,
                    color: Color(0xFFB00020),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // INFORMACIÓN LEGAL Y VERSIÓN CON TEXTO NUDE400 Y ENLACES SUBRAYADOS
              Center(
                child: Column(
                  children: [
                    const Text(
                      'GlowApp Belleza Luxe • v2.4.0 (Build 2026)',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude500),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Términos de Servicio',
                            style: TextStyle(fontSize: 11, color: LuxeColors.nude500, decoration: TextDecoration.underline),
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: LuxeColors.nude500)),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Política de Privacidad Ley 1581',
                            style: TextStyle(fontSize: 11, color: LuxeColors.nude500, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
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
