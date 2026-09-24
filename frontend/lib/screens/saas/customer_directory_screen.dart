// frontend/lib/screens/saas/customer_directory_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/customer_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/saas_customers_service.dart';
import 'widgets/customer_duplicate_modal.dart';
import 'widgets/customer_typeahead.dart';

/// CustomerDirectoryScreen (SCR-13)
///
/// Pantalla principal para la administración del Directorio de Clientes SaaS.
/// Implementa las especificaciones funcionales y de UX ratificadas en GO-08.23.
class CustomerDirectoryScreen extends StatefulWidget {
  final SaasCustomersService? service;
  final String? initialRole;
  final VoidCallback? onNavigateToContextSelector;

  const CustomerDirectoryScreen({
    super.key,
    this.service,
    this.initialRole,
    this.onNavigateToContextSelector,
  });

  @override
  State<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  late final SaasCustomersService _service;
  late final ActiveContextHolder _contextHolder;

  bool _isLoading = true;
  bool _activeContextMissing = false;
  String? _errorMessage;

  // Filtros y Paginación
  String _selectedScope = 'establishment'; // 'establishment' | 'tenant'
  String _selectedStatus = 'ALL'; // 'ALL' | 'ACTIVE' | 'INACTIVE' | 'ARCHIVED'
  int _currentPage = 1;
  final int _limit = 20;
  int _totalPages = 1;
  int _totalCustomers = 0;

  List<SaasCustomerSummary> _customers = [];

  // Búsqueda
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();

  // RBAC
  String get _currentRole => widget.initialRole ?? 'OWNER';
  bool get _isOwnerOrManager => _currentRole == 'OWNER' || _currentRole == 'MANAGER';
  bool get _isProfessionalOnly => _currentRole == 'PROFESSIONAL';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasCustomersService();
    _contextHolder = ActiveContextHolder();
    _checkContextAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkContextAndLoad() {
    if (!_contextHolder.hasActiveContext) {
      setState(() {
        _activeContextMissing = true;
        _isLoading = false;
      });
      return;
    }
    _loadCustomers();
  }

  Future<void> _loadCustomers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _activeContextMissing = false;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final result = await _service.listCustomers(
        scope: _selectedScope,
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _customers = result.customers;
          _totalPages = result.pagination.totalPages;
          _totalCustomers = result.pagination.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is SaasCustomerException ? e.message : e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _openCreateCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerCreateDialog(
        service: _service,
        onCustomerCreated: (newCustomer) {
          _loadCustomers(page: 1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente "${newCustomer.fullName}" registrado exitosamente.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        },
        onUseExisting: (candidate) {
          _openCustomerDetail(candidate.id);
        },
      ),
    );
  }

