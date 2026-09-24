// frontend/lib/screens/saas/service_ticket_checkout_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/ticket_model.dart';
import '../../models/saas/service_offer_assignment_model.dart';
import '../../models/saas/hub_salon_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas/saas_tickets_service.dart';
import '../../services/saas/service_offer_assignment_service.dart';
import 'widgets/customer_typeahead.dart';
import 'widgets/ticket_item_dialog.dart';
import 'widgets/ticket_payment_modal.dart';
import 'widgets/ticket_void_modal.dart';

/// ServiceTicketCheckoutScreen (SCR-12)
///
/// Pantalla operativa de Punto de Venta (POS) y Checkout para GlowApp SaaS.
class ServiceTicketCheckoutScreen extends StatefulWidget {
  final String? ticketId;
  final String? appointmentId;
  final String? preselectedCustomerId;
  final String? initialRole;
  final SaasTicketsService? ticketsService;
  final ServiceOfferAssignmentService? offerService;
  final VoidCallback? onNavigateToContextSelector;
  final VoidCallback? onNavigateToCashDrawer;

  const ServiceTicketCheckoutScreen({
    super.key,
    this.ticketId,
    this.appointmentId,
    this.preselectedCustomerId,
    this.initialRole,
    this.ticketsService,
    this.offerService,
    this.onNavigateToContextSelector,
    this.onNavigateToCashDrawer,
  });

  @override
  State<ServiceTicketCheckoutScreen> createState() => _ServiceTicketCheckoutScreenState();
}

class _ServiceTicketCheckoutScreenState extends State<ServiceTicketCheckoutScreen> {
  late final SaasTicketsService _ticketsService;
  late final ServiceOfferAssignmentService _offerService;
  late final ActiveContextHolder _contextHolder;

  bool _isLoading = true;
  bool _activeContextMissing = false;
  String? _errorMessage;

  SaasServiceTicket? _ticket;
  List<ServiceOfferModel> _availableOffers = [];
  List<HubStaffMember> _activeStaff = [];

  // Formulario de Cliente Walk-in (cuando no hay ticket aún)
  String _clientMode = 'GUEST'; // 'GUEST' | 'REGISTERED'
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _guestEmailController = TextEditingController();
  int? _registeredCustomerUserId;
  String? _registeredCustomerName;

  bool _isCreatingDraft = false;
  bool _isConfirming = false;
  bool _isClosing = false;

  String get _currentRole => widget.initialRole ?? 'OWNER';
  bool get _isOwnerOrManager => _currentRole == 'OWNER' || _currentRole == 'MANAGER';
  bool get _isProfessionalOnly => _currentRole == 'PROFESSIONAL';

