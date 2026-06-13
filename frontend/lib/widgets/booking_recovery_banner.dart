import 'package:flutter/material.dart';
import '../shared/theme.dart';

class BookingRecoveryBanner extends StatelessWidget {
  final Map<String, dynamic> pendingBooking;
  final VoidCallback onPayPressed;
  final VoidCallback onClosePressed;

  const BookingRecoveryBanner({
    super.key,
    required this.pendingBooking,
    required this.onPayPressed,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = pendingBooking['serviceName'] ?? 'Servicio';
    final providerName = pendingBooking['providerName'] ?? 'Profesional';
    final price = (pendingBooking['price'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pago pendiente: $serviceName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: onClosePressed,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tu cita con $providerName no está confirmada aún.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C288D),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onPayPressed,
            icon: const Icon(Icons.payment, size: 16),
            label: Text(
              'Pagar \$${price.toStringAsFixed(0)} COP con Wompi',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
