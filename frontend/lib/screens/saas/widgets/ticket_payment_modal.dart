// frontend/lib/screens/saas/widgets/ticket_payment_modal.dart
import 'package:flutter/material.dart';
import '../../../models/saas/ticket_model.dart';
import '../../../services/saas/saas_tickets_service.dart';

/// TicketPaymentModal
///
/// Modal para registrar pagos individuales o fraccionados (Split Tender) sobre un ticket OPEN.
class TicketPaymentModal extends StatefulWidget {
  final SaasServiceTicket ticket;
  final SaasTicketsService service;
  final void Function(SaasServiceTicket updatedTicket) onPaymentCompleted;
  final VoidCallback? onNavigateToCashDrawer;

  const TicketPaymentModal({
    super.key,
    required this.ticket,
    required this.service,
    required this.onPaymentCompleted,
    this.onNavigateToCashDrawer,
  });

  static Future<void> show(
    BuildContext context, {
    required SaasServiceTicket ticket,
    required SaasTicketsService service,
    required void Function(SaasServiceTicket updatedTicket) onPaymentCompleted,
    VoidCallback? onNavigateToCashDrawer,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TicketPaymentModal(
        ticket: ticket,
        service: service,
        onPaymentCompleted: onPaymentCompleted,
        onNavigateToCashDrawer: onNavigateToCashDrawer,
      ),
    );
  }

  @override
  State<TicketPaymentModal> createState() => _TicketPaymentModalState();
}

class _TicketPaymentModalState extends State<TicketPaymentModal> {
  final _formKey = GlobalKey<FormState>();

  String _paymentMethod = 'CASH'; // 'CASH' | 'CARD' | 'TRANSFER' | 'OTHER'
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.ticket.balanceDue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'El monto debe ser mayor a 0.00');
      return;
    }

    if (amount > widget.ticket.balanceDue + 0.001) {
      setState(() => _errorMessage = 'El monto no puede superar el saldo pendiente (\$${widget.ticket.balanceDue.toStringAsFixed(2)})');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.service.addPayment(
        widget.ticket.id,
        paymentMethod: _paymentMethod,
        amount: amount,
        referenceCode: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        if (res['ticket'] is SaasServiceTicket) {
          widget.onPaymentCompleted(res['ticket'] as SaasServiceTicket);
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.point_of_sale, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Registrar Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 440,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        if ((_errorMessage!.contains('CASH_DRAWER_NOT_OPEN') ||
                                _errorMessage!.toLowerCase().contains('caja')) &&
                            widget.onNavigateToCashDrawer != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton.icon(
                              key: const Key('btn_ir_a_caja_desde_error'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.point_of_sale, size: 16),
                              label: const Text('Ir a Gestión de Caja (SCR-16)'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onNavigateToCashDrawer!();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                // Resumen de Saldo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo Pendiente:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Text(
                        '\$${widget.ticket.balanceDue.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Método de Pago:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('chip_pay_cash'),
                      label: const Text('Efectivo (CASH)'),
                      selected: _paymentMethod == 'CASH',
                      onSelected: (val) {
                        if (val) setState(() => _paymentMethod = 'CASH');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_pay_card'),
                      label: const Text('Tarjeta (CARD)'),
                      selected: _paymentMethod == 'CARD',
                      onSelected: (val) {
                        if (val) setState(() => _paymentMethod = 'CARD');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_pay_transfer'),
                      label: const Text('Transferencia'),
                      selected: _paymentMethod == 'TRANSFER',
                      onSelected: (val) {
                        if (val) setState(() => _paymentMethod = 'TRANSFER');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_pay_other'),
                      label: const Text('Otro'),
                      selected: _paymentMethod == 'OTHER',
                      onSelected: (val) {
                        if (val) setState(() => _paymentMethod = 'OTHER');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  key: const Key('input_payment_amount'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto a Pagar *', border: OutlineInputBorder()),
                  validator: (v) {
                    final a = double.tryParse(v ?? '');
                    if (a == null || a <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('input_payment_reference'),
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Código / Referencia de Transacción (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_payment'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_payment'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar Pago'),
        ),
      ],
    );
  }
}
