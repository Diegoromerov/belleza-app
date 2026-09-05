import 'package:flutter/material.dart';

/// GLOWAPP BUSINESS DASHBOARD SCREEN
/// Operating Center displaying compliance score gauge, guided tasks, and findings.
class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF43F5E);
    const darkSlate = Color(0xFF0F172A);
    const emeraldGreen = Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlowApp Business Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [darkSlate, Color(0xFF1E293B)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Mi Peluquería Studio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Etapa: Constitución / Trámites Sanitaros', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 12),
                        Chip(
                          label: Text('Modo: Negocio Nuevo', style: TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  // Compliance Gauge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: emeraldGreen, width: 4),
                    ),
                    child: const Center(
                      child: Text('65%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Tasks Header
            const Text('Ruta de Trámites & Tareas Guiadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),

            _buildTaskTile(
              context,
              title: 'Concepto Sanitario Municipal',
              subtitle: 'Etapa: ENTENDER ➔ Revisar requisitos de inspección física',
              status: 'EN PROCESO',
              statusColor: Colors.orange,
            ),
            _buildTaskTile(
              context,
              title: 'Manual de Bioseguridad y RH1',
              subtitle: 'Etapa: EXPLICAR ➔ Personalizar protocolo de esterilización',
              status: 'PENDIENTE',
              statusColor: primaryColor,
            ),
            _buildTaskTile(
              context,
              title: 'Formalizar Contrato Estilista Líder',
              subtitle: 'Etapa: EJECUTAR ➔ Generar borrador de contrato laboral',
              status: 'VERIFICADO',
              statusColor: emeraldGreen,
            ),

            const SizedBox(height: 24),
            // Findings & Audit
            const Text('Hallazgos de Auditoría (Continuidad)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Actualizar Guardián de Cortopunzantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Riesgo Medio: Fecha de recambio programada para el 15 de septiembre.', style: TextStyle(fontSize: 12, color: Colors.black70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, {required String title, required String subtitle, required String status, required Color statusColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
