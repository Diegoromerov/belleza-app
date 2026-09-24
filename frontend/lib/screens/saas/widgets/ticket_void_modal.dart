// frontend/lib/screens/saas/widgets/ticket_void_modal.dart
import 'package:flutter/material.dart';
import '../../../models/saas/ticket_model.dart';
import '../../../services/saas/saas_tickets_service.dart';

/// TicketVoidModal
///
/// Modal para anular un ticket (DRAFT o OPEN) requiriendo motivo obligatorio. Solo OWNER/MANAGER.
class TicketVoidModal extends StatefulWidget {
  final SaasServiceTicket ticket;
  final SaasTicketsService service;
  final void Function(SaasServiceTicket voidedTicket) onTicketVoided;

  const TicketVoidModal({
    super.key,
    required this.ticket,
    required this.service,
    required this.onTicketVoided,
  });

  static Future<void> show(
    BuildContext context, {
    required SaasServiceTicket ticket,
    required SaasTicketsService service,
    required void Function(SaasServiceTicket voidedTicket) onTicketVoided,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TicketVoidModal(
        ticket: ticket,
        service: service,
        onTicketVoided: onTicketVoided,
      ),
    );
  }

  @override
  State<TicketVoidModal> createState() => _TicketVoidModalState();
}

class _TicketVoidModalState extends State<TicketVoidModal> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final voided = await widget.service.voidTicket(
        widget.ticket.id,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTicketVoided(voided);
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
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Anular Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const Text(
                  'Esta acción anulará permanentemente el ticket y no podrá ser reabierto ni cobrado. Ingresa el motivo de anulación:',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_void_reason'),
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de Anulación *',
                    hintText: 'Ej. Error en cobro, cliente canceló en mostrador...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'El motivo es obligatorio' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_void'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_void'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar Anulación'),
        ),
      ],
    );
  }
}
