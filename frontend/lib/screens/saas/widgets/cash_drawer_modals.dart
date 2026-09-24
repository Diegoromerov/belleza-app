// frontend/lib/screens/saas/widgets/cash_drawer_modals.dart
// GO-08.53: SaaS Cash Drawer Modals & Dialogs (SCR-16-M1, M2, M3, M4, DETAIL)

import 'package:flutter/material.dart';
import '../../../models/saas/saas_cash_model.dart';
import '../../../services/saas/saas_cash_service.dart';

/// SCR-16-M4: Modal de Apertura de Turno de Caja
class CashOpenModal extends StatefulWidget {
  final SaasCashService service;
  final VoidCallback onSuccess;

  const CashOpenModal({
    super.key,
    required this.service,
    required this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required SaasCashService service,
    required VoidCallback onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashOpenModal(service: service, onSuccess: onSuccess),
    );
  }

  @override
  State<CashOpenModal> createState() => _CashOpenModalState();
}

class _CashOpenModalState extends State<CashOpenModal> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController(text: '0.00');
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final balance = double.tryParse(_balanceController.text.trim()) ?? -1.0;
    if (balance < 0) {
      setState(() => _errorMessage = 'El monto de apertura debe ser mayor o igual a 0.00');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.service.openSession(
        openingBalance: balance,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e is SaasCashException ? e.message : e.toString().replaceFirst('Exception: ', '');
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
            decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.point_of_sale, color: Colors.indigo, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Apertura de Caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 420,
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
                  'Ingresa el monto de base física con el que se inicia el turno en la gaveta.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_opening_balance'),
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Base Inicial en Efectivo *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final b = double.tryParse(v ?? '');
                    if (b == null || b < 0) return 'Monto de apertura inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_opening_notes'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Observaciones de Apertura (Opcional)',
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
          key: const Key('btn_cancel_open_session'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_open_session'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Abrir Turno'),
        ),
      ],
    );
  }
}

/// SCR-16-M1: Modal de Ingreso Manual de Efectivo (CASH_IN)
class CashInModal extends StatefulWidget {
  final String sessionId;
  final SaasCashService service;
  final VoidCallback onSuccess;

  const CashInModal({
    super.key,
    required this.sessionId,
    required this.service,
    required this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String sessionId,
    required SaasCashService service,
    required VoidCallback onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashInModal(sessionId: sessionId, service: service, onSuccess: onSuccess),
    );
  }

  @override
  State<CashInModal> createState() => _CashInModalState();
}

class _CashInModalState extends State<CashInModal> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'BASE_ADICIONAL';
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'El monto debe ser mayor a 0.00');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.service.addCashIn(
        sessionId: widget.sessionId,
        category: _category,
        amount: amount,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e is SaasCashException ? e.message : e.toString().replaceFirst('Exception: ', '');
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
            child: const Icon(Icons.add_circle_outline, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Registrar Ingreso Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                const Text('Categoría de Ingreso:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('chip_in_BASE_ADICIONAL'),
                      label: const Text('Base Adicional'),
                      selected: _category == 'BASE_ADICIONAL',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'BASE_ADICIONAL');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_in_CAMBIO_SENCILLO'),
                      label: const Text('Cambio Sencillo'),
                      selected: _category == 'CAMBIO_SENCILLO',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'CAMBIO_SENCILLO');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_in_OTRO_INGRESO'),
                      label: const Text('Otro Ingreso'),
                      selected: _category == 'OTRO_INGRESO',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'OTRO_INGRESO');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_cash_in_amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto a Ingresar *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final a = double.tryParse(v ?? '');
                    if (a == null || a <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_cash_in_reason'),
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Justificación *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El motivo es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_cash_in_notes'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas Adicionales (Opcional)',
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
          key: const Key('btn_cancel_cash_in'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_cash_in'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar Ingreso'),
        ),
      ],
    );
  }
}

/// SCR-16-M2: Modal de Egreso Manual de Efectivo (CASH_OUT)
class CashOutModal extends StatefulWidget {
  final String sessionId;
  final SaasCashService service;
  final VoidCallback onSuccess;

  const CashOutModal({
    super.key,
    required this.sessionId,
    required this.service,
    required this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String sessionId,
    required SaasCashService service,
    required VoidCallback onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashOutModal(sessionId: sessionId, service: service, onSuccess: onSuccess),
    );
  }

