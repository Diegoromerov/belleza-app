// frontend/lib/screens/client_bookings_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_confirm_screen.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchClientBookings();
      if (mounted) {
        setState(() {
          _bookings = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCancelBooking(String bookingId, String providerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('¿Cancelar cita?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text('¿Estás seguro de que deseas cancelar tu cita con $providerName? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancelar Cita', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.cancelBooking(bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Tu cita ha sido cancelada con éxito.'),
                ],
              ),
              backgroundColor: const Color(0xFFC89D93),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }
        _loadBookings();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al cancelar: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitReviewHelper(String bookingId, int ratingSelected, String reviewComment) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.submitReview(bookingId, ratingSelected, reviewComment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Gracias por tu opinión! Reseña guardada.'),
              ],
            ),
            backgroundColor: const Color(0xFFC89D93),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
      _loadBookings();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al enviar reseña: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showRatingSheet(Map<String, dynamic> booking) {
    int ratingSelected = 5;
    String reviewComment = '';
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final providerName = (booking['provider_business_name'] != null && booking['provider_business_name'].toString().isNotEmpty)
                ? booking['provider_business_name'].toString()
                : (booking['provider_name']?.toString() ?? 'Prestador');
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Calificar tu servicio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cuéntanos tu experiencia con $providerName',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          iconSize: 40,
                          icon: Icon(
                            starValue <= ratingSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFD97706),
                          ),
                          onPressed: () {
                            setModalState(() {
                              ratingSelected = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu comentario aquí (opcional)...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5EBE6),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (v) => reviewComment = v,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC89D93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _submitReviewHelper(booking['id'], ratingSelected, reviewComment);
                      },
                      child: const Text('Enviar Calificación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(String? scheduledAtStr) {
    if (scheduledAtStr == null) {
      return '';
    }
    try {
      final date = DateTime.parse(scheduledAtStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year - $hour:$minute';
    } catch (_) {
      return scheduledAtStr;
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return const Color(0xFFD97706);
      case 'CONFIRMED':
      case 'CONFIRMADA': 
      case 'CHECKIN_REALIZADO':
        return const Color(0xFF2563EB);
      case 'EN_PROGRESO': 
        return const Color(0xFF8B5CF6);
      case 'FINALIZADA_PRESTADOR':
      case 'ESPERANDO_OTP':
        return const Color(0xFF06B6D4);
      case 'COMPLETED':
      case 'COMPLETADA': 
        return const Color(0xFF16A34A);
      case 'EN_DISPUTA':
        return const Color(0xFFEA580C);
      case 'CANCELLED':
      case 'CANCELADA': 
        return const Color(0xFFDC2626);
      default: return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return const Color(0xFFFEF3C7);
      case 'CONFIRMED':
      case 'CONFIRMADA':
      case 'CHECKIN_REALIZADO':
        return const Color(0xFFDBEAFE);
      case 'EN_PROGRESO': 
        return const Color(0xFFEDE9FE);
      case 'FINALIZADA_PRESTADOR':
      case 'ESPERANDO_OTP':
        return const Color(0xFFECFEFF);
      case 'COMPLETED':
      case 'COMPLETADA': 
        return const Color(0xFFDCFCE7);
      case 'EN_DISPUTA':
        return const Color(0xFFFFF7ED);
      case 'CANCELLED':
      case 'CANCELADA': 
        return const Color(0xFFFEE2E2);
      default: return const Color(0xFFF3F4F6);
    }
  }

  String _getStatusText(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO': 
        return 'Pendiente Pago';
      case 'CONFIRMED':
      case 'CONFIRMADA': 
        return 'Confirmada';
      case 'CHECKIN_REALIZADO':
        return 'Prestador llegó';
      case 'EN_PROGRESO': 
        return 'En Progreso';
      case 'FINALIZADA_PRESTADOR':
      case 'ESPERANDO_OTP':
        return '¡Ingresa tu código!';
      case 'COMPLETED':
      case 'COMPLETADA': 
        return 'Completada';
      case 'EN_DISPUTA':
        return 'En Disputa';
      case 'CANCELLED':
      case 'CANCELADA': 
        return 'Cancelada';
      default: return status;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 64, color: Color(0xFFC89D93)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.search),
              label: const Text('Explorar Prestadores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final status = booking['status']?.toString() ?? 'pending';
    final providerName = (booking['provider_business_name'] != null && booking['provider_business_name'].toString().isNotEmpty)
        ? booking['provider_business_name'].toString()
        : (booking['provider_name']?.toString() ?? 'Establecimiento');
    
    final avatarUrl = booking['provider_avatar_url']?.toString() ?? '';
    final serviceName = booking['service_name']?.toString() ?? 'Servicio';
    final scheduledAt = booking['scheduled_at']?.toString() ?? '';
    final totalAmount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final isReviewed = booking['is_reviewed'] == true;
    final reviewData = booking['review'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF5EBE6),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                          style: const TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(scheduledAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF3F4F6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duración: ${booking['service_duration']} min',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC89D93),
                  ),
                ),
              ],
            ),
            if (booking['service_address'] != null && booking['service_address'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Dirección del servicio: ${booking['service_address']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            ],
            if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EBE6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Nota: "${booking['notes']}"',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ),
            ],
            // ─── OTP: Cuando el prestador marcó el servicio completado ───
            if (status.toUpperCase() == 'ESPERANDO_OTP' ||
                status.toUpperCase() == 'FINALIZADA_PRESTADOR') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B21A8).withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '¡El servicio ha finalizado!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El prestador completó el servicio. Ingresa tu código de 6 dígitos para confirmar y liberar el pago.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtpConfirmScreen(
                              bookingId: booking['id'],
                              prestadorNombre: providerName,
                              servicioNombre: serviceName,
                              valorBruto: totalAmount,
                            ),
                          ),
                        ).then((_) => _loadBookings()),
                        icon: const Icon(Icons.lock_open_rounded, color: Color(0xFF6B21A8)),
                        label: const Text(
                          'Ingresar código de confirmación',
                          style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ─── Estado en disputa ───
            if (status.toUpperCase() == 'EN_DISPUTA') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel, color: Color(0xFFEA580C), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta reserva tiene una disputa activa. El equipo la resolverá en máx. 48 horas.',
                        style: TextStyle(color: Color(0xFF9A3412), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (reviewData != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1FFEFE3C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33D97706)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < reviewData['rating'] ? Icons.star_rounded : Icons.star_border_rounded,
                              color: const Color(0xFFD97706),
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tu calificación',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ],
                    ),
                    if (reviewData['comment'] != null && reviewData['comment'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${reviewData['comment']}"',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (status.toUpperCase() == 'CONFIRMADA' || status.toUpperCase() == 'CONFIRMED' || status.toUpperCase() == 'EN_PROGRESO') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/booking-tracking',
                      arguments: booking,
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('📍 Ver Seguimiento en Vivo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC89D93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            if (isUpcoming && (status.toLowerCase() == 'pending' || status.toLowerCase() == 'pendiente_pago' || status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'confirmada')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancelBooking(booking['id'], providerName),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancelar Cita'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFEE2E2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (!isUpcoming && status == 'completed' && !isReviewed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingSheet(booking),
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Calificar Servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC89D93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Citas', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))),
      );
    }

    if (_error != null && _bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Citas', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text('Error de conexión:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC89D93), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final upcoming = _bookings.where((b) {
      final status = (b['status']?.toString() ?? 'pending').toUpperCase();
      return status == 'PENDING' || status == 'PENDIENTE_PAGO' || status == 'CONFIRMED' || status == 'CONFIRMADA' || status == 'EN_PROGRESO' || status == 'FINALIZADA_PRESTADOR';
    }).toList();

    final history = _bookings.where((b) {
      final status = (b['status']?.toString() ?? 'pending').toUpperCase();
      return status == 'COMPLETED' || status == 'COMPLETADA' || status == 'CANCELLED' || status == 'CANCELADA';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mis Citas', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC89D93),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFC89D93),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Pestaña: Próximas
              RefreshIndicator(
                color: const Color(0xFFC89D93),
                onRefresh: _loadBookings,
                child: upcoming.isEmpty
                    ? _buildEmptyState('No tienes citas programadas próximamente.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: upcoming.length,
                        itemBuilder: (context, index) => _buildBookingCard(upcoming[index], true),
                      ),
              ),
              // Pestaña: Historial
              RefreshIndicator(
                color: const Color(0xFFC89D93),
                onRefresh: _loadBookings,
                child: history.isEmpty
                    ? _buildEmptyState('Tu historial de citas está vacío.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: history.length,
                        itemBuilder: (context, index) => _buildBookingCard(history[index], false),
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: const Color(0x1E000000),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFC89D93)),
              ),
            ),
        ],
      ),
    );
  }
}
