// frontend/lib/screens/designs/wardrobe_dashboard_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';
import 'laser_scanner_widget.dart';

class WardrobeDashboardScreen extends StatefulWidget {
  const WardrobeDashboardScreen({super.key});

  @override
  State<WardrobeDashboardScreen> createState() => _WardrobeDashboardScreenState();
}

class _WardrobeDashboardScreenState extends State<WardrobeDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isClassifying = false;
  String? _error;
  List<Map<String, dynamic>> _wardrobe = [];
  Map<String, dynamic>? _userProfile;

  // Filtro de categorías
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'superior', 'inferior', 'calzado', 'abrigo', 'accesorio'];

  // Selección de ocasión
  String _selectedOccasion = 'casual';
  final List<String> _occasions = ['casual', 'urbano', 'clasico', 'noche', 'fiesta'];

  // Para escaneo láser
  Uint8List? _classifyingBytes;
  final List<String> _scanningTexts = [
    'Detectando contornos...',
    'Analizando texturas...',
    'Identificando colores con IA...',
    'Clasificando estilo...',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.fetchWardrobe();
      final profile = await ApiService.fetchUserProfile();
      setState(() {
        _wardrobe = list;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addGarment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    // Validar límite Free (máximo 5 prendas)
    final glowaiPlan = _userProfile?['glowai_plan'] ?? 'free';
    if (glowaiPlan == 'free' && _wardrobe.length >= 5) {
      _showPremiumModal('Has alcanzado el límite de 5 prendas en tu clóset gratuito. Suscríbete para tener un clóset ilimitado.');
      return;
    }

    setState(() {
      _isClassifying = true;
      _classifyingBytes = bytes;
    });

    try {
      final newItem = await ApiService.classifyGarment(bytes, pickedFile.name);
      setState(() {
        _wardrobe.insert(0, newItem);
        _isClassifying = false;
        _classifyingBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Prenda catalogada: ${newItem['nombre']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isClassifying = false;
        _classifyingBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al analizar prenda: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _deleteGarment(String id, String nombre) async {
    try {
      await ApiService.deleteGarment(id);
      setState(() {
        _wardrobe.removeWhere((item) => item['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Se eliminó "$nombre" del clóset.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al eliminar: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _generateOutfit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final outfit = await ApiService.generateOutfit(_selectedOccasion);
      setState(() {
        _isLoading = false;
      });
      // Pasar a la pantalla de resultados del outfit
      Navigator.pushNamed(
        context,
        '/outfit-result',
        arguments: outfit,
      ).then((_) => _loadData()); // Recargar cuotas al volver
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      final errStr = e.toString();
      if (errStr.contains('quota_exceeded') || errStr.contains('402')) {
        _showPremiumModal('Has agotado tus combinaciones gratuitas. Suscríbete a GlowAI Premium para generar outfits de temporada ilimitados.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al sugerir outfit: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showPremiumModal(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Desbloquea GlowStyle Premium',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.text),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/glowaipremium');
                  },
                  child: const Text('Obtener GlowAI Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _getImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage('images/logo_maestro_v5.webp');
    }
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    if (url.startsWith('images/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final filteredWardrobe = _selectedCategory == 'Todos'
        ? _wardrobe
        : _wardrobe.where((item) => item['categoria'] == _selectedCategory).toList();

    final plan = _userProfile?['glowai_plan'] ?? 'free';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'GlowStyle — Tu Clóset IA',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFFAF8F5),
        foregroundColor: const Color(0xFF1F1A15),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC5A052),
          unselectedLabelColor: const Color(0xFF8E7D7A),
          indicatorColor: const Color(0xFFC5A052),
          tabs: const [
            Tab(icon: Icon(Icons.style), text: 'Mi Clóset'),
            Tab(icon: Icon(Icons.brush_rounded), text: 'Outfits IA'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _isClassifying
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_classifyingBytes != null)
                      LaserScannerWidget(
                        imageBytes: _classifyingBytes!,
                        scanningTexts: _scanningTexts,
                      ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: AppTheme.primary),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Mi Clóset
                Column(
                  children: [
                    // Filtro de categorías horizontal
                    Container(
                      height: 52,
                      color: Colors.white,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                cat == 'Todos' ? 'Todos' : cat.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primary,
                              backgroundColor: const Color(0xFFF3EAE8),
                              onSelected: (val) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Límite de prendas Free
                    if (plan == 'free')
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.amber.shade50,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Clóset Gratuito: ${_wardrobe.length} de 5 prendas registradas.',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Grid del Clóset
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                          : filteredWardrobe.isEmpty
                              ? const Center(
                                  child: Text('No tienes prendas registradas en esta categoría.',
                                      style: TextStyle(color: Colors.grey)))
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.76,
                                  ),
                                  itemCount: filteredWardrobe.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredWardrobe[index];
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.2),
                                      ),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  child: Image(
                                                    image: _getImageProvider(item['image_url']),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['nombre'] ?? 'Prenda',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            (item['categoria'] ?? '').toUpperCase(),
                                                            style: const TextStyle(
                                                                fontSize: 9,
                                                                color: AppTheme.primary,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        Text(
                                                          item['color_predominante'] ?? 'Desconocido',
                                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Colors.white.withValues(alpha: 0.8),
                                              child: IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                                onPressed: () => _deleteGarment(item['id'], item['nombre'] ?? 'Prenda'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),

                // Pestaña 2: Outfits IA
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Diseña tu look ideal con IA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.text),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Combina tu guardarropa real con tus datos de colorimetría para crear la composición perfecta.',
                        style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.45),
                      ),
                      const SizedBox(height: 20),

                      // Selector de ocasión
                      const Text('1. Selecciona la ocasión para tu look:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _occasions.map((occ) {
                          final isSelected = _selectedOccasion == occ;
                          return ChoiceChip(
                            label: Text(occ.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              setState(() {
                                _selectedOccasion = occ;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Caja de colorimetría asociada
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3EAE8), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.palette_outlined, color: AppTheme.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Sinergias Cromáticas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'GlowStyle cruzará tu outfit con tu último diagnóstico de Colorimetría facial/capilar para validar la armonía de colores con tu subtono de piel.',
                              style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Caja de cuotas
                      Card(
                        elevation: 0,
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.amber.shade200, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cuota de Generación:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.text),
                              ),
                              const SizedBox(height: 4),
                              if (plan == 'free')
                                const Text(
                                  '• Plan Free: 2 outfits de muestra de por vida.',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                )
                              else
                                const Text(
                                  '• Plan Premium: 20 outfits al mes.',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _wardrobe.isEmpty ? null : _generateOutfit,
                        icon: const Icon(Icons.stars_rounded),
                        label: const Text('Sugerir Outfit Ideal con IA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (_wardrobe.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            '⚠️ Sube al menos una prenda en "Mi Clóset" para habilitar la sugerencia IA.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      floatingActionButton: _tabController.index == 0 && !_isClassifying
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFC5A052),
              foregroundColor: const Color(0xFF1F1A15),
              onPressed: _addGarment,
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
  }
}
