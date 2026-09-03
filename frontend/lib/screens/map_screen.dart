import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../shared/theme.dart';
import 'provider_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<ProviderModel> providers;
  const MapScreen({super.key, required this.providers});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _useExactGps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPrecisionDialog();
    });
  }

  void _showLocationPrecisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFFC5A052)),
            SizedBox(width: 8),
            Text('Privacidad de Ubicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Selecciona el nivel de precisión deseado para encontrar especialistas cerca de ti. Puedes cambiarlo en cualquier momento.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _useExactGps = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Búsqueda por Ubicación Aproximada (Barrio / Ciudad)')),
              );
            },
            child: const Text('Aproximada (Barrio)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A052),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _useExactGps = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Búsqueda por GPS Exacto activada')),
              );
            },
            child: const Text('Exacta (GPS)'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final valid = widget.providers
        .where((p) => p.latitude != 0 && p.longitude != 0)
        .toList();
    final center = valid.isNotEmpty
        ? LatLng(valid[0].latitude, valid[0].longitude)
        : const LatLng(4.6097, -74.0817);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Explorar Especialistas',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8DFD8), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF1F1A15)),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF1F1A15)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Ver Lista',
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: MapSettings.isDark
                    ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyapp.map',
              ),
              MarkerLayer(
                markers: valid
                    .map((p) => Marker(
                          width: 90,
                          height: 95,
                          point: LatLng(p.latitude, p.longitude),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProviderDetailScreen(
                                        providerId: p.id))),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.primary,
                                        width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF5EBE6),
                                    backgroundImage: p.avatarUrl.isNotEmpty
                                        ? NetworkImage(p.avatarUrl)
                                        : null,
                                    child: p.avatarUrl.isEmpty
                                        ? const Icon(
                                            Icons.face_retouching_natural,
                                            size: 20,
                                            color: AppTheme.primary)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Text(
                                    p.businessName.isNotEmpty
                                        ? p.businessName
                                        : p.fullName,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                CustomPaint(
                                    size: const Size(12, 6),
                                    painter: _ArrowPainter()),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'map_theme_explore_fab',
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
                MapSettings.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
