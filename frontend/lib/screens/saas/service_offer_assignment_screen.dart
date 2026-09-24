// frontend/lib/screens/saas/service_offer_assignment_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/hub_salon_model.dart';
import '../../models/saas/service_offer_assignment_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/service_offer_assignment_service.dart';

/// ServiceOfferAssignmentScreen (SCR-08 / NODO-02 UI)
///
/// Pantalla operacional SaaS para la administración de Catálogo de Servicios y Asignaciones de Personal.
///
/// INVARIANTES ARQUITECTÓNICAS:
/// 1. Requiere contexto activo en runtime (ActiveContextHolder).
/// 2. RBAC: Modificaciones permitidas solo a OWNER y MANAGER; modo lectura para PROFESSIONAL/RECEPTIONIST.
/// 3. Target discovery filtrado a roles operativos (PROFESSIONAL, OWNER, MANAGER) con estado ACTIVE.
/// 4. Desasignación pura con confirmación explícita (DELETE no elimina entidades base).
/// 5. Prohibida la eliminación de Service Offers.
class ServiceOfferAssignmentScreen extends StatefulWidget {
  final ServiceOfferAssignmentService? service;
  final String? initialRole;
  final VoidCallback? onNavigateToContextSelector;

  const ServiceOfferAssignmentScreen({
    super.key,
    this.service,
    this.initialRole,
    this.onNavigateToContextSelector,
  });

  @override
  State<ServiceOfferAssignmentScreen> createState() => _ServiceOfferAssignmentScreenState();
}