  void _openCustomerDetail(String customerId) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerDetailDialog(
        customerId: customerId,
        service: _service,
        isOwnerOrManager: _isOwnerOrManager,
        isProfessionalOnly: _isProfessionalOnly,
        onCustomerUpdated: () => _loadCustomers(page: _currentPage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('btn_refresh_customers'),
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCustomers(page: _currentPage),
            tooltip: 'Refrescar',
          ),
          if (!_isProfessionalOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                key: const Key('btn_nuevo_cliente'),
                onPressed: _openCreateCustomerDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_activeContextMissing) {
      return _buildMissingContextState();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('loading_indicator')),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildFiltersBar(),
        Expanded(
          child: _isSearchMode ? _buildSearchResults() : _buildCustomersList(),
        ),
        if (!_isSearchMode && _totalPages > 1) _buildPaginationBar(),
      ],
    );
  }

  Widget _buildMissingContextState() {
    return Center(
      key: const Key('state_active_context_missing'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text(
              'Contexto de Sede Requerido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Debes seleccionar una sede activa para acceder al directorio de clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (widget.onNavigateToContextSelector != null)
              ElevatedButton.icon(
                key: const Key('btn_go_to_context_selector'),
                onPressed: widget.onNavigateToContextSelector,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Seleccionar Sede'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const Key('state_error'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('btn_retry_customers'),
              onPressed: () => _loadCustomers(page: _currentPage),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Barra de búsqueda Typeahead
          CustomerTypeahead(
            service: _service,
            hintText: 'Buscar por nombre, teléfono o email...',
            onCustomerSelected: (customer) {
              _openCustomerDetail(customer.id);
            },
            onAddNewCustomerRequested: !_isProfessionalOnly ? _openCreateCustomerDialog : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Selector de Alcance (Scope)
              if (_isOwnerOrManager) ...[
                const Text('Alcance:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  key: const Key('dropdown_scope'),
                  value: _selectedScope,
                  isDense: true,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'establishment', child: Text('Esta Sede')),
                    DropdownMenuItem(value: 'tenant', child: Text('Todo el Negocio')),
                  ],
                  onChanged: (val) {
                    if (val != null && val != _selectedScope) {
                      setState(() => _selectedScope = val);
                      _loadCustomers(page: 1);
                    }
                  },
                ),
                const SizedBox(width: 16),
              ],

              // Selector de Estado
              const Text('Estado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                key: const Key('dropdown_status_filter'),
                value: _selectedStatus,
                isDense: true,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Activos')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactivos')),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('Archivados')),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedStatus) {
                    setState(() => _selectedStatus = val);
                    _loadCustomers(page: 1);
                  }
                },
              ),
              const Spacer(),
              Text(
                '$_totalCustomers registros',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return const SizedBox();
  }

  Widget _buildCustomersList() {
    if (_customers.isEmpty) {
      return Center(
        key: const Key('state_empty_customers'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay clientes registrados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se encontraron clientes con los filtros seleccionados.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (!_isProfessionalOnly) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('btn_empty_create_customer'),
                  onPressed: _openCreateCustomerDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Registrar Primer Cliente'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('list_customers'),
      padding: const EdgeInsets.all(12),
      itemCount: _customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(SaasCustomerSummary customer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCustomerDetail(customer.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.indigo.shade50,
                child: Text(
                  customer.firstName.isNotEmpty ? customer.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.fullName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.hasLinkedUser) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, size: 16, color: Colors.blue.shade600),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer.phone ?? 'Sin teléfono'} • ${customer.email ?? 'Sin correo'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(customer.status),
                  const SizedBox(height: 4),
                  if (!customer.isAssociatedWithActiveEstablishment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Otra Sede',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Activo';
        break;
      case 'INACTIVE':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Inactivo';
        break;
      case 'ARCHIVED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Archivado';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('btn_prev_page'),
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _loadCustomers(page: _currentPage - 1) : null,
          ),
          Text(
            'Página $_currentPage de $_totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          IconButton(
            key: const Key('btn_next_page'),
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _loadCustomers(page: _currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIÁLOGO DE CREACIÓN DE CLIENTE
// ─────────────────────────────────────────────────────────────
class _CustomerCreateDialog extends StatefulWidget {
  final SaasCustomersService service;
  final void Function(SaasCustomerDetail customer) onCustomerCreated;
  final void Function(CustomerDuplicateCandidate candidate) onUseExisting;

  const _CustomerCreateDialog({
    required this.service,
    required this.onCustomerCreated,
    required this.onUseExisting,
  });

  @override
  State<_CustomerCreateDialog> createState() => _CustomerCreateDialogState();
}

class _CustomerCreateDialogState extends State<_CustomerCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _localNotesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    _localNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool confirmDuplicate = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final customer = await widget.service.createCustomer(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        birthDate: _birthDateController.text,
        notes: _notesController.text,
        localNotes: _localNotesController.text,
        confirmDuplicate: confirmDuplicate,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCustomerCreated(customer);
      }
    } catch (e) {
      if (e is SaasCustomerException && e.isDuplicateWarning) {
        if (mounted) {
          setState(() => _isSaving = false);
          _showDuplicateModal(e.candidates ?? []);
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceFirst('SaasCustomerException: ', '');
            _isSaving = false;
          });
        }
      }
    }
  }

  void _showDuplicateModal(List<CustomerDuplicateCandidate> candidates) {
    CustomerDuplicateModal.show(
      context,
      candidates: candidates,
      onUseExisting: () {
        Navigator.of(context).pop();
        if (candidates.isNotEmpty) {
          widget.onUseExisting(candidates.first);
        }
      },
      onCreateDistinct: () {
        _submit(confirmDuplicate: true);
      },
      onCancel: () {
        // Permanece en el formulario de creación
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Registrar Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                // ÁMBITO CANÓNICO (TENANT)
                const Text('Datos Canónicos del Negocio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('input_first_name'),
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('input_last_name'),
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('input_phone'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('input_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('input_birth_date'),
                  controller: _birthDateController,
                  decoration: const InputDecoration(labelText: 'Fecha de Nacimiento (YYYY-MM-DD)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('input_notes'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notas Globales (Todo el Tenant)', border: OutlineInputBorder()),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // ÁMBITO LOCAL (SEDE ACTIVA)
                const Text('Datos de la Sede Activa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('input_local_notes'),
                  controller: _localNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notas Privadas de esta Sede', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_create'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_create'),
          onPressed: _isSaving ? null : () => _submit(confirmDuplicate: false),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar Cliente'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIÁLOGO DE DETALLE Y EDICIÓN DEL CLIENTE
// ─────────────────────────────────────────────────────────────
class _CustomerDetailDialog extends StatefulWidget {
  final String customerId;
  final SaasCustomersService service;
  final bool isOwnerOrManager;
  final bool isProfessionalOnly;
  final VoidCallback onCustomerUpdated;

  const _CustomerDetailDialog({
    required this.customerId,
    required this.service,
    required this.isOwnerOrManager,
    required this.isProfessionalOnly,
    required this.onCustomerUpdated,
  });

  @override
  State<_CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<_CustomerDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  SaasCustomerDetail? _detail;

  // Controllers para edición canónica
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  String _canonicalStatus = 'ACTIVE';

  // Controllers para edición local
  final _localNotesController = TextEditingController();
  bool _isLocallyActive = true;

  // Historial
  bool _isLoadingHistory = false;
  CustomerHistoryResult? _historyResult;

  // Link User
  final _userIdController = TextEditingController();
  bool _isLinkingUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    _localNotesController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.service.getCustomerById(widget.customerId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _firstNameController.text = detail.firstName;
          _lastNameController.text = detail.lastName ?? '';
          _phoneController.text = detail.phone ?? '';
          _emailController.text = detail.email ?? '';
          _birthDateController.text = detail.birthDate ?? '';
          _notesController.text = detail.notes ?? '';
          _canonicalStatus = detail.status;

          _localNotesController.text = detail.localNotes ?? '';
          _isLocallyActive = detail.isLocallyActive;

          _isLoading = false;
        });
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('SaasCustomerException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final hist = await widget.service.getCustomerHistory(widget.customerId);
      if (mounted) {
        setState(() {
          _historyResult = hist;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _saveCanonical() async {
    try {
      final updated = await widget.service.updateCustomer(
        widget.customerId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        birthDate: _birthDateController.text,
        notes: _notesController.text,
        status: widget.isOwnerOrManager ? _canonicalStatus : null,
      );
      if (mounted) {
        setState(() => _detail = updated);
        widget.onCustomerUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información canónica actualizada exitosamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveLocal() async {
    try {
      if (_detail?.localEstablishment == null) {
        // Asociar
        await widget.service.associateEstablishment(
          widget.customerId,
          localNotes: _localNotesController.text,
          isActive: _isLocallyActive,
        );
      } else {
        // Actualizar
        await widget.service.updateEstablishmentRelation(
          widget.customerId,
          localNotes: _localNotesController.text,
          isActive: _isLocallyActive,
        );
      }
      _loadDetail();
      widget.onCustomerUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relación de sede actualizada exitosamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar sede: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _linkUser() async {
    final uid = _userIdController.text.trim();
    if (uid.isEmpty) return;

    setState(() => _isLinkingUser = true);
    try {
      await widget.service.linkUser(widget.customerId, userId: uid);
      _loadDetail();
      widget.onCustomerUpdated();
      if (mounted) {
        setState(() => _isLinkingUser = false);
        _userIdController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta de usuario B2C vinculada correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLinkingUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al vincular: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unlinkUser() async {
    try {
      await widget.service.unlinkUser(widget.customerId);
      _loadDetail();
      widget.onCustomerUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta de usuario B2C desvinculada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desvincular: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.indigo,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.indigo,
                        tabs: const [
                          Tab(text: 'Canónico'),
                          Tab(text: 'Sede Local'),
                          Tab(text: 'Cuenta B2C'),
                          Tab(text: 'Historial'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCanonicalTab(),
                            _buildLocalTab(),
                            _buildUserLinkTab(),
                            _buildHistoryTab(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('btn_close_detail'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    final detail = _detail!;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            detail.firstName.isNotEmpty ? detail.firstName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.fullName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'ID: ${detail.id}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: detail.status == 'ACTIVE' ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            detail.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: detail.status == 'ACTIVE' ? Colors.green.shade800 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanonicalTab() {
    final isReadOnly = widget.isProfessionalOnly;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('edit_first_name'),
            controller: _firstNameController,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_last_name'),
            controller: _lastNameController,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_phone'),
            controller: _phoneController,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_email'),
            controller: _emailController,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_birth_date'),
            controller: _birthDateController,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Fecha de Nacimiento (YYYY-MM-DD)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_notes'),
            controller: _notesController,
            maxLines: 2,
            enabled: !isReadOnly,
            decoration: const InputDecoration(labelText: 'Notas Globales (Tenant)', border: OutlineInputBorder()),
          ),
          if (widget.isOwnerOrManager) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Estatus Canónico: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  key: const Key('dropdown_canonical_status'),
                  value: _canonicalStatus,
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                    DropdownMenuItem(value: 'ARCHIVED', child: Text('ARCHIVED')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _canonicalStatus = val);
                  },
                ),
              ],
            ),
          ],
          if (!isReadOnly) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const Key('btn_save_canonical'),
              onPressed: _saveCanonical,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Guardar Datos Canónicos'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalTab() {
    final isAssociated = _detail?.localEstablishment != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isAssociated)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Este cliente pertenece al negocio pero no está registrado en la sede activa.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            key: const Key('switch_local_active'),
            title: const Text('Activo en esta Sede'),
            subtitle: const Text('Permite agendar y facturar en este establecimiento'),
            value: _isLocallyActive,
            onChanged: widget.isProfessionalOnly
                ? null
                : (val) => setState(() => _isLocallyActive = val),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('edit_local_notes'),
            controller: _localNotesController,
            maxLines: 3,
            enabled: !widget.isProfessionalOnly,
            decoration: const InputDecoration(
              labelText: 'Notas Privadas de la Sede',
              hintText: 'Preferencias, alergias o notas internas...',
              border: OutlineInputBorder(),
            ),
          ),
          if (!widget.isProfessionalOnly) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              key: const Key('btn_save_local'),
              onPressed: _saveLocal,
              icon: Icon(isAssociated ? Icons.save : Icons.add_business, size: 16),
              label: Text(isAssociated ? 'Guardar Notas Locales' : 'Asociar a esta Sede'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserLinkTab() {
    final detail = _detail!;
    final isLinked = detail.hasLinkedUser;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLinked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green.shade800),
                      const SizedBox(width: 8),
                      const Text(
                        'Cuenta Digital Vinculada',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('User ID: ${detail.userId}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (widget.isOwnerOrManager) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('btn_unlink_user'),
                onPressed: _unlinkUser,
                icon: const Icon(Icons.link_off, color: Colors.red),
                label: const Text('Desvincular Cuenta Digital', style: TextStyle(color: Colors.red)),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_off_outlined, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este cliente no tiene vinculada una cuenta digital GlowApp B2C.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isOwnerOrManager) ...[
              const SizedBox(height: 16),
              const Text('Vincular Cuenta (Requiere User ID B2C):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('input_user_id_link'),
                      controller: _userIdController,
                      decoration: const InputDecoration(labelText: 'User ID (UUID)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('btn_link_user'),
                    onPressed: _isLinkingUser ? null : _linkUser,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    child: _isLinkingUser
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Vincular'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    final hist = _historyResult;
    if (hist == null || !hist.isAttributed) {
      return Center(
        key: const Key('state_unlinked_history'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Sin Historial Atribuido',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Este cliente no tiene vinculada una cuenta digital B2C. El historial derivado requiere vinculación formal de cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (hist.appointments.isEmpty) {
      return const Center(
        child: Text('No hay citas registradas en el historial de este usuario.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      key: const Key('list_customer_history'),
      padding: const EdgeInsets.all(8),
      itemCount: hist.appointments.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final appt = hist.appointments[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.event_available, color: Colors.indigo),
          title: Text(appt.serviceTitle ?? 'Servicio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('${appt.appointmentDate} ${appt.startTime} • ${appt.professionalName ?? "Personal"}', style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
            child: Text(appt.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
