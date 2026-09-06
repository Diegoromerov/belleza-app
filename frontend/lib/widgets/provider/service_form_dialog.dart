// lib/widgets/provider/service_form_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/api_service.dart';

class ServiceFormDialog extends StatefulWidget {
  final Map<String, dynamic>? serviceToEdit;
  final VoidCallback? onSuccess;

  const ServiceFormDialog({
    super.key,
    this.serviceToEdit,
    this.onSuccess,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;

  String _category = 'Cabello';
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Cabello',
    'Uñas',
    'Rostro',
    'Barba',
    'Maquillaje',
    'Estética Corporal',
    'Depilación',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.serviceToEdit;
    _nameController = TextEditingController(text: edit?['nombre'] ?? edit?['name'] ?? '');
    _priceController = TextEditingController(text: edit?['precio']?.toString() ?? edit?['price']?.toString() ?? '');
    _durationController = TextEditingController(text: edit?['duracion_minutos']?.toString() ?? edit?['duration_minutes']?.toString() ?? '45');
    _descriptionController = TextEditingController(text: edit?['descripcion'] ?? edit?['description'] ?? '');

    if (edit?['categoria'] != null && _categories.contains(edit!['categoria'])) {
      _category = edit['categoria'];
    }
    if (edit?['is_active'] != null) {
      _isActive = edit!['is_active'] == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final duration = int.parse(_durationController.text.trim());
      final description = _descriptionController.text.trim();

      if (widget.serviceToEdit == null) {
        // Crear nuevo servicio
        await ApiService.createService(
          name: name,
          price: price,
          durationMinutes: duration,
          description: description.isNotEmpty ? description : null,
          category: _category,
          isActive: _isActive,
        );
      } else {
        // Editar servicio existente
        final serviceId = widget.serviceToEdit!['id'].toString();
        await ApiService.updateService(
          id: serviceId,
          name: name,
          price: price,
          durationMinutes: duration,
          description: description.isNotEmpty ? description : null,
          category: _category,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.serviceToEdit == null ? 'Servicio creado exitosamente' : 'Servicio actualizado'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.serviceToEdit != null;

    return Dialog(
      backgroundColor: LuxeColors.nude50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'EDITAR SERVICIO PRO' : 'NUEVO SERVICIO PRO',
                      style: const TextStyle(
                        fontFamily: 'Didot',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuxeColors.nude900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: LuxeColors.nude900, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Configura los detalles del servicio profesional ofrecido en tu salón o agenda independiente.',
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude600),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                  ),
                  const SizedBox(height: 12),
                ],

                // NOMBRE DEL SERVICIO
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Servicio',
                    hintText: 'Ej. Balayage & Visagismo Pro',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el nombre del servicio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // PRECIO Y DURACIÓN
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio (COP)',
                          prefixText: '\$ ',
                          hintText: '85000',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa precio';
                          final p = double.tryParse(val.trim());
                          if (p == null || p < 0) return 'Precio inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duración (min)',
                          hintText: '45',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa minutos';
                          final d = int.tryParse(val.trim());
                          if (d == null || d <= 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // CATEGORÍA
                DropdownButtonFormField<String>(
                  value: _categories.contains(_category) ? _category : _categories.first,
                  decoration: const InputDecoration(labelText: 'Categoría de Belleza'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 12),

                // DESCRIPCIÓN
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción Corta (Opcional)',
                    hintText: 'Incluye lavado, masaje capilar y cepillado profesional.',
                  ),
                ),
                const SizedBox(height: 12),

                // SWITCH SERVICIO ACTIVO
                Row(
                  children: [
                    const Text('Servicio Activo en Catálogo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      activeTrackColor: LuxeColors.gold871,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxeColors.nude900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isEditing ? 'GUARDAR CAMBIOS' : 'CREAR SERVICIO PRO',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
