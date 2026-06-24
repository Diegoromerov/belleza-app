// frontend/lib/screens/client_profile_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))),
      );
    }

    final avatarProvider = _getAvatarProvider();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context,
              true), // Retorna true para refrescar la pantalla principal
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.grey),
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
                                style: TextStyle(
                                    fontSize: 40,
                                    color: Color(0xFFC89D93),
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
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFC89D93),
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // 2. Formularios de edición
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _inputDecoration('Nombre completo', Icons.person_outline),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa tu nombre completo' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                    'Teléfono / Celular', Icons.phone_outlined),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa tu número telefónico' : null,
              ),
              SizedBox(height: 16),
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
              SizedBox(height: 24),

              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              if (_message != null)
                Text(
                  _message!,
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 16),

              // Botón guardar cambios
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfileChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89D93),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5CECA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Guardar Cambios',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 24),

              // 3. Accesos rápidos M3
              const Divider(color: Color(0xFFF3EAE8)),
              SizedBox(height: 12),
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
              SizedBox(height: 28),

              // Botón cerrar sesión
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.logout();
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: Icon(Icons.logout, color: Colors.redAccent),
                label: Text('Cerrar Sesión',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC89D93)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      onTap: onTap,
    );
  }

  void _showHabeasDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tratamiento de Datos Personales',
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
            child: Text('Entendido',
                style: TextStyle(
                    color: Color(0xFFC89D93), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFC89D93)),
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
        borderSide: BorderSide(color: Color(0xFFC89D93), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }
}
