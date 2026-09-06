import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/business_profile_model.dart';
import 'business_document_generator_screen.dart';
import 'business_onboarding_screen.dart';
import 'business_task_detail_screen.dart';

/// GLOWAPP BUSINESS DASHBOARD SCREEN (Flutter Expert Refactored)
/// Operating Center displaying compliance score gauge, guided tasks, and audit findings.
class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({Key? key}) : super(key: key);

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  double _complianceScore = 0.65;
  String _businessName = 'Mi Peluquería Studio';
  String _stage = 'Constitución / Trámites Sanitaros';
  String _onboardingModeLabel = 'Modo: Negocio Nuevo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamSilk,
      appBar: AppBar(
        title: const Text(
          'GlowApp Business Center',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: obsidianBg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Nuevo Diagnóstico',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessOnboardingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Documentos Legal',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessDocumentGeneratorScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: gold871,
        backgroundColor: obsidianBg,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card Belleza Luxe
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Active Tasks Header
              Text(
                'Ruta de Trámites & Tareas Guiadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: obsidianBg,
                    ),
              ),
              const SizedBox(height: 12),

              _buildTaskCard(
                title: 'Concepto Sanitario Municipal',
                stage: TaskStage.entender,
                status: TaskStatus.inProgress,
                subtitle: 'Revisar requisitos de inspección física',
              ),
              _buildTaskCard(
                title: 'Manual de Bioseguridad y RH1',
                stage: TaskStage.explicar,
                status: TaskStatus.pending,
                subtitle: 'Personalizar protocolo de esterilización',
              ),
              _buildTaskCard(
                title: 'Formalizar Contrato Estilista Líder',
                stage: TaskStage.ejecutar,
                status: TaskStatus.verified,
                subtitle: 'Generar borrador de contrato laboral',
              ),

              const SizedBox(height: 24),
              // Findings & Audit
              Text(
                'Hallazgos de Auditoría (Continuidad)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: obsidianBg,
                    ),
              ),
              const SizedBox(height: 12),

              _buildFindingCard(
                title: 'Actualizar Guardián de Cortopunzantes',
                subtitle: 'Riesgo Medio: Fecha de recambio programada para el 15 de septiembre.',
                risk: FindingRiskLevel.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: obsidianBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Etapa: $_stage',
                  style: const TextStyle(color: warmWhite, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold871,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _onboardingModeLabel,
                    style: const TextStyle(color: obsidianBg, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Compliance Gauge
          Semantics(
            label: 'Nivel de cumplimiento del negocio: ${(_complianceScore * 100).toInt()}%',
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold871, width: 4),
              ),
              child: Center(
                child: Text(
                  '${(_complianceScore * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required TaskStage stage,
    required TaskStatus status,
  }) {
    return Semantics(
      button: true,
      label: 'Tarea: $title. Estado: ${status.label}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessTaskDetailScreen()),
            );
          },
          leading: CircleAvatar(
            backgroundColor: auraTeal.withOpacity(0.12),
            child: Icon(stage.icon, color: auraTeal, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Etapa: ${stage.code} ➔ $subtitle', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(color: status.color, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFindingCard({
    required String title,
    required String subtitle,
    required FindingRiskLevel risk,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: risk.color.withOpacity(0.08),
        border: Border.all(color: risk.color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: risk.color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: obsidianBg)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