  @override
  State<CashOutModal> createState() => _CashOutModalState();
}

class _CashOutModalState extends State<CashOutModal> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'GASTO_MENOR';
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'El monto debe ser mayor a 0.00');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.service.addCashOut(
        sessionId: widget.sessionId,
        category: _category,
        amount: amount,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e is SaasCashException ? e.message : e.toString().replaceFirst('Exception: ', '');
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
            child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Registrar Egreso Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                const Text('Categoría de Egreso:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('chip_out_GASTO_MENOR'),
                      label: const Text('Gasto Menor'),
                      selected: _category == 'GASTO_MENOR',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'GASTO_MENOR');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_out_ANTICIPO_PROPINA'),
                      label: const Text('Anticipo Propina'),
                      selected: _category == 'ANTICIPO_PROPINA',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'ANTICIPO_PROPINA');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_out_RETIRO_BANCO'),
                      label: const Text('Retiro a Banco'),
                      selected: _category == 'RETIRO_BANCO',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'RETIRO_BANCO');
                      },
                    ),
                    ChoiceChip(
                      key: const Key('chip_out_OTRO_EGRESO'),
                      label: const Text('Otro Egreso'),
                      selected: _category == 'OTRO_EGRESO',
                      onSelected: (val) {
                        if (val) setState(() => _category = 'OTRO_EGRESO');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_cash_out_amount'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto a Retirar *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final a = double.tryParse(v ?? '');
                    if (a == null || a <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_cash_out_reason'),
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Destino del Dinero *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El motivo es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_cash_out_notes'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas Adicionales (Opcional)',
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
          key: const Key('btn_cancel_cash_out'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_cash_out'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar Egreso'),
        ),
      ],
    );
  }
}

/// SCR-16-M3: Diálogo de Cierre de Turno de Caja (Arqueo / Conteo Físico)
class CashCloseDialog extends StatefulWidget {
  final String sessionId;
  final SaasCashService service;
  final void Function(SaasCashReconciliation reconciliation) onClosed;

  const CashCloseDialog({
    super.key,
    required this.sessionId,
    required this.service,
    required this.onClosed,
  });

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required SaasCashService service,
    required void Function(SaasCashReconciliation reconciliation) onClosed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashCloseDialog(sessionId: sessionId, service: service, onClosed: onClosed),
    );
  }

  @override
  State<CashCloseDialog> createState() => _CashCloseDialogState();
}

class _CashCloseDialogState extends State<CashCloseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countedCashController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countedCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final counted = double.tryParse(_countedCashController.text.trim()) ?? -1.0;
    if (counted < 0) {
      setState(() => _errorMessage = 'El conteo físico debe ser mayor o igual a 0.00');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final rec = await widget.service.closeSession(
        sessionId: widget.sessionId,
        countedCash: counted,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onClosed(rec);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e is SaasCashException ? e.message : e.toString().replaceFirst('Exception: ', '');
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
            decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Cierre de Turno de Caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  'Realiza el arqueo físico del efectivo en la gaveta e ingresa el monto total contado.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input_counted_cash'),
                  controller: _countedCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Efectivo Contado Físicamente *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final c = double.tryParse(v ?? '');
                    if (c == null || c < 0) return 'Monto contado inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('input_closing_notes'),
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Observaciones de Cierre (Opcional)',
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
          key: const Key('btn_cancel_close_session'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('btn_submit_close_session'),
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Cerrar Turno y Conciliar'),
        ),
      ],
    );
  }
}

/// Modal de Resumen y Resultado de Conciliación tras el cierre
class ReconciliationSummaryDialog extends StatelessWidget {
  final SaasCashReconciliation reconciliation;
  final VoidCallback onDismiss;

