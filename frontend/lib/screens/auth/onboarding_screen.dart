// frontend/lib/screens/auth/onboarding_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedRole; // 'CLIENTE' or 'PRESTADOR'
  bool _habeasDataAccepted = false;
  bool _terminosAccepted = false;
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

    if (!_habeasDataAccepted || !_terminosAccepted) {
      setState(() {
        _error = 'Debes aceptar la Política de Privacidad (Habeas Data) y los Términos y Condiciones para continuar.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedRole == 'PRESTADOR') {
        final result = await AuthService.completeOnboarding(
          role: 'PRESTADOR',
          documentoIdUrl: _documentoUrl,
          rutUrl: _rutUrl,
          certificacionUrl: _certificacionUrl,
          aceptarHabeasData: _habeasDataAccepted,
          aceptarTerminos: _terminosAccepted,
        );

        if (result != null && mounted) {
          Navigator.pushReplacementNamed(context, '/verification-pending');
        } else {
          setState(() => _error = 'Error al guardar el perfil en el servidor');
        }
      } else {
        // CLIENTE
        final result = await AuthService.completeOnboarding(
          role: 'CLIENTE',
          aceptarHabeasData: _habeasDataAccepted,
          aceptarTerminos: _terminosAccepted,
        );
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

  Future<void> _saveDraft() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await AuthService.completeOnboarding(
        role: 'PRESTADOR',
        documentoIdUrl: _documentoUrl,
        rutUrl: _rutUrl,
        certificacionUrl: _certificacionUrl,
        aceptarHabeasData: _habeasDataAccepted,
        aceptarTerminos: _terminosAccepted,
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Borrador guardado. Puedes completar tu perfil más tarde.'),
            backgroundColor: Color(0xFFC89D93),
          ),
        );
        Navigator.pushReplacementNamed(context, '/verification-pending');
      } else {
        setState(() => _error = 'Error al guardar el borrador');
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
              Text(
                _selectedRole == 'PRESTADOR'
                    ? '¡Completa tu registro y empieza a ganar dinero esta misma semana!'
                    : 'Selecciona tu perfil de acceso para comenzar',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              _buildRoleSelectionCards(),
              if (_selectedRole == 'PRESTADOR') ...[
                const SizedBox(height: 20),
                _buildProgressStepper(),
              ],
              const SizedBox(height: 24),
              if (_selectedRole == 'PRESTADOR') _buildTestimonialCard(),
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
          child: Column(
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 3.0),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/avatar_aura.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Hola! Soy Aura, tu guía personal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Te guiaré para encontrar a tu estilista ideal a domicilio, agendar de manera segura y proteger tus pagos con depósito en garantía en segundos.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _habeasDataAccepted,
          onChanged: (val) => setState(() => _habeasDataAccepted = val ?? false),
          title: const Text(
            'Acepto la Política de Tratamiento de Datos Personales (Habeas Data - Ley 1581 de 2012).',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          activeColor: const Color(0xFFC89D93),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _terminosAccepted,
          onChanged: (val) => setState(() => _terminosAccepted = val ?? false),
          title: const Text(
            'Acepto los Términos y Condiciones de Uso de la plataforma GlowApp.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          activeColor: const Color(0xFFC89D93),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_isLoading || !_habeasDataAccepted || !_terminosAccepted) ? null : _submitOnboarding,
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
              : const Text('Comenzar Exploración',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildProviderForm() {
    final bool atLeastOneDocUploaded =
        _documentoUrl != null || _rutUrl != null || _certificacionUrl != null;
    final bool isSubmitEnabled = _habeasDataAccepted && _terminosAccepted && atLeastOneDocUploaded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32, color: Color(0xFFE8D7D3)),
        const Text(
          'Completa tu perfil profesional',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFFC89D93)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tú decides tu horario: trabaja cuando quieras y donde quieras.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFFC89D93)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pago 100% seguro: depósito en garantía antes de iniciar cada servicio.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.trending_up, color: Color(0xFFC89D93)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Clientes sin esfuerzo: nosotros nos encargamos de la publicidad y tracción.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'La ley colombiana nos pide verificar tu formación profesional — ¡es por tu seguridad y la de tus clientes!',
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
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
          subtitle: 'Opcional · Requerido para liquidaciones financieras',
          isUploaded: _rutUrl != null,
          isUploading: _uploadingRut,
          onTap: () => _pickAndUploadDocument('rut'),
        ),
        const SizedBox(height: 12),

        // Carga de Certificado de Bioseguridad
        _buildDocumentUploadTile(
          title: 'Certificado Profesional / Bioseguridad',
          subtitle: 'Opcional · Cumplimiento Ley 711 de 2001',
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
                      'GlowApp invierte en publicidad para traerte clientes, cubre el procesamiento seguro de pagos con Wompi, provee soporte 24/7 y gestiona el reporte de impuestos estatales. A cambio, retenemos una comisión fija del 20% sobre servicios exitosos. ¡Si tú no ganas, nosotros tampoco!',
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
        CheckboxListTile(
          value: _terminosAccepted,
          onChanged: (val) =>
              setState(() => _terminosAccepted = val ?? false),
          title: const Text(
            'Acepto los Términos y Condiciones y el Contrato de Prestación de Servicios de GlowApp.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          activeColor: const Color(0xFFC89D93),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 4),
          child: Text(
            'Sin contratos de permanencia. Puedes pausar o eliminar tu cuenta en cualquier momento.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
          ),
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
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Serás redirigido a tu panel de seguimiento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nuestro equipo validará tus documentos en menos de 24 horas hábiles. Te notificaremos por la app apenas tu cuenta esté activa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, left: 16, right: 16),
          child: Text(
            'Si necesitamos ajustes en tus documentos, te informaremos con instrucciones claras para resubir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : _saveDraft,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC89D93),
            side: const BorderSide(color: Color(0xFFC89D93)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Guardar borrador y completar más tarde',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildProgressStepper() {
    final int currentStep = _isLoading
        ? 3
        : (_documentoUrl != null || _rutUrl != null || _certificacionUrl != null) ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildStepCircle('✓', 'Elige rol', true),
          Expanded(
            child: Container(
              height: 2,
              color: const Color(0xFFC89D93),
            ),
          ),
          _buildStepCircle('2', 'Documentos', currentStep >= 2),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep >= 3
                  ? const Color(0xFFC89D93)
                  : const Color(0xFFE8D7D3),
            ),
          ),
          _buildStepCircle('3', '¡Listo!', currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStepCircle(String label, String text, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? const Color(0xFFC89D93) : Colors.white,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFC89D93)
                  : const Color(0xFFE8D7D3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isCompleted ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3EAE8)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFC89D93),
                    radius: 20,
                    child: Text(
                      'VP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valentina P.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Estilista en Bogotá',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => const Icon(
                        Icons.star,
                        color: Color(0xFFD4AF37),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '"Desde que me registré en GlowApp, organicé mis horarios y mis ingresos crecieron un 40% en el primer mes. Los pagos son puntuales cada semana y el soporte siempre responde rápido. ¡Es como tener mi propio salón sin pagar arriendo!"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Resultado basado en prestadoras activas durante la fase de prueba.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Datos protegidos (Ley 1581)',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.credit_card_outlined, size: 14, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'Pagos seguros vía Wompi',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUploaded ? const Color(0xFFC89D93) : const Color(0xFFEADCD6),
            width: 1.5,
          ),
          boxShadow: AppTheme.softShadow,
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
          boxShadow: isSelected ? AppTheme.cardShadow : AppTheme.softShadow,
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
