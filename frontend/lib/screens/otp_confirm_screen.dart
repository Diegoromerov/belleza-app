// frontend/lib/screens/otp_confirm_screen.dart
// El cliente ingresa el código OTP para confirmar que recibió el servicio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../shared/theme.dart';

class OtpConfirmScreen extends StatefulWidget {
  final String bookingId;
  final String prestadorNombre;
  final String servicioNombre;
  final double valorBruto;

  const OtpConfirmScreen({
    super.key,
    required this.bookingId,
    required this.prestadorNombre,
    required this.servicioNombre,
    required this.valorBruto,
  });

  @override
  State<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends State<OtpConfirmScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  int? _intentosRestantes;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String get _codigoCompleto => _controllers.map((c) => c.text).join();

  bool get _codigoLleno => _codigoCompleto.length == 6;

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {
      _error = null;
    });
    if (_codigoLleno) _confirmar();
  }

  Future<void> _confirmar() async {
    if (!_codigoLleno || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.post(
        '/api/bookings/${widget.bookingId}/confirm-otp',
        {'codigo': _codigoCompleto},
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _ConfirmacionExitosaScreen(
              prestadorNombre: widget.prestadorNombre,
              servicioNombre: widget.servicioNombre,
              disponibleEn: res['disponible_en'] != null
                  ? DateTime.parse(res['disponible_en'])
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _loading = false;
        _error = msg;
        _intentosRestantes = null;
      });
      // Extraer intentos restantes del mensaje si está disponible
      if (msg.contains('intento')) {
        final match = RegExp(r'(\d+) intento').firstMatch(msg);
        if (match != null) {
          _intentosRestantes = int.tryParse(match.group(1) ?? '');
        }
      }
      // Animación de shake
      _shakeController.forward(from: 0);
      // Limpiar campos
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: AppTheme.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // ─── Ícono animado (Oro Rosa Glow) ────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppTheme.roseGoldSatinGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.glassShadow,
                ),
                child: Icon(Icons.verified_rounded,
                    color: Colors.white, size: 48),
              ),
              SizedBox(height: 32),

              Text(
                'Confirmar servicio',
                style: AppTheme.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Ingresa el código de 6 dígitos que\nrecibirás en esta app',
                style: AppTheme.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '${widget.servicioNombre} · ${widget.prestadorNombre}',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // ─── Campos OTP ───────────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value *
                        (_shakeController.value < 0.5 ? 1 : -1),
                    0,
                  ),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      6,
                      (i) => _OtpField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            hasError: _error != null,
                            onChanged: (v) => _onDigitChanged(i, v),
                          )),
                ),
              ),

              // ─── Error (Terracota desaturado, no rojo punitivo) ─────────
              if (_error != null) ...[
                SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.text, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _intentosRestantes != null
                              ? 'Código incorrecto. $_intentosRestantes intento(s) restante(s).'
                              : _error!,
                          style:
                              TextStyle(color: AppTheme.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32),

              // ─── Botón confirmar ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _codigoLleno && !_loading ? _confirmar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: Colors.black12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirmar y liberar pago',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: 16),

              // ─── Nota sobre disputas ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEADCD6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.text, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al ingresar este código confirmas que recibiste el servicio. '
                        'Tienes 2 horas para reportar inconformidades.',
                        style: TextStyle(color: AppTheme.text, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navegar a abrir disputa
                  Navigator.pushNamed(
                    context,
                    '/dispute',
                    arguments: {'booking_id': widget.bookingId},
                  );
                },
                child: Text(
                  '¿Problemas con el servicio? Abrir disputa',
                  style: TextStyle(color: AppTheme.text, fontSize: 13, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CAMPO OTP INDIVIDUAL ─────────────────────────────────────────────────────

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? AppTheme.accent
              : focusNode.hasFocus
                  ? AppTheme.primary
                  : const Color(0xFFEADCD6),
          width: 2,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: AppTheme.text,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── PANTALLA DE ÉXITO ────────────────────────────────────────────────────────

class _ConfirmacionExitosaScreen extends StatelessWidget {
  final String prestadorNombre;
  final String servicioNombre;
  final DateTime? disponibleEn;

  const _ConfirmacionExitosaScreen({
    required this.prestadorNombre,
    required this.servicioNombre,
    this.disponibleEn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── Checkmark animado ────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (ctx, v, _) => Transform.scale(
                  scale: v,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF10B981), width: 3),
                    ),
                    child: Icon(Icons.check,
                        color: Color(0xFF10B981), size: 56),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                '¡Servicio confirmado!',
                style: AppTheme.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '$servicioNombre con $prestadorNombre',
                style: AppTheme.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEADCD6)),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: Color(0xFF10B981), size: 32),
                    SizedBox(height: 12),
                    Text(
                      'El pago fue liberado al prestador',
                      style: TextStyle(
                          color: AppTheme.text, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (disponibleEn != null) ...[
                      SizedBox(height: 6),
                      Text(
                        'Disponible en su wallet en ~2 horas',
                        style: TextStyle(
                            color: AppTheme.text, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 40),
              Text(
                'Tienes 2 horas para reportar si el servicio\nno cumplió con lo acordado.',
                style: TextStyle(color: AppTheme.text, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Calificar servicio',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
