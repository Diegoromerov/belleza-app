import 'package:flutter/material.dart';

/// GLOWAPP BUSINESS ONBOARDING SCREEN
/// Two Entry Doors: Door 1 (New Business) vs Door 2 (Existing Business).
class BusinessOnboardingScreen extends StatefulWidget {
  const BusinessOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends State<BusinessOnboardingScreen> {
  String _selectedMode = 'NEW_BUSINESS'; // NEW_BUSINESS or EXISTING_BUSINESS
  String _selectedVertical = 'BEAUTY_SALON';
  final TextEditingController _nameController = TextEditingController(text: 'Mi Peluquería Studio');
  final TextEditingController _cityController = TextEditingController(text: 'Bogotá');

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF43F5E); // Rose 500
    const darkSlate = Color(0xFF0F172A); // Slate 900

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlowApp Business Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona tu Puerta de Entrada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkSlate),
            ),
            const SizedBox(height: 8),
            const Text(
              'GlowApp Business adaptará la ruta de cumplimiento y trámites a tu realidad actual.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    onTap: () => setState(() => _selectedMode = 'NEW_BUSINESS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDoorCard(
                    title: 'Negocio Existente',
                    subtitle: 'Ya estoy operando. Auditar cumplimiento y regularizarme.',
                    icon: Icons.verified_user,
                    isSelected: _selectedMode == 'EXISTING_BUSINESS',
                    onTap: () => setState(() => _selectedMode = 'EXISTING_BUSINESS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form Inputs
            const Text('Nombre del Establecimiento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Tipo de Negocio (Vertical)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVertical,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: const [
                DropdownMenuItem(value: 'BEAUTY_SALON', child: Text('Peluquería / Salón de Belleza')),
                DropdownMenuItem(value: 'BARBERSHOP', child: Text('Barbería')),
                DropdownMenuItem(value: 'SPA_MASSAGE', child: Text('Spa / Centro de Relajación')),
                DropdownMenuItem(value: 'AESTHETICS', child: Text('Centro de Estética')),
              ],
              onChanged: (val) => setState(() => _selectedVertical = val!),
            ),
            const SizedBox(height: 16),

            const Text('Ciudad de Operación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Diagnóstico iniciado en modo: ${_selectedMode == 'NEW_BUSINESS' ? 'Negocio Nuevo' : 'Negocio Existente'}'),
                      backgroundColor: Colors.emerald,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Iniciar Diagnóstico Business', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    const primaryColor = Color(0xFFF43F5E);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.white,
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? primaryColor : Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryColor : Colors.black87)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
