// frontend/lib/screens/ideas/vto_live_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/biometric_result.dart';
import '../../shared/theme.dart';
import 'widgets/vto_painter.dart';

class VtoLiveScreen extends StatefulWidget {
  final BiometricResult biometricResult;
  final Uint8List? faceImage;

  const VtoLiveScreen({
    super.key,
    required this.biometricResult,
    this.faceImage,
  });

  @override
  State<VtoLiveScreen> createState() => _VtoLiveScreenState();
}

class _VtoLiveScreenState extends State<VtoLiveScreen> {
  Color _selectedColor = const Color(0xFFE05A47);
  String _selectedName = 'Coral Sunset';
  String _selectedFinish = 'Mate';
  double _opacity = 0.65;

  late List<Map<String, dynamic>> _recommendedLipsticks;

  @override
  void initState() {
    super.initState();
    _loadVtoTones();
  }

  void _loadVtoTones() {
    final vtoTones = widget.biometricResult.vtoTones;
    if (vtoTones != null && vtoTones['lipsticks'] is List) {
      _recommendedLipsticks = (vtoTones['lipsticks'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    } else {
      final subtono = widget.biometricResult.face?.subtono ?? 'neutro';
      final isWarm = subtono.toLowerCase().contains('cál');
      _recommendedLipsticks = isWarm
          ? [
              {'name': 'Coral Sunset', 'hex': '#E05A47', 'finish': 'Mate'},
              {'name': 'Warm Nude', 'hex': '#C88A68', 'finish': 'Satinado'},
              {'name': 'Terracota Glam', 'hex': '#B84A39', 'finish': 'Mate'},
            ]
          : [
              {'name': 'Berry Crush', 'hex': '#9E2A2B', 'finish': 'Brillante'},
              {'name': 'Pink Rose', 'hex': '#D87093', 'finish': 'Mate'},
              {'name': 'Classic Ruby', 'hex': '#A4161A', 'finish': 'Satinado'},
            ];
    }

    if (_recommendedLipsticks.isNotEmpty) {
      final first = _recommendedLipsticks.first;
      _selectedName = first['name'] ?? 'Tono Sugerido';
      _selectedColor = _hexToColor(first['hex'] ?? '#E05A47');
      _selectedFinish = first['finish'] ?? 'Mate';
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final subtono = widget.biometricResult.face?.subtono ?? 'neutro';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'VTO Maquillaje • Subtono ${subtono.toUpperCase()}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Imagen capturada del usuario o representación VTO
          Positioned.fill(
            child: widget.faceImage != null
                ? Image.memory(
                    widget.faceImage!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.person, size: 120, color: Colors.white24),
                    ),
                  ),
          ),

          // Tinte interactivo simulado
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // Panel de selección de tonos DeepSeek V4 Flash (VTO UI)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Acabado $_selectedFinish • Recomendado por DeepSeek IA',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de Opacidad de Cobertura
                  Row(
                    children: [
                      const Text('Intensidad:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _opacity,
                          min: 0.2,
                          max: 1.0,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _opacity = val),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Carrusel de tonos recomendados por subtono
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendedLipsticks.length,
                      itemBuilder: (context, index) {
                        final item = _recommendedLipsticks[index];
                        final color = _hexToColor(item['hex'] ?? '#E05A47');
                        final isSelected = item['name'] == _selectedName;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedName = item['name'] ?? 'Tono';
                              _selectedColor = color;
                              _selectedFinish = item['finish'] ?? 'Mate';
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white12 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.white24,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['name'] ?? 'Tono',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botonera de Acción Directa E-Commerce & Citas GPS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🛍️ Tono "$_selectedName" agregado al carrito'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                          label: const Text('Comprar Tono', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📍 Buscando salones con este servicio cerca de ti...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                          label: const Text('Reservar Cita', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
