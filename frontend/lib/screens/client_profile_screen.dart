// frontend/lib/screens/client_profile_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/audience_service.dart';
import '../shared/mens_theme.dart';
import '../shared/theme.dart';
import '../main.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _email;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      setState(() {
        _nameCtrl.text = profile['full_name'] ?? '';
        _phoneCtrl.text = profile['phone'] ?? '';
        _email = profile['email'] ?? '';
        _avatarUrl = profile['avatar_url'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;

      setState(() {
        _isUploading = true;
        _error = null;
        _message = null;
      });

      final Uint8List bytes = await file.readAsBytes();
      
      // Convertir a Base64 Data URI para almacenar directamente en la BD
      // Esto evita depender del filesystem del servidor (efímero en Railway)
      final ext = file.name.toLowerCase().split('.').last;
      final mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
      };
      final mimeType = mimeTypes[ext] ?? 'image/jpeg';
      final base64String = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$base64String';
      
      await ApiService.updateAvatar(dataUri);

      setState(() {
        _avatarUrl = dataUri;
        _isUploading = false;
        _message = 'Foto de perfil actualizada con éxito';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Error al subir foto: $e';
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
      _message = null;
    });

    try {
      // Nota: El backend tiene la base de datosusuarios y requiere un endpoint para nombre y celular.
      // Simulamos o llamamos al endpoint correspondiente.
      // Como agregamos PATCH /api/users/profile, llamaremos a ese endpoint:
      await ApiService.updateUserProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      setState(() {
        _isSaving = false;
        _message = 'Perfil guardado correctamente';
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al guardar cambios: $e';
      });
    }
  }

  ImageProvider? _getAvatarProvider() {
    if (_avatarUrl == null || _avatarUrl!.isEmpty) return null;
    try {
      if (_avatarUrl!.startsWith('data:')) {
        final parts = _avatarUrl!.split(',');
        if (parts.length > 1) {
          return MemoryImage(base64Decode(parts.last));
        }
      } else {
        return NetworkImage(ApiService.normalizeUrl(_avatarUrl));
      }
    } catch (e) {
      debugPrint('Error parsing avatar image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudienceMode>(
      valueListenable: AudienceService.currentAudience,
      builder: (context, audienceMode, child) {
        final isMen = audienceMode == AudienceMode.men;
        final isDark = isMen || MapSettings.isDark;

        final bgColor = isMen
            ? MensTheme.obsidianBg
            : (isDark ? const Color(0xFF18171C) : Colors.white);
        final cardBgColor = isMen
            ? MensTheme.obsidianCard
            : (isDark ? const Color(0xFF24232B) : Colors.white);
        final textColor = isMen ? MensTheme.textPrimary : (isDark ? Colors.white : Colors.black);
        final primaryColor = isMen ? MensTheme.champagneGold : AppTheme.primary;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        final avatarProvider = _getAvatarProvider();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              'Mi Perfil',
              style: TextStyle(
                  fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18, color: textColor),
            ),
        backgroundColor: cardBgColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context,
              true), // Retorna true para refrescar la pantalla principal
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthService.logout();
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera con Avatar Editable
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF5EBE6), width: 4),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 12,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: const Color(0xFFF5EBE6),
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 40,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadAvatar,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              if (_email == 'usuario_pruebas@gmail.com') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'MODO PRUEBAS: Este usuario no tiene límites de diagnóstico.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // 2. Formularios de edición
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _inputDecoration('Nombre completo', Icons.person_outline),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa tu nombre completo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                    'Teléfono / Celular', Icons.phone_outlined),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa tu número telefónico' : null,
              ),
              const SizedBox(height: 16),
              // Email de lectura no editable
              TextFormField(
                initialValue: _email,
                enabled: false,
                decoration: _inputDecoration(
                        'Correo electrónico (Lectura)', Icons.email_outlined)
                    .copyWith(
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              if (_message != null)
                Text(
                  _message!,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),

              // Botón guardar cambios
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfileChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5CECA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Guardar Cambios',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // 3. Accesos rápidos M3
              const Divider(color: Color(0xFFF3EAE8)),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.calendar_month_outlined,
                title: 'Mis Citas',
                onTap: () => Navigator.pushNamed(context, '/client-bookings'),
              ),
              _buildSettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Mensajes y Chats',
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
              _buildSettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Habeas Data & Términos Legales',
                onTap: _showHabeasDataDialog,
              ),
              _buildSettingsTile(
                icon: Icons.headset_mic_outlined,
                title: 'Centro de Soporte y PQRSF',
                onTap: () => Navigator.pushNamed(context, '/support'),
              ),
              _buildSettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Mis Disputas de Servicio',
                onTap: () => Navigator.pushNamed(context, '/disputes'),
              ),
              const SizedBox(height: 28),

              // Botón cerrar sesión
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.logout();
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Cerrar Sesión',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isMen = AudienceService.isMenMode;
    final isDark = isMen || MapSettings.isDark;
    final cardBg = isMen ? MensTheme.obsidianCard : (isDark ? const Color(0xFF24232B) : Colors.white);
    final borderColor = isMen ? MensTheme.champagneGold.withValues(alpha: 0.2) : (isDark ? const Color(0xFF33313D) : const Color(0xFFF3EAE8));
    final textColor = isMen ? MensTheme.textPrimary : (isDark ? Colors.white : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        onTap: onTap,
      ),
    );
  }

  void _showHabeasDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tratamiento de Datos Personales',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'En cumplimiento de la Ley 1581 de 2012 (Habeas Data) de la República de Colombia, '
            'Belleza App garantiza la confidencialidad, integridad y seguridad de los datos personales suministrados. '
            'Tus datos serán procesados con la única finalidad de coordinar la logística de tus servicios a domicilio '
            'en la localidad de Fontibón y gestionar los correspondientes comprobantes financieros de Wompi.',
            style: TextStyle(height: 1.4, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primary),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: const Color(0xFFF5EBE6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }
}
