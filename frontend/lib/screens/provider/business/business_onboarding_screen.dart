import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/business_api_service.dart';

/// GLOWAPP BUSINESS ONBOARDING SCREEN (Flutter Expert Refactored)
/// Door 1 (New Business) vs Door 2 (Existing Business) onboarding setup.
class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  String _selectedMode = 'NEW_BUSINESS';
  String _selectedVertical = 'BEAUTY_SALON';
  final TextEditingController _nameController = TextEditingController(text: 'Mi Peluquería Studio');
  final TextEditingController _cityController = TextEditingController(text: 'Bogotá');
  bool _isSubmitting = false;

  final _apiService = BusinessApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleDiagnosticSubmit() async {
    if (_nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      await _apiService.runDiagnostic(
        mode: _selectedMode,
        verticalCode: _selectedVertical,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnóstico iniciado en modo: ${_selectedMode == 'NEW_BUSINESS' ? 'Negocio Nuevo' : 'Negocio Existente'}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnóstico offline/demo configurado para ${_nameController.text}'),
          backgroundColor: gold871,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamSilk,
      appBar: AppBar(
        title: const Text('GlowApp Business Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: obsidianBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona tu Puerta de Entrada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: obsidianBg),
            ),
            const SizedBox(height: 8),
            const Text(
              'GlowApp Business adaptará la ruta de cumplimiento y trámites a tu realidad actual.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Door Selection Cards
            Row(
              children: [
                Expanded(
                  child: _buildDoorCard(
                    title: 'Negocio Nuevo',
                    subtitle: 'Empiezo desde cero. Guiarme paso a paso en trámites de apertura.',
                    icon: Icons.rocket_launch,
                    isSelected: _selectedMode == 'NEW_BUSINESS',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'NEW_BUSINESS');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDoorCard(
                    title: 'Negocio Existente',
                    subtitle: 'Ya estoy operando. Auditar cumplimiento y regularizarme.',
                    icon: Icons.verified_user,
                    isSelected: _selectedMode == 'EXISTING_BUSINESS',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMode = 'EXISTING_BUSINESS');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form Inputs
            const Text('Nombre del Establecimiento', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.store, color: obsidianBg),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Tipo de Negocio (Vertical)', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVertical,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'BEAUTY_SALON', child: Text('Peluquería / Salón de Belleza')),
                DropdownMenuItem(value: 'BARBERSHOP', child: Text('Barbería')),
                DropdownMenuItem(value: 'SPA_MASSAGE', child: Text('Spa / Centro de Relajación')),
                DropdownMenuItem(value: 'AESTHETICS', child: Text('Centro de Estética')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedVertical = val);
              },
            ),
            const SizedBox(height: 16),

            const Text('Ciudad de Operación', style: TextStyle(fontWeight: FontWeight.bold, color: obsidianBg)),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.location_city, color: obsidianBg),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: obsidianBg,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleDiagnosticSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: gold871, strokeWidth: 2),
                      )
                    : const Text(
                        'Iniciar Diagnóstico Business',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gold871),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? obsidianBg : Colors.white,
            border: Border.all(
              color: isSelected ? gold871 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: obsidianBg.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? gold871 : obsidianBg, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : obsidianBg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? warmWhite : Colors.black54,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
