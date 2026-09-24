// frontend/lib/screens/saas/crear_desde_cero_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/crear_desde_cero_model.dart';
import '../../models/saas/hub_salon_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/crear_desde_cero_service.dart';

/// Pantalla / Wizard de Aprovisionamiento Inicial: Crear Desde Cero (SCR-06).
///
/// Flujo transitorio en memoria que captura actividades, catálogo base y asignaciones de staff,
/// compilando el Context Package canónico hacia PRE-NODO 01.
class CrearDesdeCeroWizardScreen extends StatefulWidget {
  final CrearDesdeCeroService? service;
  final List<HubStaffMember>? initialStaff;
  final String? establishmentName;

  const CrearDesdeCeroWizardScreen({
    super.key,
    this.service,
    this.initialStaff,
    this.establishmentName,
  });

  @override
  State<CrearDesdeCeroWizardScreen> createState() => _CrearDesdeCeroWizardScreenState();
}

class _CrearDesdeCeroWizardScreenState extends State<CrearDesdeCeroWizardScreen> {
  late final CrearDesdeCeroService _service;
  final ActiveContextHolder _contextHolder = ActiveContextHolder();

  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  ContextPackageResponse? _successResponse;

  // Estado en memoria del Wizard (Axioma de Transitoriedad)
  final Set<String> _selectedActivities = {'Peluquería'};
  final List<ServiceDraft> _services = [
    const ServiceDraft(
      name: 'Corte de Cabello Estándar',
      category: 'Peluquería',
      durationMinutes: 45,
      price: 35000,
      description: 'Corte y peinado básico',
    ),
  ];
  final Map<String, Set<String>> _staffCategoryMap = {};

  final List<String> _defaultActivityOptions = [
    'Peluquería',
    'Barbería',
    'Uñas & Manicure',
    'Estética Facial',
    'Spa & Masajes',
    'Maquillaje',
    'Colorimetría',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CrearDesdeCeroService();
    if (widget.initialStaff != null) {
      for (final staff in widget.initialStaff!) {
        _staffCategoryMap[staff.membershipId] = {'Peluquería'};
      }
    }
  }

  void _addService(ServiceDraft service) {
    setState(() {
      _services.add(service);
    });
  }

  void _removeService(int index) {
    if (index >= 0 && index < _services.length) {
      setState(() {
        _services.removeAt(index);
      });
    }
  }

  Future<void> _submitBootstrap() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final staffAssignments = _staffCategoryMap.entries.map((entry) {
      return StaffCategoryAssignmentDraft(
        membershipId: entry.key,
        assignedCategories: entry.value.toList(),
      );
    }).toList();

    final request = CrearDesdeCeroBootstrapRequest(
      activities: _selectedActivities.toList(),
      services: _services,
      staffAssignments: staffAssignments,
      decisions: {
        'catalog_mode': 'STANDARD_SETUP',
        'provisioning_source': 'CREAR_DESDE_CERO_v1.0',
      },
    );

