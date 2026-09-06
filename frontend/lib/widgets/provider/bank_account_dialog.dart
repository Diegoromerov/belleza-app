// lib/widgets/provider/bank_account_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/api_service.dart';

class BankAccountFormDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const BankAccountFormDialog({super.key, this.onSuccess});

  @override
  State<BankAccountFormDialog> createState() => _BankAccountFormDialogState();
}

class _BankAccountFormDialogState extends State<BankAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String _tipoCuenta = 'NEQUI';
  String _banco = 'Nequi';
  final _numeroCuentaController = TextEditingController();
  final _titularNombreController = TextEditingController();
  String _titularDocumentoTipo = 'CC';
  final _titularDocumentoNumController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _tiposCuenta = ['NEQUI', 'DAVIPLATA', 'AHORROS', 'CORRIENTE'];
  final List<String> _bancos = [
    'Nequi',
    'Daviplata',
    'Bancolombia',
    'Banco de Bogotá',
    'Davivienda',
    'BBVA Colombia',
    'Lulo Bank',
    'RappiPay',
    'Banco de Occidente',
    'Banco Popular',
    'Scotiabank Colpatria'
  ];

  final List<String> _tiposDoc = ['CC', 'CE', 'NIT', 'PASAPORTE'];

  @override
  void dispose() {
    _numeroCuentaController.dispose();
    _titularNombreController.dispose();
    _titularDocumentoNumController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.registerProviderBankAccount(
        tipoCuenta: _tipoCuenta,
        numeroCuenta: _numeroCuentaController.text.trim(),
        banco: _banco,
        titularNombre: _titularNombreController.text.trim(),
        titularDocumentoTipo: _titularDocumentoTipo,
        titularDocumentoNum: _titularDocumentoNumController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta bancaria SaaS vinculada correctamente para dispersiones'),
            backgroundColor: Color(0xFF059669),
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
                      'CUENTA DE RETIRO SAAS',
                      style: TextStyle(
                        fontFamily: 'Didot',
                        fontSize: 16,
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
                const Text(
                  'Vincula tu cuenta bancaria o billetera digital para recibir transferencias directas de tu saldo acumulado. (Independiente de la pasarela de pagos cliente).',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: LuxeColors.nude600,
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

                // TIPO DE CUENTA Y BANCO
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipoCuenta,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Cuenta',
                          labelStyle: TextStyle(fontSize: 12),
                        ),
                        items: _tiposCuenta
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _tipoCuenta = val;
                              if (val == 'NEQUI') _banco = 'Nequi';
                              if (val == 'DAVIPLATA') _banco = 'Daviplata';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bancos.contains(_banco) ? _banco : _bancos.first,
                        decoration: const InputDecoration(
                          labelText: 'Entidad Financiera',
                          labelStyle: TextStyle(fontSize: 12),
                        ),
                        items: _bancos
                            .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _banco = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // NÚMERO DE CUENTA O CELULAR
                TextFormField(
                  controller: _numeroCuentaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: (_tipoCuenta == 'NEQUI' || _tipoCuenta == 'DAVIPLATA')
                        ? 'Número de Celular (10 dígitos)'
                        : 'Número de Cuenta Bancaria',
                    hintText: (_tipoCuenta == 'NEQUI' || _tipoCuenta == 'DAVIPLATA') ? '3001234567' : '1234567890',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el número de cuenta o celular';
                    if (val.trim().length < 6) return 'Número demasiado corto';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // NOMBRE DEL TITULAR
                TextFormField(
                  controller: _titularNombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Titular de la Cuenta',
                    hintText: 'Ej. Ana Silva',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa el nombre del titular';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // TIPO Y NÚMERO DE DOCUMENTO DEL TITULAR
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<String>(
                        value: _titularDocumentoTipo,
                        decoration: const InputDecoration(labelText: 'Doc'),
                        items: _tiposDoc
                            .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _titularDocumentoTipo = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _titularDocumentoNumController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número de Identificación',
                          hintText: '1018234567',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa el documento';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // BOTÓN DE GUARDADO
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxeColors.nude900,
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
                            'VINCULAR CUENTA DE RETIRO',
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
