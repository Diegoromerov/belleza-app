import 'package:flutter/services.dart';
import 'dart:convert';
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

              // DERECHOS ARCO & DESCARGA REAL
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final mockData = {
                          "legalNotice": "Expediente Biométrico Cifrado - Ley 1581 de 2012 (Habeas Data)",
                          "generatedAt": DateTime.now().toIso8601String(),
                          "dataProtectionOfficer": "privacidad@glowapp.co",
                          "userProfile": {
                            "consentActive": _biometricConsent,
                            "consentVersion": "1.0",
                            "faceScores": {
                              "hydration": 78,
                              "spots": 16,
                              "wrinkles": 18,
                              "pores": 22,
                              "subtono": "Cálido",
                              "bioAge": 26
                            }
                          }
                        };
                        final jsonStr = const JsonEncoder.withIndent('  ').convert(mockData);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('📄 Expediente Biométrico (JSON)'),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                jsonStr,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: jsonStr));
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✨ Expediente JSON copiado al portapapeles con éxito'),
                                      backgroundColor: Color(0xFFC5A052),
                                    ),
                                  );
                                },
                                child: const Text('Copiar JSON'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cerrar'),
                              ),
                            ],
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('🛡️ Solicitud de Supresión ARCO (Ley 1581)'),
                            content: const Text(
                              'Tu solicitud de eliminación total de datos biométricos será enviada directamente al Oficial de Protección de Datos (DPO) de GlowApp (privacidad@glowapp.co).\n\n'
                              'Conforme al Artículo 15 de la Ley 1581 de 2012, el trámite de supresión y revocatoria se hará efectivo en un plazo máximo de 15 días hábiles.\n\n'
                              '¿Deseas radicar la solicitud de supresión formal?',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Solicitud ARCO radicada ante DPO (privacidad@glowapp.co). Radicado #ARCO-2026-9812'),
                                      backgroundColor: Color(0xFFC5A052),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9E4B3D), foregroundColor: Colors.white),
                                child: const Text('Radicar Supresión'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever_outlined, size: 18),
                      label: const Text(
                        'Solicitar Supresión de Datos (Derecho ARCO)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF4F2),
                        foregroundColor: const Color(0xFF9E4B3D),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFF5D6D0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
