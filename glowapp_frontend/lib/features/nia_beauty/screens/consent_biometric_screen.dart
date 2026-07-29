import 'package:flutter/material.dart';
import '../../../shared/glow_tokens.dart';
import '../widgets/glow_glass_card.dart';

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
      backgroundColor: GlowTokens.creamSilk,
      appBar: AppBar(
        title: const Text('Consentimiento Legal'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Protección de Datos & Biometría',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'En cumplimiento de la Ley 1581 de 2012 de Colombia, solicitamos tu autorización para el tratamiento de tus datos personales y análisis biométrico facial.',
                style: Theme.of(context).textTheme.bodyMedium,
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
                          activeColor: GlowTokens.terracota,
                          checkColor: GlowTokens.creamSilk,
                          value: _acceptedHabeasData,
                          onChanged: (val) {
                            setState(() {
                              _acceptedHabeasData = val ?? false;
                            });
                          },
                          title: const Text(
                            'Autorización de Habeas Data (Ley 1581)',
                            style: TextStyle(
                              fontFamily: GlowTokens.fontInter,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: GlowTokens.nightAndean,
                            ),
                          ),
                          subtitle: const Text(
                            'Autorizo a GlowApp para recolectar y almacenar mis datos personales con fines de prestación de servicios de belleza.',
                            style: TextStyle(
                              fontFamily: GlowTokens.fontInter,
                              fontSize: 12,
                              color: GlowTokens.nightAndean,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 24),
                        CheckboxListTile(
                          activeColor: GlowTokens.terracota,
                          checkColor: GlowTokens.creamSilk,
                          value: _acceptedBiometricData,
                          onChanged: (val) {
                            setState(() {
                              _acceptedBiometricData = val ?? false;
                            });
                          },
                          title: const Text(
                            'Tratamiento de Datos Biométricos',
                            style: TextStyle(
                              fontFamily: GlowTokens.fontInter,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: GlowTokens.nightAndean,
                            ),
                          ),
                          subtitle: const Text(
                            'Autorizo el análisis de mi mapa facial para la recomendación personalizada de estilo y prueba virtual (Try-On).',
                            style: TextStyle(
                              fontFamily: GlowTokens.fontInter,
                              fontSize: 12,
                              color: GlowTokens.nightAndean,
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
              ElevatedButton(
                onPressed: _isButtonEnabled
                    ? () {
                        widget.onConsentAccepted?.call();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled
                      ? GlowTokens.terracota
                      : GlowTokens.terracota.withValues(alpha: 0.4),
                ),
                child: const Text('Continuar a la Experiencia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
