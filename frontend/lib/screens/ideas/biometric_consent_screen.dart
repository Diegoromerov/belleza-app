import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import 'welcome_screen.dart';

class BiometricConsentScreen extends StatefulWidget {
  const BiometricConsentScreen({super.key});

  @override
  State<BiometricConsentScreen> createState() => _BiometricConsentScreenState();
}

class _BiometricConsentScreenState extends State<BiometricConsentScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Consentimiento Biométrico Aura',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1F1A15)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC5A052).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 36,
                      color: Color(0xFF1F1A15),
                    ),
                  ),
              const SizedBox(height: 24),
              const Text(
                'Tu privacidad es importante para nosotros',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: const Text(
                    'Para ofrecerte recomendaciones personalizadas y diagnósticos en tiempo real de tu piel y uñas, necesitamos procesar imágenes de tu rostro y manos mediante APIs externas de Inteligencia Artificial (YouCam y Gemini).\n\n'
                    '• **Privacidad:** No almacenamos tus fotos de manera permanente en nuestros servidores. Solo se procesan en memoria durante la ejecución de los análisis.\n'
                    '• **Auditoría:** Tu aceptación se registrará de forma auditable (IP, fecha y versión de la política) bajo los lineamientos de la Ley 1581 de 2012 (Habeas Data de Colombia).\n'
                    '• **Control:** Puedes revocar este consentimiento en cualquier momento directamente desde los ajustes de tu perfil.\n\n'
                    'Al presionar "ACEPTAR", autorizas libremente el procesamiento de tus datos biométricos para el Hub de Inspiración e Ideas de GlowApp.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  title: const Text(
                    'Acepto el tratamiento de mis datos biométricos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  value: _accepted,
                  onChanged: (value) {
                    setState(() {
                      _accepted = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFC5A052),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _accepted && !_isLoading
                            ? const LinearGradient(
                                colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _accepted && !_isLoading ? null : Colors.grey.shade300,
                        boxShadow: _accepted && !_isLoading
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFC5A052).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _accepted && !_isLoading
                            ? () async {
                                setState(() => _isLoading = true);
                                try {
                                  await BiometricService.saveConsent();
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const BiometricWelcomeScreen(),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al guardar consentimiento: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFF1F1A15),
                          disabledBackgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF1F1A15),
                                ),
                              )
                            : Text(
                                'ACEPTAR',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: _accepted && !_isLoading ? const Color(0xFF1F1A15) : Colors.grey.shade600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
