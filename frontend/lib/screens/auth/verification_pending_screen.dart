// frontend/lib/screens/auth/verification_pending_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 100,
                color: Color(0xFFC89D93),
              ),
              const SizedBox(height: 32),
              const Text(
                'Perfil en proceso de verificación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'El equipo de Belleza App está validando físicamente tus documentos de identidad, RUT y acreditación profesional para garantizar la seguridad del servicio en Fontibón.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Recibirás una notificación y podrás acceder a tu panel de prestador tan pronto como el estado cambie a APROBADO.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Color(0xFFC89D93)),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