  const ReconciliationSummaryDialog({
    super.key,
    required this.reconciliation,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required SaasCashReconciliation reconciliation,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReconciliationSummaryDialog(reconciliation: reconciliation, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.green;
    String statusTitle = 'Caja Cuadrada';
    IconData statusIcon = Icons.check_circle;
    String statusExplanation = 'El efectivo contado coincide exactamente con el saldo esperado.';

    if (reconciliation.isSurplus) {
      statusColor = Colors.blue;
      statusTitle = 'Sobrante de Caja';
      statusIcon = Icons.arrow_upward;
      statusExplanation = 'El efectivo contado es mayor al saldo esperado del turno.';
    } else if (reconciliation.isShortage) {
      statusColor = Colors.red;
      statusTitle = 'Faltante de Caja';
      statusIcon = Icons.arrow_downward;
      statusExplanation = 'El efectivo contado es menor al saldo esperado del turno.';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Resumen de Cierre y Conciliación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                        const SizedBox(height: 2),
                        Text(statusExplanation, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _metricRow('Saldo Esperado en Sistema:', '\$${reconciliation.expectedCash.toStringAsFixed(2)}'),
            _metricRow('Efectivo Contado Físicamente:', '\$${reconciliation.countedCash.toStringAsFixed(2)}', isBold: true),
            const Divider(height: 16),
            _metricRow(
              'Diferencia Final:',
              '${reconciliation.difference >= 0 ? "+" : "-"}\$${reconciliation.difference.abs().toStringAsFixed(2)}',
              isBold: true,
              color: statusColor,
              fontSize: 16,
            ),
            if (reconciliation.notes != null && reconciliation.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Observaciones: ${reconciliation.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          key: const Key('btn_dismiss_reconciliation'),
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: const Text('Aceptar y Finalizar'),
        ),
      ],
    );
  }

  Widget _metricRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// SCR-16-DETAIL: Diálogo de Detalle de Turno Histórico
class SessionDetailDialog extends StatelessWidget {
  final SaasCashSession session;
  final List<SaasCashMovement> movements;

  const SessionDetailDialog({
    super.key,
    required this.session,
    required this.movements,
  });

  static Future<void> show(
    BuildContext context, {
    required SaasCashSession session,
    required List<SaasCashMovement> movements,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SessionDetailDialog(session: session, movements: movements),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Detalle de Turno de Caja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _detailRow('ID Turno:', session.id),
                    _detailRow('Apertura:', '${session.openedAt.toLocal()} (${session.openedByUserName ?? "Operador"})'),
                    if (session.closedAt != null)
                      _detailRow('Cierre:', '${session.closedAt!.toLocal()} (${session.closedByUserName ?? "Operador"})'),
                    const Divider(height: 12),
                    _detailRow('Base Inicial:', '\$${session.openingBalance.toStringAsFixed(2)}'),
                    _detailRow('Ventas Efectivo:', '\$${session.cashSalesTotal.toStringAsFixed(2)}'),
                    _detailRow('Ingresos Manuales:', '+\$${session.cashInTotal.toStringAsFixed(2)}'),
                    _detailRow('Egresos Manuales:', '-\$${session.cashOutTotal.toStringAsFixed(2)}'),
                    if (session.expectedCash != null)
                      _detailRow('Saldo Esperado:', '\$${session.expectedCash!.toStringAsFixed(2)}'),
                    if (session.countedCash != null)
                      _detailRow('Efectivo Contado:', '\$${session.countedCash!.toStringAsFixed(2)}', isBold: true),
                    if (session.difference != null)
                      _detailRow(
                        'Diferencia:',
                        '${session.difference! >= 0 ? "+" : ""}\$${session.difference!.toStringAsFixed(2)} (${session.reconciliationStatus ?? ""})',
                        isBold: true,
                        color: session.difference! == 0 ? Colors.green : (session.difference! > 0 ? Colors.blue : Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Movimientos del Turno', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (movements.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: Text('No hay movimientos registrados en este turno.', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mov = movements[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        mov.isCashSale
                            ? Icons.point_of_sale
                            : (mov.isCashIn ? Icons.add_circle : (mov.isCashOut ? Icons.remove_circle : Icons.inventory)),
                        color: mov.isCashSale
                            ? Colors.green
                            : (mov.isCashIn ? Colors.teal : (mov.isCashOut ? Colors.red : Colors.indigo)),
                      ),
                      title: Text(
                        mov.isCashSale
                            ? 'Venta Folio ${mov.ticketNumber ?? ""}'
                            : '${mov.movementType} (${mov.category ?? ""})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        mov.reason ?? mov.notes ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Text(
                        '${mov.isCashOut ? "-" : "+"}\$${mov.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mov.isCashOut ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
