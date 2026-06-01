// frontend/lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../shared/theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _startMockNotificationGenerator();
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationsStream =>
      _notificationController.stream;

  Timer? _mockTimer;

  void _startMockNotificationGenerator() {
    _mockTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      final mockNotif = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': '✨ ¡Nueva oferta de belleza!',
        'body': 'Carlos Daniel tiene un 20% de descuento en manicura hoy.',
        'timestamp': DateTime.now().toIso8601String(),
      };
      _notificationController.add(mockNotif);
      showInAppNotification(mockNotif);
    });
  }

  void triggerMockNotification({String? title, String? body}) {
    final mockNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title ?? '🔔 Recordatorio de Cita',
      'body': body ?? 'Tu cita de cejas con María Paula inicia en 15 minutos.',
      'timestamp': DateTime.now().toIso8601String(),
    };
    _notificationController.add(mockNotif);
    showInAppNotification(mockNotif);
  }

  void showInAppNotification(Map<String, dynamic> notification) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1.0 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification['title'] ?? 'Notificación',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.info,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification['body'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void dispose() {
    _mockTimer?.cancel();
    _notificationController.close();
  }
}
