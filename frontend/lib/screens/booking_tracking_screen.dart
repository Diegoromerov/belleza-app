// frontend/lib/screens/booking_tracking_screen.dart
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';
import '../shared/theme.dart';

class BookingTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingTrackingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> with SingleTickerProviderStateMixin {
  // Coordenadas fijas del cliente en Fontibón
  final LatLng _clientLoc = const LatLng(4.6735, -74.1422);
  
  // Coordenadas iniciales del prestador (se irán acercando)
  late LatLng _providerLoc;
  
  // Progreso de interpolación (0.0 a 1.0)
  double _progress = 0.0;
  Timer? _moveTimer;
  int _minutesRemaining = 8;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Inicia un poco al noreste del cliente
    _providerLoc = const LatLng(4.6795, -74.1310);
    
    // Controlador para la animación pulsante concéntrica del marcador del proveedor
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startTrackingSimulation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startTrackingSimulation() {
    _moveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.05; // Incrementa el progreso en cada tick
          if (_progress > 1.0) _progress = 1.0;
          
          // Interpolación lineal simple entre la posición inicial y el cliente
          final double lat = 4.6795 + (_clientLoc.latitude - 4.6795) * _progress;
          final double lon = -74.1310 + (_clientLoc.longitude - (-74.1310)) * _progress;
          _providerLoc = LatLng(lat, lon);
          
          // Disminuir tiempo estimado progresivamente
          _minutesRemaining = (8 * (1.0 - _progress)).round();
          if (_minutesRemaining < 1) _minutesRemaining = 1;
        } else {
          _moveTimer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String providerName = widget.booking['provider_name'] ?? 'Profesional';
    final String providerBusiness = widget.booking['provider_business_name'] ?? 'Studio Profesional';
    final String providerAvatar = widget.booking['provider_avatar_url'] ?? '';
    final String pin = widget.booking['pin_verificacion'] ?? '----';
    final String providerId = widget.booking['provider_id']?.toString() ?? '2';

    // Cálculo dinámico de distancia en kilómetros
    final double distanceInKm = const Distance().distance(_providerLoc, _clientLoc) / 1000.0;
    final String distanceText = '${distanceInKm.toStringAsFixed(1)} km';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Seguimiento en Vivo',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Capa del Mapa (OSM via flutter_map)
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng((_clientLoc.latitude + _providerLoc.latitude) / 2, (_clientLoc.longitude + _providerLoc.longitude) / 2),
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: MapSettings.isDark
                    ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyapp.map',
              ),
              // Línea de Ruta (Polyline)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_providerLoc, _clientLoc],
                    color: AppTheme.primary,
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              // Marcadores en el mapa
              MarkerLayer(
                markers: [
                  // Marcador de Ubicación del Cliente (Destino)
                  Marker(
                    width: 50,
                    height: 50,
                    point: _clientLoc,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.home_work, color: AppTheme.primary, size: 28),
                    ),
                  ),
                  // Marcador de Ubicación del Prestador (Origen Animado con pulso concéntrico real)
                  Marker(
                    width: 100,
                    height: 100,
                    point: _providerLoc,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Primer anillo concéntrico
                            Opacity(
                              opacity: (1.0 - _pulseController.value).clamp(0.0, 1.0),
                              child: Container(
                                width: 35 + (_pulseController.value * 55),
                                height: 35 + (_pulseController.value * 55),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.4),
                                ),
                              ),
                            ),
                            // Segundo anillo concéntrico desfasado
                            Opacity(
                              opacity: (1.0 - ((_pulseController.value + 0.5) % 1.0)).clamp(0.0, 1.0),
                              child: Container(
                                width: 35 + (((_pulseController.value + 0.5) % 1.0) * 55),
                                height: 35 + (((_pulseController.value + 0.5) % 1.0) * 55),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.25),
                                ),
                              ),
                            ),
                            child!,
                          ],
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2.5),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryLight,
                          backgroundImage: providerAvatar.isNotEmpty ? NetworkImage(providerAvatar) : null,
                          child: providerAvatar.isEmpty
                              ? const Icon(Icons.face_retouching_natural, size: 18, color: AppTheme.primary)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Botón Tema de Mapa (Claro/Oscuro Limpio)
          Positioned(
            right: 20,
            bottom: 380,
            child: FloatingActionButton(
              heroTag: 'map_theme_tracking_fab',
              onPressed: () {
                setState(() {
                  MapSettings.isDark = !MapSettings.isDark;
                });
              },
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                MapSettings.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 22,
              ),
            ),
          ),

          // Botón flotante para chatear fácilmente
          Positioned(
            right: 20,
            bottom: 315,
            child: FloatingActionButton(
              heroTag: 'chat_tracking_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      partnerId: providerId,
                      partnerName: providerBusiness,
                      partnerRole: 'provider',
                      partnerAvatar: providerAvatar,
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.chat_bubble_rounded, size: 24),
            ),
          ),

          // 3. Capa Inferior: Bottom Status Card (Glassmorphic Redesign with Integrated Escrow PIN)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryLight,
                              backgroundImage: providerAvatar.isNotEmpty ? NetworkImage(providerAvatar) : null,
                              child: providerAvatar.isEmpty
                                  ? Text(
                                      providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                                      style: const TextStyle(fontSize: 18, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    providerBusiness.isNotEmpty ? providerBusiness : providerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$providerName • $distanceText',
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            // Contador de tiempo estimado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.errorBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Llega en',
                                    style: TextStyle(fontSize: 10, color: AppTheme.error, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$_minutesRemaining min',
                                    style: const TextStyle(fontSize: 15, color: AppTheme.error, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Barra de progreso de llegada
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progreso de llegada',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: AppTheme.primaryLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 8,
                          ),
                        ),
                        
                        const Divider(height: 24, color: Color(0xFFF3EAE8)),
                        
                        // Escrow PIN integrado de manera limpia
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.vpn_key_rounded, color: AppTheme.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'PIN Escrow Seguro:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                              Text(
                                pin,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Wompi Badge
                            Row(
                              children: [
                                const Icon(Icons.shield, color: AppTheme.success, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'Pago Wompi Protegido',
                                  style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Text(
                              'En camino',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
