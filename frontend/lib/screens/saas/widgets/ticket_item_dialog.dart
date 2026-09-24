// frontend/lib/screens/saas/widgets/ticket_item_dialog.dart
import 'package:flutter/material.dart';
import '../../../models/saas/ticket_model.dart';
import '../../../models/saas/service_offer_assignment_model.dart';
import '../../../models/saas/hub_salon_model.dart';
import '../../../services/saas/saas_tickets_service.dart';

/// TicketItemDialog
///
/// Diálogo modal para agregar o editar un ítem en el ticket (SERVICE o CUSTOM).
class TicketItemDialog extends StatefulWidget {
  final String ticketId;
  final SaasTicketItem? existingItem;
  final List<ServiceOfferModel> availableOffers;
  final List<HubStaffMember> activeStaff;
  final SaasTicketsService service;
  final void Function(SaasServiceTicket updatedTicket) onItemSaved;

  const TicketItemDialog({
    super.key,
    required this.ticketId,
    this.existingItem,
    this.availableOffers = const [],
    this.activeStaff = const [],
    required this.service,
    required this.onItemSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String ticketId,
    SaasTicketItem? existingItem,
    List<ServiceOfferModel> availableOffers = const [],
    List<HubStaffMember> activeStaff = const [],
    required SaasTicketsService service,
    required void Function(SaasServiceTicket updatedTicket) onItemSaved,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TicketItemDialog(
        ticketId: ticketId,
        existingItem: existingItem,
        availableOffers: availableOffers,
        activeStaff: activeStaff,
        service: service,
        onItemSaved: onItemSaved,
      ),
    );
  }

  @override
  State<TicketItemDialog> createState() => _TicketItemDialogState();
}

class _TicketItemDialogState extends State<TicketItemDialog> {
  final _formKey = GlobalKey<FormState>();

  String _itemType = 'SERVICE'; // 'SERVICE' | 'CUSTOM'
  ServiceOfferModel? _selectedOffer;
  String? _selectedPerformerId;

  final _quantityController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0.00');
  final _customTitleController = TextEditingController();
  final _customPriceController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _itemType = item.itemType;
      _selectedPerformerId = item.performedByMembershipId;
      _quantityController.text = item.quantity.toString();
      _discountController.text = item.discountAmount.toStringAsFixed(2);

      if (item.isService && item.serviceOfferId != null) {
        final matches = widget.availableOffers.where((o) => o.id == item.serviceOfferId);
        if (matches.isNotEmpty) {
          _selectedOffer = matches.first;
        }
      } else if (item.isCustom) {
        _customTitleController.text = item.titleSnapshot;
        _customPriceController.text = item.unitPriceSnapshot.toStringAsFixed(2);
      }
    } else {
      if (widget.availableOffers.isNotEmpty) {
        _selectedOffer = widget.availableOffers.first;
      }
      if (widget.activeStaff.isNotEmpty) {
        _selectedPerformerId = widget.activeStaff.first.membershipId;
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _discountController.dispose();
    _customTitleController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPerformerId == null || _selectedPerformerId!.isEmpty) {
      setState(() => _errorMessage = 'Debes seleccionar un profesional ejecutor.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    try {
      if (_isEditing) {
        final res = await widget.service.updateItem(
          widget.ticketId,
          widget.existingItem!.id,
          quantity: qty,
          discountAmount: discount,
          title: _itemType == 'CUSTOM' ? _customTitleController.text.trim() : null,
          unitPrice: _itemType == 'CUSTOM' ? double.tryParse(_customPriceController.text.trim()) : null,
        );
        if (mounted) {
          Navigator.of(context).pop();
          if (res['ticket'] is SaasServiceTicket) {
            widget.onItemSaved(res['ticket'] as SaasServiceTicket);
          }
        }
      } else {
        final res = await widget.service.addItem(
          widget.ticketId,
          itemType: _itemType,
          serviceOfferId: _itemType == 'SERVICE' ? _selectedOffer?.id : null,
          performedByMembershipId: _selectedPerformerId!,
          quantity: qty,
          title: _itemType == 'CUSTOM' ? _customTitleController.text.trim() : null,
          unitPrice: _itemType == 'CUSTOM' ? double.tryParse(_customPriceController.text.trim()) : null,
          discountAmount: discount,
        );
        if (mounted) {
          Navigator.of(context).pop();
          if (res['ticket'] is SaasServiceTicket) {
            widget.onItemSaved(res['ticket'] as SaasServiceTicket);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is SaasTicketException ? e.message : e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEditing ? 'Editar Ítem del Ticket' : 'Agregar Ítem al Ticket',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
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
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                if (!_isEditing) ...[
                  Row(
                    children: [
                      ChoiceChip(
                        key: const Key('chip_type_service'),
                        label: const Text('Servicio de Catálogo'),
                        selected: _itemType == 'SERVICE',
                        onSelected: (val) {
                          if (val) setState(() => _itemType = 'SERVICE');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        key: const Key('chip_type_custom'),
                        label: const Text('Ítem Libre (Custom)'),
                        selected: _itemType == 'CUSTOM',
                        onSelected: (val) {
                          if (val) setState(() => _itemType = 'CUSTOM');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (_itemType == 'SERVICE') ...[
                  if (!_isEditing) ...[
                    const Text('Seleccionar Servicio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ServiceOfferModel>(
                      key: const Key('dropdown_service_offer'),
                      initialValue: _selectedOffer,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: widget.availableOffers.map((offer) {
                        return DropdownMenuItem(
                          value: offer,
                          child: Text('${offer.name} (\$${offer.basePrice.toStringAsFixed(2)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedOffer = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  TextFormField(
                    key: const Key('input_custom_title'),
                    controller: _customTitleController,
                    decoration: const InputDecoration(labelText: 'Concepto / Título *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El concepto es obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('input_custom_price'),
                    controller: _customPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio Unitario *', border: OutlineInputBorder()),
                    validator: (v) {
                      final p = double.tryParse(v ?? '');
                      if (p == null || p < 0) return 'Precio inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Profesional Ejecutor
                if (!_isEditing) ...[
                  const Text('Profesional Ejecutor:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: const Key('dropdown_performer'),
                    initialValue: _selectedPerformerId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: widget.activeStaff.map((staff) {
                      return DropdownMenuItem(
                        value: staff.membershipId,
                        child: Text('${staff.userName} (${staff.role})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPerformerId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('input_item_quantity'),
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder()),
                        validator: (v) {
                          final q = int.tryParse(v ?? '');
                          if (q == null || q < 1) return 'Min. 1';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('input_item_discount'),
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Descuento (\$)', border: OutlineInputBorder()),
                        validator: (v) {
                          final d = double.tryParse(v ?? '');
                          if (d == null || d < 0) return 'Desc. inválido';
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
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_item'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_item'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Guardar Cambios' : 'Agregar Ítem'),
        ),
      ],
    );
  }
}