  @override
  void initState() {
    super.initState();
    _ticketsService = widget.ticketsService ?? SaasTicketsService();
    _offerService = widget.offerService ?? ServiceOfferAssignmentService();
    _contextHolder = ActiveContextHolder();

    _checkContextAndLoad();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestEmailController.dispose();
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _activeContextMissing = false;
      _errorMessage = null;
    });

    try {
      // 1. Cargar ofertas y staff de la sede
      final offers = await _offerService.listServiceOffers();
      _availableOffers = offers;

      final staff = await _offerService.getEligibleStaff();
      _activeStaff = staff;

      // 2. Cargar ticket existente o iniciar creación
      if (widget.ticketId != null && widget.ticketId!.isNotEmpty) {
        final ticket = await _ticketsService.getTicketById(widget.ticketId!);
        if (mounted) {
          setState(() {
            _ticket = ticket;
            _isLoading = false;
          });
        }
      } else if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        // Modo Cita: Crear DRAFT directamente desde cita
        final created = await _ticketsService.createTicket(
          appointmentId: widget.appointmentId,
          clientMode: 'GUEST', // Default inicial, backend mapea
          guestName: 'Cita en Proceso',
        );
        if (mounted) {
          setState(() {
            _ticket = created;
            _isLoading = false;
          });
        }
      } else {
        // Modo Walk-in: Pantalla lista para capturar cliente y crear borrador
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is SaasTicketException ? e.message : e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createWalkInDraft() async {
    if (_clientMode == 'GUEST' && _guestNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del cliente invitado es obligatorio.')),
      );
      return;
    }

    if (_clientMode == 'REGISTERED' && _registeredCustomerUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un cliente registrado con cuenta digital válida.')),
      );
      return;
    }

    setState(() => _isCreatingDraft = true);
    try {
      final created = await _ticketsService.createTicket(
        clientMode: _clientMode,
        customerUserId: _clientMode == 'REGISTERED' ? _registeredCustomerUserId : null,
        guestName: _clientMode == 'GUEST' ? _guestNameController.text.trim() : null,
        guestPhone: _clientMode == 'GUEST' ? _guestPhoneController.text.trim() : null,
        guestEmail: _clientMode == 'GUEST' ? _guestEmailController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _ticket = created;
          _isCreatingDraft = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmTicket() async {
    if (_ticket == null) return;
    if (_ticket!.items.isEmpty && _ticket!.itemsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un servicio antes de confirmar la cuenta.')),
      );
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final confirmed = await _ticketsService.confirmTicket(_ticket!.id);
      if (mounted) {
        setState(() {
          _ticket = confirmed;
          _isConfirming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket confirmado. Listo para registro de pagos.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _closeTicket() async {
    if (_ticket == null) return;
    setState(() => _isClosing = true);
    try {
      final closed = await _ticketsService.closeTicket(_ticket!.id);
      if (mounted) {
        setState(() {
          _ticket = closed;
          _isClosing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket ${_ticket!.ticketNumber} liquidado y cerrado exitosamente.'), backgroundColor: Colors.green.shade700),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openAddItemDialog() {
    if (_ticket == null) return;
    TicketItemDialog.show(
      context,
      ticketId: _ticket!.id,
      availableOffers: _availableOffers,
      activeStaff: _activeStaff,
      service: _ticketsService,
      onItemSaved: (updated) {
        setState(() => _ticket = updated);
      },
    );
  }

  void _openPaymentModal() {
    if (_ticket == null) return;
    TicketPaymentModal.show(
      context,
      ticket: _ticket!,
      service: _ticketsService,
      onPaymentCompleted: (updated) {
        setState(() => _ticket = updated);
      },
      onNavigateToCashDrawer: widget.onNavigateToCashDrawer,
    );
  }

  void _openVoidModal() {
    if (_ticket == null) return;
    TicketVoidModal.show(
      context,
      ticket: _ticket!,
      service: _ticketsService,
      onTicketVoided: (voided) {
        setState(() => _ticket = voided);
      },
    );
  }

  Future<void> _refreshTicket() async {
    if (_ticket != null) {
      final t = await _ticketsService.getTicketById(_ticket!.id);
      if (mounted) setState(() => _ticket = t);
    } else {
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _ticket != null ? 'Ticket ${_ticket!.ticketNumber}' : 'Nuevo Checkout / Ticket',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('btn_refresh_ticket'),
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTicket,
            tooltip: 'Refrescar',
          ),
          if (_ticket != null && (_ticket!.isDraft || _ticket!.isOpen) && _isOwnerOrManager)
            IconButton(
              key: const Key('btn_void_ticket'),
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: _openVoidModal,
              tooltip: 'Anular Ticket',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_activeContextMissing) return _buildMissingContextState();
    if (_isLoading) return const Center(child: CircularProgressIndicator(key: Key('loading_indicator')));
    if (_errorMessage != null) return _buildErrorState();

    if (_ticket == null) {
      return _buildWalkInCreationForm();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
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
            const Text('Contexto de Sede Requerido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('No hay una sede activa seleccionada.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (widget.onNavigateToContextSelector != null)
              ElevatedButton.icon(
                key: const Key('btn_go_to_context_selector'),
                onPressed: widget.onNavigateToContextSelector,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Seleccionar Sede'),
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
            Text('Error: $_errorMessage', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('btn_retry_ticket'),
              onPressed: _loadInitialData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkInCreationForm() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1, color: Colors.indigo),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Abrir Ticket en Mostrador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('chip_guest_mode'),
                      label: const Text('Cliente Invitado (Guest)'),
                      selected: _clientMode == 'GUEST',
                      onSelected: (val) {
                        if (val) setState(() => _clientMode = 'GUEST');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_registered_mode'),
                      label: const Text('Cliente Registrado'),
                      selected: _clientMode == 'REGISTERED',
                      onSelected: (val) {
                        if (val) setState(() => _clientMode = 'REGISTERED');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_clientMode == 'GUEST') ...[
                  TextField(
                    key: const Key('input_guest_name'),
                    controller: _guestNameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Cliente *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('input_guest_phone'),
                    controller: _guestPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono (Opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('input_guest_email'),
                    controller: _guestEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo (Opcional)', border: OutlineInputBorder()),
                  ),
                ] else ...[
                  CustomerTypeahead(
                    key: const Key('customer_typeahead_checkout'),
                    hintText: 'Buscar en Directorio...',
                    onCustomerSelected: (customer) {
                      setState(() {
                        if (customer.hasLinkedUser) {
                          _registeredCustomerUserId = int.tryParse(customer.userId!);
                          _registeredCustomerName = customer.fullName;
                        } else {
                          _registeredCustomerUserId = null;
                          _registeredCustomerName = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Este cliente no tiene cuenta digital B2C vinculada. Debe cobrarse como Invitado.'),
                            ),
                          );
                        }
                      });
                    },
                  ),
                  if (_registeredCustomerName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Cliente: $_registeredCustomerName (User ID: $_registeredCustomerUserId)')),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('btn_create_walkin_draft'),
                    onPressed: _isCreatingDraft ? null : _createWalkInDraft,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isCreatingDraft
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Comenzar Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildItemsSection(),
              ],
            ),
          ),
        ),
        Container(width: 1, color: Colors.grey.shade200),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildFinancialAndPaymentsPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildHeaderCard(),
          const TabBar(
            labelColor: Colors.indigo,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: 'Consumos e Ítems'),
              Tab(text: 'Cobro y Pagos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(padding: const EdgeInsets.all(12), child: _buildItemsSection()),
                SingleChildScrollView(padding: const EdgeInsets.all(12), child: _buildFinancialAndPaymentsPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final t = _ticket!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: const Icon(Icons.receipt_long, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Folio: ${t.ticketNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Cliente: ${t.clientDisplayName}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),
            _buildStatusBadge(t.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'DRAFT':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'OPEN':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'PAID':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        break;
      case 'CLOSED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'VOID':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: fg)),
    );
  }

  Widget _buildItemsSection() {
    final t = _ticket!;
    final canEdit = (t.isDraft && !_isProfessionalOnly) || (t.isOpen && _isOwnerOrManager);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Servicios y Consumos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (canEdit)
                  ElevatedButton.icon(
                    key: const Key('btn_add_item'),
                    onPressed: _openAddItemDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar Ítem'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (t.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No hay ítems agregados al ticket.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: t.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = t.items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.titleSnapshot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      '${item.quantity}x \$${item.unitPriceSnapshot.toStringAsFixed(2)} • Atiende: ${item.performerName ?? "Colaborador"}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${item.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (t.isDraft && !_isProfessionalOnly) ...[
                          IconButton(
                            key: Key('btn_delete_item_${item.id}'),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () async {
                              final updated = await _ticketsService.deleteItem(t.id, item.id);
                              setState(() => _ticket = updated);
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialAndPaymentsPanel() {
    final t = _ticket!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen Financiero
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Liquidación de la Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 16),
                _rowMetric('Subtotal', '\$${t.subtotalAmount.toStringAsFixed(2)}'),
                if (t.discountAmount > 0)
                  _rowMetric('Descuento', '-\$${t.discountAmount.toStringAsFixed(2)}', color: Colors.green.shade700),
                if (t.taxAmount > 0)
                  _rowMetric('Impuestos', '+\$${t.taxAmount.toStringAsFixed(2)}'),
                if (t.tipAmount > 0)
                  _rowMetric('Propina', '+\$${t.tipAmount.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _rowMetric('Total General', '\$${t.totalAmount.toStringAsFixed(2)}', isBold: true, fontSize: 16),
                _rowMetric('Monto Pagado', '\$${t.paidAmount.toStringAsFixed(2)}', color: Colors.green.shade800),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Pendiente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '\$${t.balanceDue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: t.balanceDue == 0.0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Pagos Registrados
        if (t.payments.isNotEmpty) ...[
          const Text('Pagos Registrados (Split Tender)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: t.payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final p = t.payments[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${p.paymentMethod} ${p.referenceCode != null ? "(${p.referenceCode})" : ""}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('\$${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Botones de Acción de Estado
        if (t.isDraft && !_isProfessionalOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_confirm_ticket'),
              onPressed: _isConfirming ? null : _confirmTicket,
              icon: const Icon(Icons.check_circle_outline),
              label: _isConfirming
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar y Abrir Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),

        if (t.isOpen && !_isProfessionalOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_open_payment_modal'),
              onPressed: _openPaymentModal,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Registrar Pago en Mostrador', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),

        if (t.isPaid && !_isProfessionalOnly)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_close_ticket'),
              onPressed: _isClosing ? null : _closeTicket,
              icon: const Icon(Icons.done_all),
              label: _isClosing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Cerrar y Finalizar Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),

        if (t.isClosed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Ticket Liquidado y Finalizado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),

        if (t.isVoid)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Ticket Anulado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                if (t.voidReason != null) ...[
                  const SizedBox(height: 4),
                  Text('Motivo: ${t.voidReason}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _rowMetric(String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
