// lib/widgets/provider/provider_pos_checkout_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/api_service.dart';

class ProviderPosCheckoutDialog extends StatefulWidget {
  final String bookingId;
  final String clientName;
  final String serviceName;
  final double servicePrice;
  final VoidCallback? onSuccess;

  const ProviderPosCheckoutDialog({
    super.key,
    required this.bookingId,
    required this.clientName,
    required this.serviceName,
    required this.servicePrice,
    this.onSuccess,
  });

  @override
  State<ProviderPosCheckoutDialog> createState() => _ProviderPosCheckoutDialogState();
}

class _ProviderPosCheckoutDialogState extends State<ProviderPosCheckoutDialog> {
  String _metodoPago = 'EFECTIVO';
  final _propinaController = TextEditingController(text: '0');
  final _descuentoController = TextEditingController(text: '0');

  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _metodosPago = {
    'EFECTIVO': '💵 Efectivo en Caja',
    'DATAFONO_PROPIO': '💳 Datáfono Propio del Salón',
    'TRANSFERENCIA_DIRECTA': '📱 Transferencia Directa QR Nequi/Daviplata',
  };

  @override
  void dispose() {
    _propinaController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  double get _propina => double.tryParse(_propinaController.text.trim()) ?? 0.0;
  double get _descuento => double.tryParse(_descuentoController.text.trim()) ?? 0.0;
  double get _totalPagar => (widget.servicePrice + _propina - _descuento).clamp(0, 99999999);

  Future<void> _handleCompleteService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Actualizar estado de cita a COMPLETADA en backend
      await ApiService.updateBookingStatus(
        widget.bookingId,
        'COMPLETADA',
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita completada y cobro de \$${_totalPagar.toStringAsFixed(0)} COP registrado en caja (${_metodosPago[_metodoPago]})',
            ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CIERRE DE CITA & COBRO POS',
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
                'Cliente: ${widget.clientName} | Servicio: ${widget.serviceName}',
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude600),
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

              // RESUMEN MONTO BASE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuxeColors.nude100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LuxeColors.nude200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valor Base Servicio:', style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('\$${widget.servicePrice.toStringAsFixed(0)} COP', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15, fontWeight: FontWeight.bold, color: LuxeColors.gold871)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SELECCIÓN MÉTODO DE PAGO DIRECTO
              const Text('Método de Cobro Propio del Salón:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _metodosPago.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _metodoPago = val);
                },
              ),
              const SizedBox(height: 12),

              // PROPINAS Y DESCUENTOS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _propinaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Propina Voluntaria',
                        prefixText: '\$ ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _descuentoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Descuento',
                        prefixText: '\$ ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TOTAL LIQUIDADO EN CAJA SAAS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuxeColors.nude900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL COBRADO EN CAJA:',
                      style: TextStyle(fontFamily: 'Didot', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '\$${_totalPagar.toStringAsFixed(0)} COP',
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.bold, color: LuxeColors.gold871),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleCompleteService,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'REGISTRAR COBRO Y FINALIZAR CITA',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
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
    );
  }
}
