import 'package:flutter/material.dart';

/// GLOWAPP BUSINESS DOCUMENT GENERATOR SCREEN
/// Select templates, fill variables, preview draft, and download document.
class BusinessDocumentGeneratorScreen extends StatefulWidget {
  const BusinessDocumentGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<BusinessDocumentGeneratorScreen> createState() => _BusinessDocumentGeneratorScreenState();
}

class _BusinessDocumentGeneratorScreenState extends State<BusinessDocumentGeneratorScreen> {
  String _selectedTemplate = 'TPL_LABOR_CONTRACT_BEAUTY';
  final TextEditingController _employerController = TextEditingController(text: 'Peluquería Studio SAS');
  final TextEditingController _employeeController = TextEditingController(text: 'María Rodríguez');
  final TextEditingController _jobTitleController = TextEditingController(text: 'Estilista Colorista Senior');
  final TextEditingController _salaryController = TextEditingController(text: '\$ 1.800.000 COP');

  bool _isGenerated = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF43F5E);
    const darkSlate = Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador Documental Business', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona una Plantilla Preforma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTemplate,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: const [
                DropdownMenuItem(value: 'TPL_LABOR_CONTRACT_BEAUTY', child: Text('Contrato de Trabajo (Sector Belleza)')),
                DropdownMenuItem(value: 'TPL_BIOSECURITY_MANUAL', child: Text('Manual de Bioseguridad y RH1')),
              ],
              onChanged: (val) => setState(() {
                _selectedTemplate = val!;
                _isGenerated = false;
              }),
            ),
            const SizedBox(height: 20),

            const Text('Datos del Establecimiento y Partes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            TextField(
              controller: _employerController,
              decoration: const InputDecoration(labelText: 'Nombre / Razon Social Empleador', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _employeeController,
              decoration: const InputDecoration(labelText: 'Nombre Completo del Trabajador / Colaborador', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(labelText: 'Cargo / Función Principal', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryController,
              decoration: const InputDecoration(labelText: 'Salario Base / Honorarios', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                onPressed: () {
                  setState(() => _isGenerated = true);
                },
                icon: const Icon(Icons.description),
                label: const Text('Generar Borrador Documental', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            if (_isGenerated) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('BORRADOR GENERADO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Chip(label: Text('Revisión Legal', style: TextStyle(fontSize: 10)), backgroundColor: Colors.amber),
                      ],
                    ),
                    const Divider(),
                    Text('CONTRATO INDIVIDUAL DE TRABAJO\nEntre: ${_employerController.text}\nY: ${_employeeController.text}\nCargo: ${_jobTitleController.text}\nSalario: ${_salaryController.text}\n\nCLÁUSULAS:\n1. El trabajador desempeñará las labores propias de estilismo cumpliendo estrictamente con los protocolos sanitarios.'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.amber.shade100,
                      child: const Text(
                        'ADVERTENCIA LEGAL: Este documento es una plantilla borrador orientativa. Se recomienda la revisión previa por parte de un profesional antes de su firma.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
