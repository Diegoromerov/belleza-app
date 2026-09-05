// lib/widgets/provider/payout_request_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/api_service.dart';

class PayoutRequestDialog extends StatefulWidget {
  final double availableBalance;
  final VoidCallback? onSuccess;

  const PayoutRequestDialog({
    super.key,
    required this.availableBalance,
    this.onSuccess,
  });

  @override
  State<PayoutRequestDialog> createState() => _PayoutRequestDialogState();
}

class _PayoutRequestDialogState extends State<PayoutRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final double monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
    if (monto <= 0) return;

    if (monto > widget.availableBalance) {
      setState(() {
        _errorMessage = 'El monto supera el saldo disponible (\$${widget.availableBalance.toStringAsFixed(0)} COP)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.requestProviderPayout(monto: monto);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud de retiro por \$${monto.toStringAsFixed(0)} COP enviada a dispersión'),
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
                    const Text(
                      'SOLICITAR RETIRO DE FONDOS',
                      style: TextStyle(
                        fontFamily: 'Didot',
                        fontSize: 15,
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
                Text(
                  'Saldo Disponible: \$${widget.availableBalance.toStringAsFixed(0)} COP',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.gold871,
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto a Retirar (COP)',
                    hintText: 'Ej. 200000',
                    prefixText: '\$ ',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el monto a retirar';
                    final monto = double.tryParse(val.trim());
                    if (monto == null || monto <= 0) return 'Monto inválido';
                    if (monto < 20000) return 'El monto mínimo de retiro es \$20,000 COP';
                    if (monto > widget.availableBalance) return 'Supera el saldo disponible';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'El retiro se procesará directamente hacia tu cuenta bancaria o billetera digital registrada en el módulo SaaS.',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    color: LuxeColors.nude600,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'CONFIRMAR SOLICITUD DE RETIRO',
                            style: TextStyle(
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
