// frontend/lib/screens/auth/onboarding_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedRole; // 'CLIENTE' or 'PRESTADOR'
  bool _habeasDataAccepted = false;
  bool _isLoading = false;
  String? _error;

  // URLs de documentos subidos
  String? _documentoUrl;
  String? _rutUrl;
  String? _certificacionUrl;

  // Estados de carga por documento
  bool _uploadingDoc = false;
  bool _uploadingRut = false;
  bool _uploadingCert = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadDocument(String type) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() {
        if (type == 'doc') _uploadingDoc = true;
        if (type == 'rut') _uploadingRut = true;
        if (type == 'cert') _uploadingCert = true;
        _error = null;
      });

      final Uint8List bytes = await file.readAsBytes();
      final String uploadedUrl = await ApiService.uploadImage(bytes, file.name);

      setState(() {
        if (type == 'doc') _documentoUrl = uploadedUrl;
        if (type == 'rut') _rutUrl = uploadedUrl;
        if (type == 'cert') _certificacionUrl = uploadedUrl;
      });
    } catch (e) {
      setState(() => _error = 'Error al subir el archivo: $e');
    } finally {
      setState(() {
        if (type == 'doc') _uploadingDoc = false;
        if (type == 'rut') _uploadingRut = false;
        if (type == 'cert') _uploadingCert = false;
      });
    }
  }

  Future<void> _submitOnboarding() async {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedRole == 'PRESTADOR') {
        if (!_habeasDataAccepted ||
            _documentoUrl == null ||
            _rutUrl == null ||
            _certificacionUrl == null) {
          setState(() {
            _error = 'Debes aceptar Habeas Data y subir todos los documentos.';
            _isLoading = false;
          });
          return;
        }

        final result = await AuthService.completeOnboarding(
          role: 'PRESTADOR',
          documentoIdUrl: _documentoUrl,
          rutUrl: _rutUrl,
          certificacionUrl: _certificacionUrl,
        );

        if (result != null && mounted) {
          Navigator.pushReplacementNamed(context, '/verification-pending');
        } else {
          setState(() => _error = 'Error al guardar el perfil en el servidor');
        }
      } else {
        // CLIENTE
        final result = await AuthService.completeOnboarding(role: 'CLIENTE');
        if (result != null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() => _error = 'Error al guardar el perfil');
        }
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Configura tu Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Cómo deseas usar Belleza App?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona tu perfil de acceso para comenzar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              _buildRoleSelectionCards(),
              const SizedBox(height: 24),
              if (_selectedRole == 'CLIENTE') _buildClientView(),
              if (_selectedRole == 'PRESTADOR') _buildProviderForm(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionCards() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            title: 'Cliente',
            subtitle: 'Quiero agendar citas de belleza',
            icon: Icons.person_outline,
            isSelected: _selectedRole == 'CLIENTE',
            onTap: () => setState(() {
              _selectedRole = 'CLIENTE';
              _error = null;
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _RoleCard(
            title: 'Prestador',
            subtitle: 'Quiero ofrecer mis servicios',
            icon: Icons.storefront_outlined,
            isSelected: _selectedRole == 'PRESTADOR',
            onTap: () => setState(() {
              _selectedRole = 'PRESTADOR';
              _error = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildClientView() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBE6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Icon(Icons.face_retouching_natural,
                  size: 48, color: Color(0xFFC89D93)),
              SizedBox(height: 12),
              Text(
                '¡Excelente elección!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Al ingresar como Cliente podrás ver perfiles de prestadores cercanos en Fontibón, cotizar y agendar tus citas a domicilio en segundos.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC89D93),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Comenzar Exploración',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildProviderForm() {
    final bool allDocsUploaded =
        _documentoUrl != null && _rutUrl != null && _certificacionUrl != null;
    final bool isSubmitEnabled = _habeasDataAccepted && allDocsUploaded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32, color: Color(0xFFE8D7D3)),
        const Text(
          'Requisitos de Verificación Comercial',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'De acuerdo con las regulaciones de la Ley 711 de 2001 de Colombia, es obligatorio adjuntar documentación válida para prestar servicios estéticos.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
        ),
        const SizedBox(height: 20),

        // Carga de Cédula
        _buildDocumentUploadTile(
          title: 'Cédula de Ciudadanía / ID',
          subtitle: 'Documento de identidad nacional',
          isUploaded: _documentoUrl != null,
          isUploading: _uploadingDoc,
          onTap: () => _pickAndUploadDocument('doc'),
        ),
        const SizedBox(height: 12),

        // Carga de RUT
        _buildDocumentUploadTile(
          title: 'Registro Único Tributario (RUT)',
          subtitle: 'Requerido para liquidaciones financieras',
          isUploaded: _rutUrl != null,
          isUploading: _uploadingRut,
          onTap: () => _pickAndUploadDocument('rut'),
        ),
        const SizedBox(height: 12),

        // Carga de Certificado de Bioseguridad
        _buildDocumentUploadTile(
          title: 'Certificado Profesional / Bioseguridad',
          subtitle: 'Cumplimiento Ley 711 de 2001',
          isUploaded: _certificacionUrl != null,
          isUploading: _uploadingCert,
          onTap: () => _pickAndUploadDocument('cert'),
        ),
        const SizedBox(height: 24),

        // Carta informativa de comisiones (Transparencia Financiera)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3EAE8)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFFC89D93), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transparencia Financiera',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'La plataforma retiene una comisión fija del 20% sobre la tarifa bruta del servicio para soporte operativo y se encarga del correspondiente reporte de impuestos estatales.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Checkbox Habeas Data
        CheckboxListTile(
          value: _habeasDataAccepted,
          onChanged: (val) =>
              setState(() => _habeasDataAccepted = val ?? false),
          title: const Text(
            'Acepto la política de protección de datos (Habeas Data - Ley 1581 de 2012) de la aplicación Belleza App.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          activeColor: const Color(0xFFC89D93),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 28),

        ElevatedButton(
          onPressed:
              (_isLoading || !isSubmitEnabled) ? null : _submitOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC89D93),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5CECA),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Enviar para Verificación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x66F5EBE6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUploaded ? const Color(0x80C89D93) : const Color(0xFFF3EAE8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded
                  ? Icons.check_circle_outline
                  : Icons.cloud_upload_outlined,
              color: isUploaded ? Colors.green : const Color(0xFFC89D93),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Color(0xFFC89D93), strokeWidth: 2),
              )
            else if (isUploaded)
              const Text('Cargado',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))
            else
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5EBE6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFC89D93) : const Color(0xFFF3EAE8),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0x0F000000)
                  : const Color(0x05000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFFC89D93) : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black87 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.black54 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
