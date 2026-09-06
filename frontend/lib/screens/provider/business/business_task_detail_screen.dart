import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/business_profile_model.dart';

/// GLOWAPP BUSINESS TASK DETAIL SCREEN (Flutter Expert Refactored)
/// Guided workflow screen: ENTENDER -> EXPLICAR -> RECOMENDAR -> EJECUTAR -> VERIFICAR
class BusinessTaskDetailScreen extends StatefulWidget {
  final BusinessTaskModel? task;
  const BusinessTaskDetailScreen({Key? key, this.task}) : super(key: key);

  @override
  State<BusinessTaskDetailScreen> createState() => _BusinessTaskDetailScreenState();
}

class _BusinessTaskDetailScreenState extends State<BusinessTaskDetailScreen> {
  int _currentStep = 0;
  bool _isEvidenceUploaded = false;

  @override
  Widget build(BuildContext context) {
    final titleText = widget.task?.title ?? 'Trámite: Concepto Sanitario';

    return Scaffold(
      backgroundColor: creamSilk,
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: obsidianBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          HapticFeedback.lightImpact();
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Evidencia enviada exitosamente para revisión administrativa.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          HapticFeedback.lightImpact();
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: obsidianBg,
                    foregroundColor: gold871,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? 'Enviar para Verificación' : 'Siguiente Paso'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Anterior', style: TextStyle(color: obsidianBg)),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('1. Entender el Requisito', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            subtitle: const Text('Normativa Sanitaria Ley 9 de 1979 / Decreto 1879'),
            content: const Text(
              'El Concepto Sanitario es el documento emitido por la Secretaría de Salud que certifica que el local cumple con condiciones de higiene, ventilación, bioseguridad y vertimientos.',
              style: TextStyle(height: 1.4, color: Colors.black87),
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('2. Explicar por qué Importa', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            content: const Text(
              'Evita cierres temporales, sanciones económicas y garantiza la confianza de tus clientes al demostrar un espacio seguro y certificado.',
              style: TextStyle(height: 1.4, color: Colors.black87),
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('3. Recomendación Aura AI', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: auraTeal.withOpacity(0.08),
                border: Border.all(color: auraTeal.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: auraTeal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aura sugiere: Asegúrate de tener al día el certificado de fumigación (menor a 1 año) y el contrato de recolección de residuos peligrosos (RH1) antes de solicitar la visita.',
                      style: TextStyle(fontSize: 12, height: 1.3, color: obsidianBg),
                    ),
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('4. Ejecutar Acción', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completa la solicitud en línea o descarga el formulario de inspección oficial.'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Descargando Formulario de Inspección...')),
                    );
                  },
                  icon: const Icon(Icons.download, color: obsidianBg),
                  label: const Text('Descargar Formulario de Inspección (PDF)', style: TextStyle(color: obsidianBg)),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('5. Cargar Evidencia & Verificar', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adjunta foto o PDF del certificado otorgado para la verificación administrativa.'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isEvidenceUploaded = !_isEvidenceUploaded);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isEvidenceUploaded ? const Color(0xFFD1FAE5) : Colors.white,
                      border: Border.all(
                        color: _isEvidenceUploaded ? const Color(0xFF10B981) : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isEvidenceUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                          color: _isEvidenceUploaded ? const Color(0xFF10B981) : obsidianBg,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isEvidenceUploaded
                                ? 'Certificado_Sanitario_2026.pdf (Cargado)'
                                : 'Tocar para adjuntar documento / foto',
                            style: TextStyle(
                              fontWeight: _isEvidenceUploaded ? FontWeight.bold : FontWeight.normal,
                              color: _isEvidenceUploaded ? const Color(0xFF065F46) : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 4,
            state: _isEvidenceUploaded ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
