import 'package:flutter/material.dart';

/// GLOWAPP BUSINESS TASK DETAIL SCREEN
/// Guided workflow screen: ENTENDER -> EXPLICAR -> RECOMENDAR -> EJECUTAR -> VERIFICAR
class BusinessTaskDetailScreen extends StatefulWidget {
  const BusinessTaskDetailScreen({Key? key}) : super(key: key);

  @override
  State<BusinessTaskDetailScreen> createState() => _BusinessTaskDetailScreenState();
}

class _BusinessTaskDetailScreenState extends State<BusinessTaskDetailScreen> {
  int _currentStep = 0; // 0: Entender, 1: Explicar, 2: Recomendar, 3: Ejecutar, 4: Evidencia

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF43F5E);
    const darkSlate = Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trámite: Concepto Sanitario', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('1. Entender el Requisito', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Ley 9 de 1979 / Decreto 1879'),
            content: const Text(
              'El Concepto Sanitario es el documento emitido por la Secretaría de Salud que certifica que el local cumple con condiciones de higiene, ventilación, bioseguridad y vertimientos.',
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('2. Explicar por qué Importa', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Evita cierres temporales, sanciones económicas y garantiza la confianza de tus clientes al demostrar un espacio seguro y certificado.',
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('3. Recomendación Aura AI', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Aura sugiere: Asegúrate de tener al día el certificado de fumigación (menor a 1 año) y el contrato de recolección de residuos peligrosos (RH1) antes de solicitar la visita.',
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('4. Ejecutar Acción', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completa la solicitud en línea o descarga el formulario de inspección.'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar Formulario de Inspección'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('5. Cargar Evidencia & Verificar', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adjunta foto o PDF del certificado otorgado para la verificación.'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir Certificado Sanitario (PDF/Foto)'),
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }
}
