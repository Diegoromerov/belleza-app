// lib/screens/profile/habeas_data_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';

class HabeasDataScreen extends StatefulWidget {
  const HabeasDataScreen({super.key});

  @override
  State<HabeasDataScreen> createState() => _HabeasDataScreenState();
}

class _HabeasDataScreenState extends State<HabeasDataScreen> {
  bool _biometricConsent = true;

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
          'HABEAS DATA & PRIVACIDAD',
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LuxeSpacing.xl),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO LEGAL LEY 1581
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LuxeColors.nude200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, color: LuxeColors.nude900, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'PROTECCIÓN DE DATOS SENSIBLES',
                          style: TextStyle(
                            fontFamily: 'Didot',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: LuxeColors.nude900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'De conformidad con la Ley Statutory 1581 de 2012 y el GDPR, tus vectores faciales y mapas biométricos recopilados por Aura AI se almacenan con cifrado AES-256 en servidores aislados.',
                      style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 14,
                        color: LuxeColors.nude700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              const Text(
                'GESTIÓN DE CONSENTIMIENTOS',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LuxeColors.nude200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Procesamiento Biométrico Facial',
                            style: TextStyle(
                              fontFamily: 'Didot',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LuxeColors.nude900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Permite a Aura AI escanear la salud de tu piel',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 13,
                              color: LuxeColors.nude600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _biometricConsent,
                      activeColor: const Color(0xFFC5A052),
                      onChanged: (val) {
                        setState(() => _biometricConsent = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'Consentimiento biométrico otorgado.'
                                : 'Consentimiento revocado. Los datos serán anonimizados.'),
                            backgroundColor: LuxeColors.nude900,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // DERECHOS ARCO & DESCARGA
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando paquete JSON cifrado de tus datos biométricos...'),
                        backgroundColor: LuxeColors.nude900,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_outlined, color: LuxeColors.nude900, size: 18),
                  label: const Text(
                    'Exportar Mi Expediente Biométrico (JSON)',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: LuxeColors.nude300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
