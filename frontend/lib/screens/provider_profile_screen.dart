// frontend/lib/screens/provider_profile_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProviderProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _coverageCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  String? _email;
  String? _avatarUrl;
  String? _verificationStatus;
  int _startHour = 6;
  int _endHour = 20;
  Map<String, dynamic> _weeklySchedule = {
    'lunes': {'activo': true, 'inicio': 6, 'fin': 20},
    'martes': {'activo': true, 'inicio': 6, 'fin': 20},
    'miercoles': {'activo': true, 'inicio': 6, 'fin': 20},
    'jueves': {'activo': true, 'inicio': 6, 'fin': 20},
    'viernes': {'activo': true, 'inicio': 6, 'fin': 20},
    'sabado': {'activo': true, 'inicio': 8, 'fin': 18},
    'domingo': {'activo': false, 'inicio': 8, 'fin': 18},
  };
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
    _bioCtrl.dispose();
    _coverageCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      final prefs = await SharedPreferences.getInstance();

      final localBio =
          prefs.getString('provider_bio') ?? profile['description'] ?? '';
      final localCoverage = prefs.getDouble('provider_coverage_radius') ?? 10.0;
      final localExperience = prefs.getInt('provider_experience_years') ?? 3;

      final start = profile['active_start_hour'] != null
          ? int.tryParse(profile['active_start_hour'].toString()) ?? 6
          : 6;
      final end = profile['active_end_hour'] != null
          ? int.tryParse(profile['active_end_hour'].toString()) ?? 20
          : 20;
      final schedule = profile['weekly_schedule'] != null
          ? Map<String, dynamic>.from(profile['weekly_schedule'])
          : null;

      setState(() {
        _nameCtrl.text = profile['full_name'] ?? '';
        _phoneCtrl.text = profile['phone'] ?? '';
        _bioCtrl.text = localBio;
        _coverageCtrl.text = localCoverage.toString();
        _experienceCtrl.text = localExperience.toString();
        _startHour = start;
        _endHour = end;
        if (schedule != null) {
          _weeklySchedule = schedule;
        }
        _email = profile['email'] ?? '';
        _avatarUrl = profile['avatar_url'] ?? '';
        _verificationStatus = profile['estatus_verificacion'] ?? 'PENDIENTE';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seleccionar Foto de Perfil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: Color(0xFFC89D93)),
                title: Text('Galería de fotos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFFC89D93)),
                title: Text('Cámara de fotos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() {
        _isUploading = true;
        _error = null;
        _message = null;
      });

      final Uint8List bytes = await file.readAsBytes();
      final String uploadedUrl = await ApiService.uploadImage(bytes, file.name);
      await ApiService.updateAvatar(uploadedUrl);

      setState(() {
        _avatarUrl = uploadedUrl;
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_bio', _bioCtrl.text.trim());
      await prefs.setDouble('provider_coverage_radius',
          double.tryParse(_coverageCtrl.text) ?? 10.0);
      await prefs.setInt(
          'provider_experience_years', int.tryParse(_experienceCtrl.text) ?? 3);

      await ApiService.updateUserProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        description: _bioCtrl.text.trim(),
        activeStartHour: _startHour,
        activeEndHour: _endHour,
        weeklySchedule: _weeklySchedule,
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

  double _calculateCompleteness() {
    int totalFields = 6;
    int filledFields = 0;

    if (_nameCtrl.text.trim().isNotEmpty) filledFields++;
    if (_phoneCtrl.text.trim().isNotEmpty) filledFields++;
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) filledFields++;
    if (_bioCtrl.text.trim().isNotEmpty) filledFields++;
    if (_coverageCtrl.text.trim().isNotEmpty) filledFields++;
    if (_experienceCtrl.text.trim().isNotEmpty) filledFields++;

    return filledFields / totalFields;
  }

  Widget _buildCompletenessBar() {
    final percent = _calculateCompleteness();
    final displayPercent = (percent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBE6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del Perfil',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 13),
              ),
              Text(
                '$displayPercent%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC89D93),
                    fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFFC89D93)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge() {
    final status = _verificationStatus?.toUpperCase() ?? 'PENDIENTE';
    Color badgeColor;
    Color textColor;
    IconData icon;
    String text;

    if (status == 'APROBADO') {
      badgeColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      icon = Icons.verified_user_rounded;
      text = 'Verificado / Aprobado';
    } else if (status == 'RECHAZADO') {
      badgeColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.gpp_bad_rounded;
      text = 'Rechazado';
    } else {
      badgeColor = const Color(0xFFFEF9C3);
      textColor = const Color(0xFFCA8A04);
      icon = Icons.pending_actions_rounded;
      text = 'Verificación Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleEditor() {
    final days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo'
    ];
    final dayNames = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5EBE6), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Color(0xFFC89D93), size: 20),
              SizedBox(width: 8),
              Text(
                'Horario de Disponibilidad Semanal',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF4A3E3D)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Configura las horas de inicio y fin para cada día, o apaga los días que no laboras.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24, color: Color(0xFFF5EBE6)),
          ...days.map((key) {
            final conf = _weeklySchedule[key] ??
                {'activo': true, 'inicio': 6, 'fin': 20};
            final bool isActive = conf['activo'] ?? false;
            final int start = conf['inicio'] ?? 6;
            final int end = conf['fin'] ?? 20;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 105,
                    child: Row(
                      children: [
                        Checkbox(
                          value: isActive,
                          activeColor: const Color(0xFFC89D93),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _weeklySchedule[key]['activo'] = val;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            dayNames[key]!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? const Color(0xFF4A3E3D)
                                  : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: isActive
                        ? Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: start,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    labelText: 'De',
                                    labelStyle: TextStyle(fontSize: 10),
                                  ),
                                  items: List.generate(
                                      24,
                                      (h) => DropdownMenuItem(
                                            value: h,
                                            child: Text(
                                                '${h.toString().padLeft(2, '0')}:00',
                                                style: TextStyle(
                                                    fontSize: 12)),
                                          )),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _weeklySchedule[key]['inicio'] = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: end,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    labelText: 'Hasta',
                                    labelStyle: TextStyle(fontSize: 10),
                                  ),
                                  items: List.generate(
                                      24,
                                      (h) => DropdownMenuItem(
                                            value: h,
                                            child: Text(
                                                '${h.toString().padLeft(2, '0')}:00',
                                                style: TextStyle(
                                                    fontSize: 12)),
                                          )),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _weeklySchedule[key]['fin'] = val;
                                      });
                                    }
                                  },
                                  validator: (val) {
                                    if (val != null && val <= start) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Cerrado / No disponible',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 13),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('¿Cerrar sesión?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content:
            Text('¿Estás seguro de que deseas cerrar tu sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      await AuthService.logout();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Perfil de Socio',
          style: TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, true),
              ),
        automaticallyImplyLeading: !widget.isEmbedded,
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
              // completeness bar
              _buildCompletenessBar(),

              // verification status badge
              Center(child: _buildVerificationBadge()),

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
                        backgroundImage:
                            _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? NetworkImage(_avatarUrl!)
                                : null,
                        child: _avatarUrl == null || _avatarUrl!.isEmpty
                            ? Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : 'P',
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
                        onTap: _isUploading ? null : _showPhotoSourceSheet,
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
                onChanged: (v) => setState(() {}),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                    'Teléfono / Celular', Icons.phone_outlined),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa tu número telefónico' : null,
                onChanged: (v) => setState(() {}),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: _inputDecoration(
                    'Bio Profesional', Icons.text_snippet_outlined),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa una breve biografía' : null,
                onChanged: (v) => setState(() {}),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coverageCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                          'Radio Cobertura (km)', Icons.map_outlined),
                      validator: (v) {
                        if (v!.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _experienceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                          'Experiencia (Años)', Icons.work_outline),
                      validator: (v) {
                        if (v!.isEmpty) return 'Requerido';
                        if (int.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
              _buildWeeklyScheduleEditor(),
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

              // 3. Accesos rápidos de Prestador
              const Divider(color: Color(0xFFF3EAE8)),
              SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.inventory_2_outlined,
                title: 'Gestionar Mis Servicios',
                onTap: () => Navigator.pushNamed(context, '/provider/services'),
              ),
              _buildSettingsTile(
                icon: Icons.photo_library_outlined,
                title: 'Mi Portafolio de Trabajo',
                onTap: () =>
                    Navigator.pushNamed(context, '/provider/portfolio'),
              ),
              _buildSettingsTile(
                icon: Icons.gavel_outlined,
                title: 'Habeas Data & Términos Legales',
                onTap: _showHabeasDataDialog,
              ),
              SizedBox(height: 28),

              // Botón cerrar sesión
              OutlinedButton.icon(
                onPressed: _confirmLogout,
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
      floatingLabelBehavior: FloatingLabelBehavior.auto,
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