    try {
      final response = await _service.bootstrapInitialSetup(request);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _successResponse = response;
        });
      }
    } on CrearDesdeCeroException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Error inesperado: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estName = widget.establishmentName ?? 'Sede Activa';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial de Sede'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _successResponse != null
          ? _buildSuccessView(_successResponse!)
          : _buildWizardStepper(estName),
    );
  }

  Widget _buildWizardStepper(String establishmentName) {
    return Column(
      children: [
        // Header informativo de Sede Activa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Icon(Icons.storefront, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sede: $establishmentName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Paso ${_currentStep + 1} de 4',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        if (_errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: IndexedStack(
            index: _currentStep,
            children: [
              _buildStep1Activities(),
              _buildStep2Services(),
              _buildStep3Staff(),
              _buildStep4Review(),
            ],
          ),
        ),

        // Barra de navegación inferior del Stepper
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                  child: const Text('Anterior'),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep < 3)
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 0 && _selectedActivities.isEmpty) {
                      setState(() => _errorMessage = 'Seleccione al menos una especialidad.');
                      return;
                    }
                    if (_currentStep == 1 && _services.isEmpty) {
                      setState(() => _errorMessage = 'Agregue al menos un servicio base.');
                      return;
                    }
                    setState(() {
                      _errorMessage = null;
                      _currentStep++;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                  child: const Text('Siguiente'),
                )
              else
                ElevatedButton(
                  key: const Key('btn_confirm_handover'),
                  onPressed: _isSubmitting ? null : _submitBootstrap,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirmar y Compilar Handover'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // PASO 1: Especialidades / Actividades
  Widget _buildStep1Activities() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '1. Selecciona las Especialidades del Salón',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Indica las líneas de negocio operativas de esta sede física.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _defaultActivityOptions.map((opt) {
            final isSelected = _selectedActivities.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedActivities.add(opt);
                  } else {
                    _selectedActivities.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // PASO 2: Catálogo de Servicios en Tránsito
  Widget _buildStep2Services() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. Catálogo Base en Tránsito',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              tooltip: 'Agregar Servicio',
              onPressed: () => _showAddServiceDialog(),
            ),
          ],
        ),
        const Text(
          'Define los servicios iniciales para compilación de Handover a Pre-Nodo 01.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_services.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No hay servicios agregados. Presione + para agregar uno.'),
          )
        else
          ..._services.asMap().entries.map((entry) {
            final idx = entry.key;
            final serv = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(serv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${serv.category} • ${serv.durationMinutes} min • \$${serv.price.toStringAsFixed(0)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeService(idx),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '30');
    final priceCtrl = TextEditingController(text: '25000');
    String selectedCat = _selectedActivities.isNotEmpty ? _selectedActivities.first : 'GENERAL';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Servicio en Tránsito'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Servicio *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCat,
                items: (_selectedActivities.isNotEmpty ? _selectedActivities : {'GENERAL'})
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => selectedCat = val ?? 'GENERAL',
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración (minutos) *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio Base (\$) *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final dur = int.tryParse(durCtrl.text) ?? 30;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (name.isNotEmpty) {
                _addService(ServiceDraft(
                  name: name,
                  category: selectedCat,
                  durationMinutes: dur,
                  price: price,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // PASO 3: Asignación de Staff Preexistente
  Widget _buildStep3Staff() {
    final staffList = widget.initialStaff ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '3. Asignación Preliminar de Personal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Asigna las especialidades habilitadas a los miembros activos del equipo.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (staffList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Text(
              'No se detectaron colaboradores adicionales preexistentes en la sede. El titular (Owner) continuará como operador por defecto.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          )
        else
          ...staffList.map((staff) {
            final assigned = _staffCategoryMap[staff.membershipId] ?? {};
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rol: ${staff.role} • ${staff.relationType}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _selectedActivities.map((cat) {
                        final hasCat = assigned.contains(cat);
                        return FilterChip(
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          selected: hasCat,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                (_staffCategoryMap[staff.membershipId] ??= {}).add(cat);
                              } else {
                                _staffCategoryMap[staff.membershipId]?.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // PASO 4: Revisión y Handover
  Widget _buildStep4Review() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '4. Revisión y Handover a Pre-Nodo 01',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Verifica la intención operativa antes de enviar el Context Package.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildReviewCard('Especialidades', '${_selectedActivities.length} seleccionadas (${_selectedActivities.join(', ')})'),
        _buildReviewCard('Servicios en Tránsito', '${_services.length} servicios definidos'),
        _buildReviewCard('Frontera de Entrega', 'PRE-NODO 01 (In-Memory Handover)'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Este proceso compila el paquete de contexto en memoria sin persistir tablas relacionales en frontend.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  // Vista de Éxito tras Handover
  Widget _buildSuccessView(ContextPackageResponse response) {
    final pkg = response.contextPackage;
    final stateStr = pkg?.derivedState ?? 'READY_FOR_PRE_NODE_01';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Aprovisionamiento Exitoso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'El Context Package ha sido compilado y entregado a Pre-Nodo 01 con estado $stateStr.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('btn_return_hub'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al Hub Salón'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