class _ServiceOfferAssignmentScreenState extends State<ServiceOfferAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late final ServiceOfferAssignmentService _service;
  late final TabController _tabController;

  bool _isLoading = true;
  bool _activeContextMissing = false;
  String? _errorMessage;
  String? _resolvedRole;
  List<ServiceOfferModel> _offers = [];
  List<ServiceAssignmentModel> _assignments = [];
  List<HubStaffMember> _eligibleStaff = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ServiceOfferAssignmentService();
    _resolvedRole = widget.initialRole;
    _tabController = TabController(length: 2, vsync: this);
    _checkContextAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canMutate {
    final role = (_resolvedRole ?? widget.initialRole ?? '').toUpperCase();
    return role == 'OWNER' || role == 'MANAGER';
  }

  void _checkContextAndLoad() {
    if (!ActiveContextHolder().hasActiveContext && widget.initialRole == null) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
      });
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeContextMissing = false;
    });

    try {
      final offersFuture = _service.listServiceOffers();
      final assignmentsFuture = _service.listAssignments();
      final staffFuture = _service.getEligibleStaff();

      final offers = await offersFuture;
      final assignments = await assignmentsFuture;
      final staff = await staffFuture;

      final activeMemId = ActiveContextHolder().activeMembershipId;
      if (activeMemId != null) {
        final currentMember = staff.cast<HubStaffMember?>().firstWhere(
              (m) => m?.membershipId == activeMemId,
              orElse: () => null,
            );
        if (currentMember != null) {
          _resolvedRole = currentMember.role;
        }
      }

      if (!mounted) return;
      setState(() {
        _offers = offers;
        _assignments = assignments;
        _eligibleStaff = staff;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ========================================================
  // ACCIONES DE OFERTAS DE SERVICIO
  // ========================================================

  Future<void> _openCreateOfferDialog() async {
    final result = await showDialog<ServiceOfferFormData>(
      context: context,
      builder: (ctx) => const _ServiceOfferFormDialog(title: 'Nueva Oferta de Servicio'),
    );

    if (result != null) {
      _executeCreateOffer(result);
    }
  }

  Future<void> _openEditOfferDialog(ServiceOfferModel offer) async {
    final result = await showDialog<ServiceOfferFormData>(
      context: context,
      builder: (ctx) => _ServiceOfferFormDialog(
        title: 'Editar Oferta de Servicio',
        initialData: ServiceOfferFormData(
          name: offer.name,
          description: offer.description,
          baseDuration: offer.baseDuration,
          basePrice: offer.basePrice,
        ),
      ),
    );

    if (result != null) {
      _executeEditOffer(offer.id, result);
    }
  }

  Future<void> _executeCreateOffer(ServiceOfferFormData formData) async {
    try {
      final newOffer = await _service.createServiceOffer(formData);
      if (!mounted) return;
      setState(() {
        _offers = [..._offers, newOffer];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta "${newOffer.name}" creada exitosamente.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _executeEditOffer(String offerId, ServiceOfferFormData formData) async {
    try {
      final updated = await _service.updateServiceOffer(offerId, formData);
      if (!mounted) return;
      setState(() {
        _offers = _offers.map((o) => o.id == offerId ? updated : o).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oferta "${updated.name}" actualizada exitosamente.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  // ========================================================
  // ACCIONES DE ASIGNACIONES
  // ========================================================

  Future<void> _openCreateAssignmentDialog({String? preselectedOfferId}) async {
    if (_offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe crear una oferta de servicio.')),
      );
      return;
    }

    if (_eligibleStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay personal operativo activo disponible en la sede.')),
      );
      return;
    }

    final result = await showDialog<ServiceAssignmentFormData>(
      context: context,
      builder: (ctx) => _CreateAssignmentDialog(
        offers: _offers,
        eligibleStaff: _eligibleStaff,
        existingAssignments: _assignments,
        preselectedOfferId: preselectedOfferId,
      ),
    );

    if (result != null) {
      _executeCreateAssignment(result);
    }
  }

  Future<void> _executeCreateAssignment(ServiceAssignmentFormData formData) async {
    try {
      final newAssignment = await _service.createAssignment(formData);
      if (!mounted) return;
      setState(() {
        _assignments = [..._assignments, newAssignment];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asignación creada exitosamente.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _confirmDeleteAssignment(ServiceAssignmentModel assignment) async {
    final offer = _offers.cast<ServiceOfferModel?>().firstWhere(
          (o) => o?.id == assignment.serviceOfferId,
          orElse: () => null,
        );
    final staff = _eligibleStaff.cast<HubStaffMember?>().firstWhere(
          (s) => s?.membershipId == assignment.membershipId,
          orElse: () => null,
        );

    final offerName = offer?.name ?? 'Servicio';
    final staffName = staff?.userName ?? 'Colaborador';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Desasignación'),
        content: Text(
          '¿Desea desvincular a "$staffName" de la oferta "$offerName"?\n\n'
          'Nota: Esta acción solo elimina la asignación operativa. No se eliminará la oferta ni la membresía del personal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desasignar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _executeDeleteAssignment(assignment.id);
    }
  }

  Future<void> _executeDeleteAssignment(String assignmentId) async {
    try {
      await _service.deleteAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _assignments = _assignments.where((a) => a.id != assignmentId).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asignación desvinculada exitosamente.'),
          backgroundColor: Colors.blueGrey.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String rawError) {
    final message = rawError.replaceFirst('Exception: ', '').replaceFirst('ServiceOfferAssignmentException: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================================
  // BUILD PRINCIPAL
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios y Asignaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.room_service),
              text: 'Catálogo (${_offers.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: 'Asignaciones (${_assignments.length})',
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _canMutate ? _buildFloatingActionButton() : null,
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        if (_tabController.index == 0) {
          _openCreateOfferDialog();
        } else {
          _openCreateAssignmentDialog();
        }
      },
      icon: const Icon(Icons.add),
      label: Text(_tabController.index == 0 ? 'Nueva Oferta' : 'Asignar Personal'),
    );
  }

  Widget _buildBody() {
    if (_activeContextMissing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_center_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Sin Sede Activa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Debe seleccionar un contexto de establecimiento activo antes de gestionar los servicios.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToContextSelector,
                icon: const Icon(Icons.store),
                label: const Text('Seleccionar Sede'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando servicios y personal...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el módulo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOffersTab(),
        _buildAssignmentsTab(),
      ],
    );
  }

  // ========================================================
  // TAB 1: CATÁLOGO DE OFERTAS DE SERVICIO
  // ========================================================

  Widget _buildOffersTab() {
    if (_offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay ofertas de servicio registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea los servicios que ofrece tu salón para luego asignarlos a los profesionales.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              if (_canMutate) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openCreateOfferDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primera Oferta'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final staffMap = {for (final m in _eligibleStaff) m.membershipId: m};

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final offerAssignments = _assignments.where((a) => a.serviceOfferId == offer.id).toList();
          final assignedStaffList = offerAssignments
              .map((a) => staffMap[a.membershipId])
              .whereType<HubStaffMember>()
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (offer.description != null && offer.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                offer.description!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_canMutate)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          tooltip: 'Editar Oferta',
                          onPressed: () => _openEditOfferDialog(offer),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.timer_outlined, '${offer.baseDuration} min', Colors.orange),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        Icons.payments_outlined,
                        '\$${offer.basePrice.toStringAsFixed(2)}',
                        Colors.green,
                      ),
                      const Spacer(),
                      _buildInfoBadge(
                        Icons.people_alt_outlined,
                        '${assignedStaffList.length} asignados',
                        Colors.purple,
                      ),
                    ],
                  ),
                  if (assignedStaffList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: assignedStaffList.map((staff) {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: Text(
                              staff.userName.isNotEmpty ? staff.userName[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 11, color: Colors.purple.shade900),
                            ),
                          ),
                          label: Text(
                            '${staff.userName} (${staff.role})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========================================================
  // TAB 2: ASIGNACIONES DE PERSONAL
  // ========================================================

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay asignaciones de servicio activas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Asigna colaboradores operativos a los servicios del catálogo para habilitar su disponibilidad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              if (_canMutate && _offers.isNotEmpty && _eligibleStaff.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openCreateAssignmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Asignar Primer Colaborador'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final offersMap = {for (final o in _offers) o.id: o};
    final staffMap = {for (final s in _eligibleStaff) s.membershipId: s};

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          final offer = offersMap[assignment.serviceOfferId];
          final staff = staffMap[assignment.membershipId];

          final offerName = offer?.name ?? 'Servicio [${assignment.serviceOfferId}]';
          final staffName = staff?.userName ?? 'Colaborador [${assignment.membershipId}]';
          final staffRole = staff?.role ?? 'STAFF';

          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade50,
                child: Icon(Icons.handyman_outlined, color: Colors.purple.shade700),
              ),
              title: Text(offerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [
                  Text(staffName),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      staffRole,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
              trailing: _canMutate
                  ? IconButton(
                      icon: const Icon(Icons.link_off, color: Colors.red),
                      tooltip: 'Desasignar',
                      onPressed: () => _confirmDeleteAssignment(assignment),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade800),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.shade900),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// DIÁLOGO: CREAR / EDITAR OFERTA DE SERVICIO
// ========================================================

class _ServiceOfferFormDialog extends StatefulWidget {
  final String title;
  final ServiceOfferFormData? initialData;

  const _ServiceOfferFormDialog({
    required this.title,
    this.initialData,
  });

  @override
  State<_ServiceOfferFormDialog> createState() => _ServiceOfferFormDialogState();
}

class _ServiceOfferFormDialogState extends State<_ServiceOfferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    _nameController = TextEditingController(text: init?.name ?? '');
    _descriptionController = TextEditingController(text: init?.description ?? '');
    _durationController = TextEditingController(
      text: init != null && init.baseDuration > 0 ? init.baseDuration.toString() : '30',
    );
    _priceController = TextEditingController(
      text: init != null ? init.basePrice.toStringAsFixed(2) : '0.00',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    final data = ServiceOfferFormData(
      name: name,
      description: description.isNotEmpty ? description : null,
      baseDuration: duration,
      basePrice: price,
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio *',
                  hintText: 'Ej. Corte de Cabello Dama',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  if (val.trim().length > 255) {
                    return 'Máximo 255 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Detalles del servicio...',
                ),
                validator: (val) {
                  if (val != null && val.length > 2000) {
                    return 'Máximo 2000 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (min) *',
                        hintText: '30',
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed <= 0 || parsed > 1440) {
                          return '1 a 1440 min';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio Base (\$) *',
                        hintText: '0.00',
                      ),
                      validator: (val) {
                        final parsed = double.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Precio >= 0.00';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ========================================================
// DIÁLOGO: CREAR ASIGNACIÓN
// ========================================================

class _CreateAssignmentDialog extends StatefulWidget {
  final List<ServiceOfferModel> offers;
  final List<HubStaffMember> eligibleStaff;
  final List<ServiceAssignmentModel> existingAssignments;
  final String? preselectedOfferId;

  const _CreateAssignmentDialog({
    required this.offers,
    required this.eligibleStaff,
    required this.existingAssignments,
    this.preselectedOfferId,
  });

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  String? _selectedOfferId;
  String? _selectedMembershipId;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedOfferId = widget.preselectedOfferId ?? (widget.offers.isNotEmpty ? widget.offers.first.id : null);
    _selectedMembershipId = widget.eligibleStaff.isNotEmpty ? widget.eligibleStaff.first.membershipId : null;
  }

  void _submit() {
    if (_selectedOfferId == null || _selectedMembershipId == null) {
      setState(() {
        _validationError = 'Debe seleccionar una oferta y un colaborador.';
      });
      return;
    }

    final isDuplicate = widget.existingAssignments.any(
      (a) => a.serviceOfferId == _selectedOfferId && a.membershipId == _selectedMembershipId,
    );

    if (isDuplicate) {
      setState(() {
        _validationError = 'Este colaborador ya está asignado a la oferta seleccionada.';
      });
      return;
    }

    final data = ServiceAssignmentFormData(
      serviceOfferId: _selectedOfferId!,
      membershipId: _selectedMembershipId!,
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Servicio a Colaborador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione la oferta de servicio y el colaborador operativo que prestará este servicio:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedOfferId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Oferta de Servicio'),
              items: widget.offers.map((offer) {
                return DropdownMenuItem<String>(
                  value: offer.id,
                  child: Text('${offer.name} (${offer.baseDuration} min)'),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedOfferId = val;
                _validationError = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMembershipId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Colaborador Operativo'),
              items: widget.eligibleStaff.map((staff) {
                return DropdownMenuItem<String>(
                  value: staff.membershipId,
                  child: Text('${staff.userName} — ${staff.role}'),
                );
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedMembershipId = val;
                _validationError = null;
              }),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Confirmar Asignación'),
        ),
      ],
    );
  }
}
