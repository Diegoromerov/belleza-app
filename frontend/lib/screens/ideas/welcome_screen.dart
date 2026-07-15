import 'package:flutter/material.dart';
import 'capture_screen.dart';

class BiometricWelcomeScreen extends StatelessWidget {
  const BiometricWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.face_retouching_natural_outlined,
                    size: 64,
                    color: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '¡Te damos la bienvenida al\nHub Biométrico!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'A continuación realizaremos un escaneo facial de 15 segundos y de manos para analizar tus tonos y recomendar la rutina y paletas ideales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              // Lista de recomendaciones para la captura
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildGuidelineRow(Icons.wb_sunny_outlined, 'Asegura una buena iluminación natural.'),
                    const SizedBox(height: 12),
                    _buildGuidelineRow(Icons.no_photography_outlined, 'Evita accesorios como gafas o gorras.'),
                    const SizedBox(height: 12),
                    _buildGuidelineRow(Icons.center_focus_strong_outlined, 'Mantén la mirada al centro del visor.'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navegar a la pantalla de captura
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaptureScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'COMENZAR ESCANEO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Volver a Ideas',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
