// frontend/lib/screens/otp_confirm_screen.dart
// El cliente ingresa el código OTP para confirmar que recibió el servicio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

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
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Ícono animado ────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFFE040FB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE040FB).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),

              const Text(
                'Confirmar servicio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ingresa el código de 6 dígitos que\nrecibirás en esta app',
                style: const TextStyle(color: Colors.white54, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.servicioNombre} · ${widget.prestadorNombre}',
                style: const TextStyle(
                    color: Color(0xFFE040FB), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

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

              // ─── Error ────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _intentosRestantes != null
                              ? 'Código incorrecto. $_intentosRestantes intento(s) restante(s).'
                              : _error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // ─── Botón confirmar ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _codigoLleno && !_loading ? _confirmar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE040FB),
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar y liberar pago',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Nota sobre disputas ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.white38, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al ingresar este código confirmas que recibiste el servicio. '
                        'Tienes 2 horas para reportar inconformidades.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Navegar a abrir disputa
                  Navigator.pushNamed(
                    context,
                    '/dispute',
                    arguments: {'booking_id': widget.bookingId},
                  );
                },
                child: const Text(
                  '¿Problemas con el servicio? Abrir disputa',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
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
        color: hasError ? Colors.red.withOpacity(0.1) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.5)
              : focusNode.hasFocus
                  ? const Color(0xFFE040FB)
                  : Colors.white12,
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: Colors.white,
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
      backgroundColor: const Color(0xFF0F0F1A),
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
                    child: const Icon(Icons.check,
                        color: Color(0xFF10B981), size: 56),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Servicio confirmado!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$servicioNombre con $prestadorNombre',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Color(0xFF10B981), size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'El pago fue liberado al prestador',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (disponibleEn != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Disponible en su wallet en ~2 horas',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Tienes 2 horas para reportar si el servicio\nno cumplió con lo acordado.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE040FB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Calificar servicio',
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
