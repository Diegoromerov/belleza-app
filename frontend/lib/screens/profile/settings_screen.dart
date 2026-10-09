// lib/screens/profile/settings_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../widgets/profile/luxe_list_tile.dart';
import '../../widgets/profile/colombian_address_builder.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';

class SettingsScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    required this.userEmail,
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricAuthEnabled = true;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  bool _anonymizedAnalytics = true;
  bool _isLoadingPreferences = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
      _errorMessage = null;
    });
    try {
      final headers = await ApiService.getAuthHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/api/users/preferences');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = data['data'];
        if (prefs != null && mounted) {
          setState(() {
            _pushNotifications = prefs['push_enabled'] ?? true;
            _marketingEmails = prefs['marketing_enabled'] ?? false;
            _anonymizedAnalytics = prefs['telemetry_enabled'] ?? true;
            _isLoadingPreferences = false;
          });
          // Actualizar cache de AnalyticsService
          AnalyticsService().invalidateTelemetryCache();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al cargar preferencias: ${response.statusCode}';
            _isLoadingPreferences = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoadingPreferences = false;
        });
      }
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    // Optimistic update
    setState(() {
      switch (key) {
        case 'push_enabled':
          _pushNotifications = value;
          break;
        case 'marketing_enabled':
          _marketingEmails = value;
          break;
        case 'telemetry_enabled':
          _anonymizedAnalytics = value;
          break;
      }
    });

    try {
      final headers = await ApiService.getAuthHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/api/users/preferences');
      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode({key: value}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Revert on error
        if (mounted) {
          setState(() {
            switch (key) {
              case 'push_enabled':
                _pushNotifications = !value;
                break;
              case 'marketing_enabled':
                _marketingEmails = !value;
                break;
              case 'telemetry_enabled':
                _anonymizedAnalytics = !value;
                break;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar preferencia: ${response.statusCode}'),
              backgroundColor: const Color(0xFFB00020),
            ),
          );
        }
      } else {
        if (key == 'telemetry_enabled') {
          AnalyticsService().invalidateTelemetryCache();
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          switch (key) {
            case 'push_enabled':
              _pushNotifications = !value;
              break;
            case 'marketing_enabled':
              _marketingEmails = !value;
              break;
            case 'telemetry_enabled':
              _anonymizedAnalytics = !value;
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: const Color(0xFFB00020),
          ),
        );
      }
    }
  }

  // DIÁLOGO DE CAMBIO DE CONTRASEÑA
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: LuxeColors.nude100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuxeSpacing.md),
            side: const BorderSide(color: LuxeColors.nude200),
          ),
          title: const Text(
            'CAMBIAR CONTRASEÑA',
            style: TextStyle(
              fontFamily: 'Didot',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LuxeColors.nude900,
              letterSpacing: 1.0,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    labelStyle: const TextStyle(fontSize: 13, color: LuxeColors.nude600),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: const TextStyle(fontSize: 13, color: LuxeColors.nude600),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    labelStyle: const TextStyle(fontSize: 13, color: LuxeColors.nude600),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: LuxeColors.nude700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxeColors.nude900,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : () async {
                if (newPasswordController.text.isEmpty ||
                    newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden o están vacías.'),
                      backgroundColor: Color(0xFFB00020),
                    ),
                  );
                  return;
                }
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debes ingresar tu contraseña actual.'),
                      backgroundColor: Color(0xFFB00020),
                    ),
                  );
                  return;
                }
                setDialogState(() => _isLoading = true);
                
                try {
                  final headers = await ApiService.getAuthHeaders();
                  final uri = Uri.parse('${ApiService.baseUrl}/api/auth/change-password');
                  final response = await http.patch(
                    uri,
                    headers: headers,
                    body: json.encode({
                      'current_password': currentPasswordController.text,
                      'new_password': newPasswordController.text,
                    }),
                  ).timeout(const Duration(seconds: 15));

                  if (mounted) {
                    setDialogState(() => _isLoading = false);
                    
                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña actualizada con éxito.'),
                          backgroundColor: LuxeColors.nude900,
                        ),
                      );
                    } else {
                      final data = json.decode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(data['error'] ?? 'Error al cambiar contraseña'),
                          backgroundColor: const Color(0xFFB00020),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    setDialogState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error de conexión: $e'),
                        backgroundColor: const Color(0xFFB00020),
                      ),
                    );
                  }
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  // SOLICITAR SUPRESIÓN DE DATOS (ARCO)
  void _requestDataDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuxeColors.nude100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpacing.md),
          side: const BorderSide(color: LuxeColors.nude200),
        ),
        title: const Text(
          'Eliminar Cuenta Concierge',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
          ),
        ),
        content: const Text(
          'Esta acción creará una solicitud formal de supresión de datos (ARCO) según Ley 1581/2012. '
          'Tu solicitud será revisada por nuestro equipo y recibirás una confirmación con el número de ticket. '
          'La eliminación se ejecutará tras verificación de identidad.',
          style: LuxeTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: LuxeColors.nude900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar Solicitud ARCO',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                color: Color(0xFFB00020),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviando solicitud ARCO...'),
          backgroundColor: LuxeColors.nude900,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final headers = await ApiService.getAuthHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/api/tickets');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'tipo': 'PETICION',
          'categoria': 'seguridad',
          'asunto': 'Solicitud de Supresión de Datos (ARCO) - Ley 1581/2012',
          'descripcion': 'El usuario solicita la supresión total de sus datos personales y biométricos '
              'conforme al Artículo 15 de la Ley Estatutaria 1581 de 2012. '
              'Se requiere revisión y ejecución manual por parte del equipo de privacidad.',
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          final ticketId = data['data']?['id'] ?? 'N/A';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solicitud ARCO registrada. Ticket: $ticketId. Recibirás confirmación por email.'),
              backgroundColor: LuxeColors.nude900,
              duration: const Duration(seconds: 8),
            ),
          );
        } else {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear solicitud: ${data['error'] ?? response.statusCode}'),
              backgroundColor: const Color(0xFFB00020),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: const Color(0xFFB00020),
          ),
        );
      }
    }
  }

  // MODAL TÉRMINOS DE SERVICIO
  void _showTermsOfServiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuxeColors.nude50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(LuxeSpacing.xl),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LuxeColors.nude300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TÉRMINOS DE SERVICIO CONCIERGE',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '1. ACEPTACIÓN DE CONDICIONES\n'
                'Al acceder a la plataforma GlowApp Belleza Luxe y hacer uso de los servicios Concierge, el usuario acepta de forma incondicional los presentes términos de servicio.\n\n'
                '2. SERVICIOS BIOMÉTRICOS & IA\n'
                'El algoritmo de análisis facial Aura AI ofrece sugerencias de cuidado estético. Dichos análisis no constituyen un diagnóstico médico dermatológico oficial.\n\n'
                '3. POLÍTICA DE RESERVAS Y CANCELACIONES\n'
                'Las citas agendadas a través del Concierge pueden ser reprogramadas con hasta 4 horas de anticipación sin penalización.\n\n'
                '4. PROPIEDAD INTELECTUAL\n'
                'Todos los diseños, nombres, marcas y modelos de diagnóstico 3D son propiedad exclusiva del Club Glow Luxe.',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 15,
                  color: LuxeColors.nude800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxeColors.nude900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido & Aceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODAL POLÍTICA DE PRIVACIDAD LEY 1581
  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LuxeColors.nude50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(LuxeSpacing.xl),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LuxeColors.nude300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'POLÍTICA DE PRIVACIDAD LEY 1581 DE 2012',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'TRATAMIENTO DE DATOS PERSONALES Y SENSIBLES\n'
                'GlowApp da estricto cumplimiento a la Ley Estatutaria 1581 de 2012 y al Decreto 1377 de 2013 sobre la protección de datos personales en Colombia.\n\n'
                '1. DATOS RECOPILADOS\n'
                'Recopilamos información de contacto y datos biométricos faciales necesarios para personalizar la experiencia de diagnóstico de belleza.\n\n'
                '2. FINALIDAD DE LA INFORMACIÓN\n'
                'Sus datos serán usados única y exclusivamente para la prestación de servicios estéticos, recomendaciones de productos en GlowStore y agendamiento de citas.\n\n'
                '3. DERECHOS ARCO\n'
                'Como titular, usted tiene derecho a Conocer, Actualizar, Rectificar y Solicitar la Supresión de sus datos personales en cualquier momento a través del panel de configuración de la app.',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 15,
                  color: LuxeColors.nude800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxeColors.nude900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    // SECCIÓN DE DIRECCIONES DE ENTREGA
    Widget _DeliveryAddressesSection() {
      return FutureBuilder<List<dynamic>>(
        future: _fetchDeliveryAddresses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB00020).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB00020).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFB00020)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error al cargar direcciones: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFFB00020)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final addresses = snapshot.data ?? [];

          return Column(
            children: [
              // Lista de direcciones
              if (addresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: LuxeColors.nude100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LuxeColors.nude200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_outlined, size: 48, color: LuxeColors.nude400),
                      const SizedBox(height: 12),
                      const Text(
                        'No tienes direcciones de entrega guardadas',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: LuxeColors.nude700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agrega una dirección para que se autocomplete en el checkout de GlowStore',
                        style: TextStyle(fontSize: 13, color: LuxeColors.nude500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddressBuilder(),
                        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                        label: const Text('Agregar primera dirección'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuxeColors.nude900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...addresses.map((addr) => _buildAddressCard(addr)).toList(),

              const SizedBox(height: 12),

              // Botón agregar nueva dirección
              OutlinedButton.icon(
                onPressed: () => _showAddressBuilder(),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18, color: LuxeColors.nude700),
                label: const Text(
                  'Agregar otra dirección',
                  style: TextStyle(color: LuxeColors.nude700, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  side: BorderSide(color: LuxeColors.nude300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      );
    }

    Future<List<dynamic>> _fetchDeliveryAddresses() async {
      try {
        final headers = await ApiService.getAuthHeaders();
        final uri = Uri.parse('${ApiService.baseUrl}/api/users/delivery-addresses');
        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['data'] ?? [];
        }
        throw Exception('Error ${response.statusCode}');
      } catch (e) {
        throw Exception('Error de conexión: $e');
      }
    }

    Future<void> _showAddressBuilder({Map<String, dynamic>? addressToEdit}) async {
      await showColombianAddressBuilder(
        context: context,
        initialAddress: addressToEdit,
        onSave: (addressData) async {
          try {
            final headers = await ApiService.getAuthHeaders();
            final uri = addressToEdit != null
                ? Uri.parse('${ApiService.baseUrl}/api/users/delivery-addresses/${addressToEdit['id']}')
                : Uri.parse('${ApiService.baseUrl}/api/users/delivery-addresses');
            final method = addressToEdit != null ? 'PATCH' : 'POST';
            
            final request = method == 'POST'
                ? await http.post(uri, headers: headers, body: json.encode(addressData))
                : await http.patch(uri, headers: headers, body: json.encode(addressData));
            
            if (request.statusCode == 200 || request.statusCode == 201) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(addressToEdit != null 
                        ? 'Dirección actualizada correctamente' 
                        : 'Dirección guardada correctamente'),
                    backgroundColor: LuxeColors.nude900,
                  ),
                );
                setState(() {}); // Refresh
              }
            } else {
              final errorData = json.decode(request.body);
              throw Exception(errorData['error'] ?? 'Error al guardar');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFB00020)),
              );
            }
          }
        },
      );
    }

    Widget _buildAddressCard(Map<String, dynamic> addr) {
      final isDefault = addr['es_default'] == true;
      final formatted = addr['direccion_formateada'] ?? _buildFormattedAddress(addr);
      final alias = addr['alias'];

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDefault ? LuxeColors.gold50 : LuxeColors.nude100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault ? LuxeColors.gold200 : LuxeColors.nude200,
            width: isDefault ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con alias y badge default
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDefault ? LuxeColors.gold100 : LuxeColors.nude200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: isDefault ? LuxeColors.gold700 : LuxeColors.nude600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (alias != null && alias.isNotEmpty)
                              Text(
                                alias,
                                style: const TextStyle(
                                  fontFamily: 'CormorantGaramond',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LuxeColors.nude900,
                                ),
                              )
                            else
                              const Text(
                                'Dirección de entrega',
                                style: TextStyle(
                                  fontFamily: 'CormorantGaramond',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LuxeColors.nude900,
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LuxeColors.gold700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PREDETERMINADA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: LuxeColors.nude700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Botón editar discreto
                  IconButton(
                    onPressed: () => _showAddressBuilder(addressToEdit: addr),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: LuxeColors.nude500),
                    tooltip: 'Editar dirección',
                    style: IconButton.styleFrom(
                      backgroundColor: LuxeColors.nude200.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

              // Acciones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    if (!isDefault)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setDefaultAddress(addr['id']),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Establecer por defecto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LuxeColors.gold700,
                            side: BorderSide(color: LuxeColors.gold300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    if (!isDefault) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddressBuilder(addressToEdit: addr),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LuxeColors.nude700,
                          side: BorderSide(color: LuxeColors.nude300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteAddress(addr['id']),
                      icon: const Icon(Icons.delete_outline, size: 18, color: LuxeColors.nude500),
                      tooltip: 'Eliminar',
                      style: IconButton.styleFrom(
                        backgroundColor: LuxeColors.nude200.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

    String _buildFormattedAddress(Map<String, dynamic> addr) {
      final parts = <String>[];
      if (addr['tipo_via'] != null) parts.add(addr['tipo_via']);
      if (addr['numero_principal'] != null) parts.add(addr['numero_principal'].toString());
      if (addr['letra_principal'] != null && addr['letra_principal'].isNotEmpty) parts.add(addr['letra_principal']);
      if (addr['numero_secundario'] != null && addr['numero_secundario'].isNotEmpty) {
        String cruce = '#${addr['numero_secundario']}';
        if (addr['letra_secundaria'] != null && addr['letra_secundaria'].isNotEmpty) {
          cruce += '-${addr['letra_secundaria']}';
        }
        parts.add(cruce);
      }
      if (addr['complemento'] != null && addr['complemento'].isNotEmpty) parts.add(addr['complemento']);
      if (addr['barrio'] != null && addr['barrio'].isNotEmpty) parts.add(addr['barrio']);
      if (addr['ciudad'] != null) parts.add(addr['ciudad']);
      if (addr['departamento'] != null) parts.add(addr['departamento']);
      return parts.join(', ');
    }

    Future<void> _setDefaultAddress(String addressId) async {
      try {
        final headers = await ApiService.getAuthHeaders();
        final uri = Uri.parse('${ApiService.baseUrl}/api/users/delivery-addresses/$addressId/set-default');
        final response = await http.patch(uri, headers: headers).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dirección establecida como predeterminada'), backgroundColor: LuxeColors.nude900),
            );
            setState(() {});
          }
        } else {
          throw Exception('Error al establecer por defecto');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFB00020)),
          );
        }
      }
    }

    Future<void> _deleteAddress(String addressId) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: LuxeColors.nude100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: LuxeColors.nude200)),
          title: const Text('Eliminar dirección', style: TextStyle(fontFamily: 'Didot', color: LuxeColors.nude900)),
          content: const Text('¿Seguro que quieres eliminar esta dirección?', style: TextStyle(color: LuxeColors.nude700)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: LuxeColors.nude700))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Color(0xFFB00020), fontWeight: FontWeight.bold))),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        final headers = await ApiService.getAuthHeaders();
        final uri = Uri.parse('${ApiService.baseUrl}/api/users/delivery-addresses/$addressId');
        final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dirección eliminada'), backgroundColor: LuxeColors.nude900),
            );
            setState(() {});
          }
        } else {
          throw Exception('Error al eliminar');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFB00020)),
          );
        }
      }
    }

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
          'CONFIGURACIÓN & PRIVACIDAD',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingPreferences
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(LuxeSpacing.xl),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB00020).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB00020)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB00020)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFB00020)))),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Color(0xFFB00020), size: 20),
                              onPressed: _loadPreferences,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: LuxeSpacing.xl),
                    ],
                    // SECCIÓN 1: SEGURIDAD DE SESIÓN
                    const Text(
                      'SEGURIDAD & AUTENTICACIÓN',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LuxeColors.nude500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    LuxeProfileTile(
                      icon: Icons.fingerprint,
                      title: 'Autenticación Biométrica',
                      subtitle: 'Ingreso rápido con FaceID / Huella',
                      trailing: LuxeToggle(
                        value: _biometricAuthEnabled,
                        onChanged: (val) => setState(() => _biometricAuthEnabled = val),
                      ),
                    ),
                    LuxeProfileTile(
                      icon: Icons.lock_outline,
                      title: 'Cambiar Contraseña',
                      showDivider: false,
                      onTap: () => _showChangePasswordDialog(context),
                    ),

                    const SizedBox(height: LuxeSpacing.xxl),

                    // SECCIÓN 2: NOTIFICACIONES
                    const Text(
                      'COMUNICACIÓN CONCIERGE',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LuxeColors.nude500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    LuxeProfileTile(
                      icon: Icons.notifications_none,
                      title: 'Notificaciones Push',
                      subtitle: 'Recordatorios de rutina de piel',
                      trailing: LuxeToggle(
                        value: _pushNotifications,
                        onChanged: (val) => _updatePreference('push_enabled', val),
                      ),
                    ),
                    LuxeProfileTile(
                      icon: Icons.mail_outline,
                      title: 'Novedades y Novedades Luxe',
                      subtitle: 'Boletín de lanzamientos de productos',
                      trailing: LuxeToggle(
                        value: _marketingEmails,
                        onChanged: (val) => _updatePreference('marketing_enabled', val),
                      ),
                      showDivider: false,
                    ),

                    const SizedBox(height: LuxeSpacing.xxl),

                    // SECCIÓN 3: PRIVACIDAD Y DATOS SENSIBLES
                    const Text(
                      'DATOS Y TELEMETRÍA',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LuxeColors.nude500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    LuxeProfileTile(
                      icon: Icons.analytics_outlined,
                      title: 'Telemetría Anónima de Uso',
                      subtitle: 'Ayuda a mejorar los modelos de escaneo de Aura',
                      trailing: LuxeToggle(
                        value: _anonymizedAnalytics,
                        onChanged: (val) => _updatePreference('telemetry_enabled', val),
                      ),
                      showDivider: false,
                    ),

                    const SizedBox(height: LuxeSpacing.xxl),

                    // SECCIÓN 4: DIRECCIONES DE ENTREGA
                    const Text(
                      'DIRECCIONES DE ENTREGA',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: LuxeColors.nude500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _DeliveryAddressesSection(),

                    const SizedBox(height: LuxeSpacing.xxl),

                    // ACCIÓN DESTRUCTIVA: ELIMINAR CUENTA (CON TIPOGRAFÍA SERIF ROJA SUTIL)
                    ListTile(
                      onTap: () => _requestDataDeletion(context),
                      leading: const Icon(Icons.delete_outline, color: Color(0xFFB00020)),
                      title: const Text(
                        'Solicitar Supresión de Datos (ARCO)',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 16,
                          color: Color(0xFFB00020),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // INFORMACIÓN LEGAL Y VERSIÓN CON TEXTO NUDE400 Y ENLACES SUBRAYADOS
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'GlowApp Belleza Luxe • v2.4.0 (Build 2026)',
                            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude500),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _showTermsOfServiceModal(context),
                                child: const Text(
                                  'Términos de Servicio',
                                  style: TextStyle(fontSize: 11, color: LuxeColors.nude500, decoration: TextDecoration.underline),
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: LuxeColors.nude500)),
                              GestureDetector(
                                onTap: () => _showPrivacyPolicyModal(context),
                                child: const Text(
                                  'Política de Privacidad Ley 1581',
                                  style: TextStyle(fontSize: 11, color: LuxeColors.nude500, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}