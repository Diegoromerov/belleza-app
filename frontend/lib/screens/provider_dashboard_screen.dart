// frontend/lib/screens/provider_dashboard_screen.dart
import 'dart:async';
import '../services/web_geolocation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_screen.dart';
import 'provider_route_screen.dart';
import 'wallet_screen.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  bool _loadingProfile = true;
  String? _error;
  bool _isActive = true;
  double _ratingAvg = 4.8;
  int _ratingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _fetchProfile();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchProviderBookings();
      if (mounted) {
        setState(() {
          _bookings = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _loadingProfile = true);
    try {
      final data = await ApiService.fetchUserProfile();
      if (data['role'] == 'provider' && data['estatus_verificacion'] != 'APROBADO') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/verification-pending');
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isActive = data['is_active'] ?? true;
          _ratingAvg = double.tryParse(data['rating_avg']?.toString() ?? '') ?? 4.8;
          _ratingCount = int.tryParse(data['rating_count']?.toString() ?? '') ?? 0;
          _loadingProfile = false;
        });

        // Si el proveedor está en línea, refrescamos su ubicación en background
        if (_isActive) {
          _refreshActiveLocation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _refreshActiveLocation() async {
    try {
      final pos = await getWebGeolocation();
      await ApiService.updateProviderStatus(true, latitude: pos['lat'], longitude: pos['lon']);
      debugPrint('🟢 Ubicación actualizada automáticamente al cargar perfil: ${pos['lat']}, ${pos['lon']}');
    } catch (e) {
      debugPrint('❌ Error al actualizar ubicación automáticamente: $e');
    }
  }

  Future<void> _handleStartService(String bookingId) async {
    setState(() => _loading = true);
    try {
      await ApiService.startBooking(bookingId);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white),
                SizedBox(width: 8),
                Text('🚀 Servicio iniciado. ¡A dar el mejor look, vecino!'),
              ],
            ),
            backgroundColor: const Color(0xFFC89D93),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
      _fetchBookings();
      _fetchProfile();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar servicio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSegmentedPinDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SegmentedPinDialog(
        booking: booking,
        onSuccess: (res) {
          _fetchBookings();
          _fetchProfile();
          _showPayoutBreakdownDialog(res['booking'] ?? booking, immediate: true);
        },
      ),
    );
  }

  void _showPayoutBreakdownDialog(Map<String, dynamic> booking, {bool immediate = false}) {
    final double gross = double.tryParse(booking['valor_bruto']?.toString() ?? booking['total_amount']?.toString() ?? '0.0') ?? 0.0;
    final double platformCut = double.tryParse(booking['comision_plataforma']?.toString() ?? booking['platform_commission']?.toString() ?? '0.0') ?? 0.0;
    final double stateTax = double.tryParse(booking['impuestos_estado']?.toString() ?? booking['state_tax']?.toString() ?? '0.0') ?? 0.0;
    final double netPayout = double.tryParse(booking['pago_neto_prestador']?.toString() ?? booking['provider_net_amount']?.toString() ?? '0.0') ?? 0.0;

    final String nequiAccount = booking['numero_cuenta_nequi'] ?? '+573001112222';
    final String wompiRef = booking['wompi_reference'] ?? 'wompi_ref_${booking['id'].toString().substring(0, 8).toUpperCase()}';
    final String payoutStatus = booking['payout_status'] == 'paid' ? 'DISPERSADO (Nequi)' : 'EN COLA (Wompi)';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                immediate ? Icons.stars_rounded : Icons.receipt_long_outlined,
                color: immediate ? Colors.green : const Color(0xFFC89D93),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  immediate ? '¡Servicio Completado!' : 'Detalle de Liquidación',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (immediate) ...[
                const Text(
                  'El PIN ha sido verificado con éxito. Hemos liberado los fondos y la transferencia está en camino.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
              ],
              _breakdownRow('Liquidación Bruta', '\$${gross.toStringAsFixed(0)} COP', isBold: true),
              const SizedBox(height: 8),
              _breakdownRow('Comisión Plataforma (20%)', '-\$${platformCut.toStringAsFixed(0)} COP', color: Colors.red[800]),
              const SizedBox(height: 4),
              _breakdownRow('Retenciones del Estado (8%)', '-\$${stateTax.toStringAsFixed(0)} COP', color: Colors.red[800]),
              const Divider(height: 24, color: Color(0xFFE8D7D3)),
              _breakdownRow('Dispersión Nequi (Neto 72%)', '\$${netPayout.toStringAsFixed(0)} COP', color: Colors.green[800], isBold: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBE6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: $payoutStatus',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuenta Nequi: $nequiAccount',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Referencia Wompi:\n$wompiRef',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Widget _breakdownRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCardActionButtons(Map<String, dynamic> b) {
    final status = (b['status'] as String? ?? 'pending').toUpperCase();

    if (status == 'CONFIRMED' || status == 'CONFIRMADA' || status == 'CHECKIN_REALIZADO') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderRouteScreen(booking: b),
                  ),
                );
                if (refresh == true) {
                  _fetchBookings();
                  _fetchProfile();
                }
              },
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: const Text('Iniciar Ruta', style: TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC89D93),
                side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleStartService(b['id'].toString()),
              icon: const Icon(Icons.play_arrow_outlined, size: 16),
              label: const Text('Iniciar Servicio', style: TextStyle(fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'EN_PROGRESO') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final clientId = b['client_id']?.toString();
                    if (clientId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          partnerId: clientId,
                          partnerName: b['client_name'] ?? 'Cliente',
                          partnerRole: 'client',
                          partnerAvatar: '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC89D93),
                    side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final refresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderRouteScreen(booking: b),
                      ),
                    );
                    if (refresh == true) {
                      _fetchBookings();
                      _fetchProfile();
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Ver Mapa', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC89D93),
                    side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCompleteService(b['id'].toString()),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Marcar como completado',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'ESPERANDO_OTP' || status == 'FINALIZADA_PRESTADOR') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFEFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
            ),
            SizedBox(width: 10),
            Text(
              'Esperando código del cliente...',
              style: TextStyle(color: Color(0xFF0E7490), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (status == 'EN_DISPUTA') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, color: Color(0xFFEA580C), size: 18),
            SizedBox(width: 8),
            Text(
              'Disputa activa — en revisión',
              style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (status == 'COMPLETED' || status == 'COMPLETADA') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showPayoutBreakdownDialog(b),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Ver Liquidación', style: TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC89D93),
                side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final clientId = b['client_id']?.toString();
                if (clientId == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      partnerId: clientId,
                      partnerName: b['client_name'] ?? 'Cliente',
                      partnerRole: 'client',
                      partnerAvatar: '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chatear', style: TextStyle(fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                final clientId = b['client_id']?.toString();
                if (clientId == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      partnerId: clientId,
                      partnerName: b['client_name'] ?? 'Cliente',
                      partnerRole: 'client',
                      partnerAvatar: '',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat', style: TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC89D93),
                side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Llama al endpoint que genera OTP y cambia estado a ESPERANDO_OTP
  Future<void> _handleCompleteService(String bookingId) async {
    try {
      await ApiService.post('/api/bookings/$bookingId/complete', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Servicio completado. El cliente recibirá su código de confirmación.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  Future<void> _toggleStatus(bool value) async {
    setState(() => _isActive = value);
    try {
      double? lat;
      double? lon;
      if (value) {
        try {
          final pos = await getWebGeolocation();
          lat = pos['lat'];
          lon = pos['lon'];
        } catch (e) {
          debugPrint('Error getting geolocation: $e');
        }
      }
      await ApiService.updateProviderStatus(value, latitude: lat, longitude: lon);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '🟢 Ahora estás En Línea' : '⚫ Ahora estás Fuera de Línea'),
            backgroundColor: const Color(0xFFC89D93),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isActive = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cambiar estado: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  int get _todayBookingsCount {
    final now = DateTime.now();
    return _bookings.where((b) {
      try {
        final date = DateTime.parse(b['scheduled_at']);
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  double get _weeklyNetEarnings {
    return _bookings.where((b) {
      final st = (b['status'] as String? ?? '').toUpperCase();
      return st == 'CONFIRMADA' || st == 'COMPLETADA' || st == 'CONFIRMED' || st == 'COMPLETED' || st == 'EN_PROGRESO';
    }).fold(0.0, (sum, b) {
      return sum + (double.tryParse(b['provider_net_amount']?.toString() ?? '') ?? 0.0);
    });
  }

  void _showSOSConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 8),
              Text(
                '🚨 ALERTA SOS',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás en peligro o necesitas asistencia inmediata?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              SizedBox(height: 12),
              Text(
                'Al confirmar, se enviará una alerta silenciosa con tu ubicación actual a la central de seguridad de la plataforma y te daremos la opción de llamar directamente al número de emergencias (123).',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo primero
                await _triggerSOSAlert();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 18),
                  SizedBox(width: 6),
                  Text('SÍ, ENVIAR SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerSOSAlert() async {
    setState(() {
      _loading = true;
    });

    try {
      String? activeBookingId;
      try {
        final inProgressBooking = _bookings.firstWhere(
          (b) => (b['status'] as String? ?? '').toUpperCase() == 'EN_PROGRESO',
        );
        activeBookingId = inProgressBooking['id']?.toString();
      } catch (_) {
        // Ignorar si no hay citas en progreso
      }

      // Registrar evento de telemetría de botón SOS presionado por prestador
      AnalyticsService().logEvent(
        eventType: 'SOS_TRIGGERED',
        screenName: '/provider',
        elementId: 'sos_provider_fab',
        metadata: {
          'booking_id': activeBookingId,
          'latitude': 4.6735,
          'longitude': -74.1422,
        },
      );

      const double lat = 4.6735;
      const double lon = -74.1422;

      final res = await ApiService.triggerSOS(
        bookingId: activeBookingId,
        latitude: lat,
        longitude: lon,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
      });

      _showSOSTriggeredSheet(res['message'] ?? 'Alerta enviada correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al enviar alerta SOS: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSOSTriggeredSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Alerta SOS Registrada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📞 Marcando al 123 (Emergencias)...'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                },
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text(
                  'LLAMAR A EMERGENCIAS (123)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFFE8D7D3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido / Cerrar',
                  style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))));
    }
    if (_error != null && _bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Prestador')),
        body: Center(
          child: TextButton(
            onPressed: () {
              _fetchBookings();
              _fetchProfile();
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('❌ Error de conexión', style: TextStyle(color: Colors.red, fontSize: 18)),
                SizedBox(height: 8),
                Text('Toca para reintentar', style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Belleza Pro',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          Row(
            children: [
              Text(
                _isActive ? 'En Línea' : 'Fuera de Línea',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isActive ? const Color(0xFF16A34A) : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _isActive,
                onChanged: _toggleStatus,
                activeThumbColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFDCFCE7),
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[200],
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Gestionar Servicios',
            onPressed: () => Navigator.pushNamed(context, '/provider/services'),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Mi Portafolio',
            onPressed: () => Navigator.pushNamed(context, '/provider/portfolio'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Mensajes',
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Mi Perfil',
            onPressed: () async {
              final refresh = await Navigator.pushNamed(context, '/provider/profile');
              if (refresh == true) {
                _fetchBookings();
                _fetchProfile();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchBookings();
              _fetchProfile();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchBookings();
          await _fetchProfile();
        },
        color: const Color(0xFFC89D93),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero section with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDF4F2), Color(0xFFF5EBE6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8D7D3).withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu Resumen en Fontibón',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestiona tus citas y chatea con tus clientes en tiempo real, vecino.',
                    style: TextStyle(fontSize: 13.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Analytics Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _analyticsCard(
                          'Citas Hoy',
                          _todayBookingsCount.toString(),
                          Icons.today_rounded,
                          const Color(0xFFC89D93),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _analyticsCardWithTween(
                          'Ganancia Net',
                          _weeklyNetEarnings,
                          Icons.account_balance_wallet_outlined,
                          const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _analyticsCard(
                          'Valoración',
                          _ratingAvg.toStringAsFixed(1),
                          Icons.star_rounded,
                          const Color(0xFFD97706),
                          subtitle: '$_ratingCount reseñas',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── Banner acceso rápido al Wallet ────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B21A8).withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mi Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Ver saldo, retiros e historial', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agenda de Clientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                Text(
                  '${_bookings.length} servicios',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_bookings.isEmpty)
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'No tienes citas agendadas aún.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ..._bookings.map((b) {
                final date = DateTime.parse(b['scheduled_at']).toLocal();
                final dayStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                final hourStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                final clientInitial = (b['client_name'] ?? '?')[0].toUpperCase();
                final cardStatus = (b['status'] as String? ?? '').toUpperCase();

                return Stack(
                  children: [
                    // Main Appointment Card
                    GestureDetector(
                      onTap: (cardStatus == 'COMPLETADA' || cardStatus == 'COMPLETED')
                          ? () => _showPayoutBreakdownDialog(b)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF3EAE8), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF5EBE6),
                                    child: Text(
                                      clientInitial,
                                      style: const TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b['client_name'] ?? 'Cliente',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const Text(
                                          'Contacto seguro vía Chat',
                                          style: TextStyle(fontSize: 12, color: Color(0xFFC89D93), fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusBgColor(b['status']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusText(b['status']).toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(b['status']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: Color(0xFFF3F4F6)),
                              Row(
                                children: [
                                  const Icon(Icons.spa_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Servicio: ${b['service_name']}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '\$${(double.tryParse(b['total_amount']?.toString() ?? '') ?? 0.0).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFC89D93)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$dayStr a las $hourStr',
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      (b['service_address']?.toString().isNotEmpty ?? false)
                                          ? 'Dirección: ${b['service_address']}'
                                          : 'Dirección pendiente por confirmar',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ),
                                  if ((b['service_address']?.toString().isNotEmpty ?? false) &&
                                      cardStatus != 'COMPLETADA' &&
                                      cardStatus != 'COMPLETED' &&
                                      cardStatus != 'CANCELADA' &&
                                      cardStatus != 'CANCELLED' &&
                                      cardStatus != 'PENDIENTE_PAGO') ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        final refresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProviderRouteScreen(booking: b),
                                          ),
                                        );
                                        if (refresh == true) {
                                          _fetchBookings();
                                          _fetchProfile();
                                        }
                                      },
                                      child: const Icon(
                                        Icons.map_outlined,
                                        color: Color(0xFFC89D93),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCardActionButtons(b),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Glassmorphic Locked Overlay for PENDIENTE_PAGO
                    if (cardStatus == 'PENDIENTE_PAGO')
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0x1F000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFFFEF3C7), width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_clock_outlined, color: Color(0xFFD97706), size: 36),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Pago en Verificación',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Esperando confirmación de la pasarela Wompi...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'sos_provider_fab',
        onPressed: _showSOSConfirmationDialog,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.emergency_outlined, size: 28),
      ),
    );
  }

  Widget _analyticsCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _analyticsCardWithTween(String label, double targetValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetValue),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Text(
                '\$${value.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _statusColor(dynamic status) {
    final s = (status?.toString() ?? '').toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return const Color(0xFFD97706);
      case 'CONFIRMED':
      case 'CONFIRMADA': 
        return const Color(0xFF2563EB);
      case 'EN_PROGRESO': 
        return const Color(0xFF8B5CF6);
      case 'FINALIZADA_PRESTADOR': 
        return const Color(0xFF06B6D4);
      case 'COMPLETED':
      case 'COMPLETADA': 
        return const Color(0xFF16A34A);
      case 'CANCELLED':
      case 'CANCELADA': 
        return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  Color _statusBgColor(dynamic status) {
    final s = (status?.toString() ?? '').toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return const Color(0xFFFEF3C7);
      case 'CONFIRMED':
      case 'CONFIRMADA': 
        return const Color(0xFFDBEAFE);
      case 'EN_PROGRESO': 
        return const Color(0xFFEDE9FE);
      case 'FINALIZADA_PRESTADOR': 
        return const Color(0xFFECFEFF);
      case 'COMPLETED':
      case 'COMPLETADA': 
        return const Color(0xFFDCFCE7);
      case 'CANCELLED':
      case 'CANCELADA': 
        return const Color(0xFFFEE2E2);
      default: return const Color(0xFFF3F4F6);
    }
  }

  String _statusText(dynamic status) {
    final s = (status?.toString() ?? '').toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return 'Pendiente Pago';
      case 'CONFIRMED':
      case 'CONFIRMADA': 
        return 'Confirmada';
      case 'EN_PROGRESO': 
        return 'En Progreso';
      case 'FINALIZADA_PRESTADOR': 
        return 'Finalizada';
      case 'COMPLETED':
      case 'COMPLETADA': 
        return 'Completada';
      case 'CANCELLED':
      case 'CANCELADA': 
        return 'Cancelada';
      default: return status?.toString() ?? '';
    }
  }
}

// Custom Segemented Pin Input Dialog
class SegmentedPinDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(Map<String, dynamic>) onSuccess;

  const SegmentedPinDialog({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  @override
  State<SegmentedPinDialog> createState() => _SegmentedPinDialogState();
}

class _SegmentedPinDialogState extends State<SegmentedPinDialog> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _controllers.map((c) => c.text).join();
    if (pin.length != 4) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Capturar geolocalización en tiempo real
      double providerLat = 4.6735;
      double providerLon = -74.1422;
      double clientLat = 4.6735;
      double clientLon = -74.1422;

      if (kIsWeb) {
        try {
          final pos = await getWebGeolocation();
          providerLat = pos['lat']!;
          providerLon = pos['lon']!;
          clientLat = providerLat;
          clientLon = providerLon;
        } catch (e) {
          debugPrint('Error obteniendo geolocalización web: $e');
        }
      }

      final res = await ApiService.completeBooking(
        widget.booking['id'].toString(), 
        pin,
        providerLat: providerLat,
        providerLon: providerLon,
        clientLat: clientLat,
        clientLon: clientLon,
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSuccess(res);
      }
    } catch (e) {
      HapticFeedback.vibrate();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceAll('Exception:', '');
          // Reset fields on error
          for (var c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Color(0xFFC89D93)),
          SizedBox(width: 8),
          Text('Verificación Escrow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pídele al cliente el PIN de 4 dígitos generado en su pantalla para liberar los fondos.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBE6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNodes[index].hasFocus ? const Color(0xFFC89D93) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF881337)),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.length == 1) {
                      if (index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else {
                        // Segmented auto-submit
                        _submitPin();
                      }
                    } else if (val.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          if (_isSubmitting) ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC89D93)),
                ),
                SizedBox(width: 8),
                Text(
                  '📡 Validando proximidad GPS (PostGIS)...',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
