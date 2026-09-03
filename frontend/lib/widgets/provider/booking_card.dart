// lib/widgets/provider/booking_card.dart
// Widget atómico: Tarjeta de reserva/cita reutilizable
// Usado en Dashboard, Agenda, y próximamente Calendar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/app_theme.dart';

class BookingCard extends ConsumerWidget {
  final Booking booking;
  final bool isHero; // Para "Próxima Cita" hero card
  final VoidCallback? onTap;
  final VoidCallback? onStartRoute;
  final VoidCallback? onStartService;
  final VoidCallback? onCompleteService;
  final VoidCallback? onChat;
  final VoidCallback? onViewPayout;
  final VoidCallback? onViewRoute;
  final VoidCallback? onReportSupport;

  const BookingCard({
    super.key,
    required this.booking,
    this.isHero = false,
    this.onTap,
    this.onStartRoute,
    this.onStartService,
    this.onCompleteService,
    this.onChat,
    this.onViewPayout,
    this.onViewRoute,
    this.onReportSupport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Token.of(context);

    final statusColor = _statusColor(t);
    final statusBgColor = _statusBgColor(t);
    final statusText = _statusText(t);

    final card = _buildCardContent(context, t, statusColor, statusBgColor, statusText);

    if (isHero) {
      return Container(
        margin: const EdgeInsets.only(bottom: Spacing.xxl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [t.neutral50, t.surfaceVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Radii.xxxl),
          border: Border.all(color: t.outlineVariant, width: 1.5),
          boxShadow: AppShadow.card(t),
        ),
        child: card,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(Radii.xxl),
        border: Border.all(color: t.outlineVariant, width: 1),
        boxShadow: AppShadow.soft(t),
      ),
      child: card,
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    Token t,
    Color statusColor,
    Color statusBgColor,
    String statusText,
  ) {
    final clientInitial = booking.clientName.isNotEmpty ? booking.clientName[0].toUpperCase() : 'C';
    final formattedDate = _formatDate(booking.scheduledAt);
    final formattedTime = _formatTime(booking.scheduledAt);

    return Padding(
      padding: EdgeInsets.all(isHero ? Spacing.xxl : Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Info + Amount
          Row(
            children: [
              CircleAvatar(
                radius: isHero ? 24 : 20,
                backgroundColor: t.brandPrimary.withValues(alpha: 0.1),
                child: Text(
                  clientInitial,
                  style: AppTypography.titleMedium(t).copyWith(
                    color: t.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: isHero ? Spacing.md : Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName,
                      style: (isHero ? AppTypography.headlineSmall : AppTypography.titleMedium)(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Servicio: ${booking.serviceName}',
                      style: AppTypography.bodySmall(t).copyWith(
                        color: t.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: AppTypography.labelSmall(t).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (!isHero) ...[
                SizedBox(width: Spacing.sm),
                Text(
                  booking.formattedTotalAmount,
                  style: AppTypography.monoMedium(t).copyWith(
                    color: t.brandPrimary,
                  ),
                ),
              ],
            ],
          ),

          // Hero: Amount prominent
          if (isHero) ...[
            SizedBox(height: Spacing.md),
            Divider(color: t.outlineVariant, height: 1),
            SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: AppTypography.bodyMedium(t),
                    ),
                    Text(
                      formattedTime,
                      style: AppTypography.bodySmall(t).copyWith(color: t.neutral600),
                    ),
                  ],
                ),
                Text(
                  booking.formattedTotalAmount,
                  style: AppTypography.monoLarge(t).copyWith(
                    color: t.brandPrimary,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: Spacing.md),
            Divider(color: t.outlineVariant, height: 1),
            SizedBox(height: Spacing.md),
            // Details row
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: t.neutral500),
                SizedBox(width: Spacing.xs),
                Text(
                  '$formattedDate a las $formattedTime',
                  style: AppTypography.bodyMedium(t),
                ),
                Spacer(),
                Icon(Icons.location_on, size: 16, color: t.neutral500),
                SizedBox(width: Spacing.xs),
                Flexible(
                  child: Text(
                    booking.serviceAddress.isNotEmpty
                        ? 'Dirección: ${booking.serviceAddress}'
                        : 'Dirección pendiente',
                    style: AppTypography.bodySmall(t).copyWith(color: t.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: Spacing.lg),

          // Actions based on status
          _buildActions(context, t, typo),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Token t) {
    final loadingSet = ref.watch(bookingLoadingProvider);
    final isLoading = loadingSet.contains(booking.id);

    if (isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.md),
          child: CircularProgressIndicator(color: t.brandPrimary, strokeWidth: 2),
        ),
      );
    }

    switch (booking.statusUpper) {
      case 'CONFIRMED':
      case 'CONFIRMADA':
      case 'CHECKIN_REALIZADO':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartRoute ?? onViewRoute,
                icon: Icon(Icons.navigation_outlined, size: 16),
                label: Text('Iniciar Ruta', style: AppTypography.labelMedium(t)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.brandPrimary,
                  side: BorderSide(color: t.brandPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            SizedBox(width: Spacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStartService,
                icon: Icon(Icons.play_arrow_outlined, size: 16),
                label: Text('Iniciar Servicio', style: AppTypography.labelMedium(t)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        );

      case 'EN_PROGRESO':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text('Chat', style: AppTypography.labelMedium(t)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.brandPrimary,
                      side: BorderSide(color: t.brandPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                      padding: EdgeInsets.symmetric(vertical: Spacing.md),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
                SizedBox(width: Spacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewRoute,
                    icon: Icon(Icons.map_outlined, size: 16),
                    label: Text('Ver Mapa', style: AppTypography.labelMedium(t)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.brandPrimary,
                      side: BorderSide(color: t.brandPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                      padding: EdgeInsets.symmetric(vertical: Spacing.md),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCompleteService,
                icon: Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text('Marcar como completado', style: AppTypography.labelLarge(t)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.success,
                  foregroundColor: t.successOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.lg),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        );

      case 'ESPERANDO_OTP':
      case 'FINALIZADA_PRESTADOR':
        return Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.lg),
              decoration: BoxDecoration(
                color: t.infoBg,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: t.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: t.info),
                  ),
                  SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      'Esperando confirmación OTP del cliente...',
                      style: AppTypography.bodyMedium(t).copyWith(
                        fontWeight: FontWeight.bold,
                        color: t.infoOn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onReportSupport,
                    icon: Icon(Icons.support_agent_outlined, size: 16, color: t.neutral500),
                    label: Text(
                      'El cliente no puede confirmar / Reportar soporte',
                      style: AppTypography.labelSmall(t).copyWith(
                        color: t.neutral500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'EN_DISPUTA':
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: t.warningBg,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: t.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gavel, color: t.warning, size: 18),
              SizedBox(width: Spacing.sm),
              Text(
                'Disputa activa — en revisión',
                style: AppTypography.titleSmall(t).copyWith(
                  color: t.warningOn,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case 'COMPLETED':
      case 'COMPLETADA':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewPayout,
                icon: Icon(Icons.receipt_long_outlined, size: 16),
                label: Text('Ver Liquidación', style: AppTypography.labelMedium(t)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.brandPrimary,
                  side: BorderSide(color: t.brandPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            SizedBox(width: Spacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onChat,
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text('Chatear', style: AppTypography.labelMedium(t)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        );

      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChat,
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text('Chat', style: AppTypography.labelMedium(t)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.brandPrimary,
                  side: BorderSide(color: t.brandPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _statusColor(Token t) {
    final s = booking.statusUpper;
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO':
        return t.warning;
      case 'CONFIRMED':
      case 'CONFIRMADA':
        return t.info;
      case 'EN_PROGRESO':
        return t.inProgress;
      case 'FINALIZADA_PRESTADOR':
      case 'ESPERANDO_OTP':
        return t.info;
      case 'COMPLETED':
      case 'COMPLETADA':
        return t.success;
      case 'CANCELLED':
      case 'CANCELADA':
        return t.error;
      case 'EN_DISPUTA':
        return t.warning;
      default:
        return t.neutral500;
    }
  }

  Color _statusBgColor(Token t) {
    final s = booking.statusUpper;
    switch (s) {
      case 'PENDING':
      case 'PENDIENTE_PAGO':
        return t.warningBg;
      case 'CONFIRMED':
      case 'CONFIRMADA':
        return t.infoBg;
      case 'EN_PROGRESO':
        return t.inProgressBg;
      case 'FINALIZADA_PRESTADOR':
      case 'ESPERANDO_OTP':
        return t.infoBg;
      case 'COMPLETED':
      case 'COMPLETADA':
        return t.successBg;
      case 'CANCELLED':
      case 'CANCELADA':
        return t.errorBg;
      case 'EN_DISPUTA':
        return t.warningBg;
      default:
        return t.neutral100;
    }
  }

  String _statusText(Token t) {
    final s = booking.statusUpper;
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
      case 'EN_DISPUTA':
        return 'Disputa';
      default:
        return s;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Extension para Booking
extension BookingExt on Booking {
  String get formattedTotalAmount {
    return '\$${totalAmount.toStringAsFixed(0)} COP';
  }
}