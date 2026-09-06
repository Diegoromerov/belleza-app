import 'package:flutter/material.dart';
import '../../shared/glow_tokens.dart';
import '../../widgets/glow_glass_card.dart';

/// Pantalla de Consentimiento Biométrico y Habeas Data (Ley 1581).
/// Contiene dos Checkboxes explícitos y habilita el botón de continuación
/// únicamente cuando ambos han sido aceptados explícitamente.
class ConsentBiometricScreen extends StatefulWidget {
  final VoidCallback? onConsentAccepted;

  const ConsentBiometricScreen({
    super.key,
    this.onConsentAccepted,
  });

  @override
  State<ConsentBiometricScreen> createState() => _ConsentBiometricScreenState();
}

class _ConsentBiometricScreenState extends State<ConsentBiometricScreen> {
  bool _acceptedHabeasData = false;
  bool _acceptedBiometricData = false;

  bool get _isButtonEnabled => _acceptedHabeasData && _acceptedBiometricData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Consentimiento Legal',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F1A15)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Protección de Datos & Biometría',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1A15),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'En cumplimiento de la Ley 1581 de 2012 de Colombia, solicitamos tu autorización para el tratamiento de tus datos personales y análisis biométrico facial.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF6B5E59),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: GlowGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              activeColor: const Color(0xFFC5A052),
                              checkColor: Colors.white,
                              value: _acceptedHabeasData,
                              onChanged: (val) {
                                setState(() {
                                  _acceptedHabeasData = val ?? false;
                                });
                              },
                              title: const Text(
                                'Autorización de Habeas Data (Ley 1581)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1F1A15),
                                ),
                              ),
                              subtitle: const Text(
                                'Autorizo a GlowApp para recolectar y almacenar mis datos personales con fines de prestación de servicios de belleza.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF6B5E59),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 24),
                            CheckboxListTile(
                              activeColor: const Color(0xFFC5A052),
                              checkColor: Colors.white,
                              value: _acceptedBiometricData,
                              onChanged: (val) {
                                setState(() {
                                  _acceptedBiometricData = val ?? false;
                                });
                              },
                              title: const Text(
                                'Tratamiento de Datos Biométricos',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1F1A15),
                                ),
                              ),
                              subtitle: const Text(
                                'Autorizo el análisis de mi mapa facial para la recomendación personalizada de estilo y prueba virtual (Try-On).',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF6B5E59),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _isButtonEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _isButtonEnabled ? null : const Color(0xFFE8DFD8),
                      boxShadow: _isButtonEnabled
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
                      onPressed: _isButtonEnabled
                          ? () {
                              widget.onConsentAccepted?.call();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF1F1A15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Continuar a la Experiencia',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isButtonEnabled ? const Color(0xFF1F1A15) : const Color(0xFF8E7D7A),
                        ),
                      ),
                    ),
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
