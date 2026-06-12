// frontend/lib/screens/designs/manicure_ideas_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class ManicureIdeasScreen extends StatefulWidget {
  const ManicureIdeasScreen({super.key});

  @override
  State<ManicureIdeasScreen> createState() => _ManicureIdeasScreenState();
}

class _ManicureIdeasScreenState extends State<ManicureIdeasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- COMPARTIDO: LÍMITES DE SESIÓN ---
  int _searchCount = 0;
  int _totalImagesLoaded = 0;
  static const int maxSearches = 2;
  static const int maxImages = 12;

  bool get _isLimitReached => _searchCount >= maxSearches || _totalImagesLoaded >= maxImages;

  // --- PESTAÑA 1: UÑAS ---
  String? _selectedColor;
  String? _selectedStyle;
  String? _selectedShape;
  final TextEditingController _customQueryController = TextEditingController();
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = false;
  String? _error;

  final List<String> _colors = ['Nude', 'Rojo', 'Negro', 'Blanco', 'Rosa Pastel', 'Gliter/Brillos'];
  final List<String> _styles = ['Francesa', 'Minimalista', 'Con Apliques', 'Mano Alzada', 'Efecto Espejo'];
  final List<String> _shapes = ['Almendra', 'Cuadrada', 'Ovalada', 'Stiletto', 'Coffin'];

  // --- PESTAÑA 2: CABELLO ---
  XFile? _selectedFaceImage;
  Uint8List? _faceImageBytes;
  bool _isAnalyzingFace = false;
  String? _faceError;
  Map<String, dynamic>? _faceAnalysisResult;
  List<Map<String, dynamic>> _hairImages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customQueryController.dispose();
    super.dispose();
  }

  // --- MÉTODOS UÑAS ---
  Future<void> _searchDesigns() async {
    if (_isLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Límite de sesión alcanzado (máximo 2 búsquedas o 12 imágenes).'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    List<String> queryParts = [];
    if (_selectedColor != null) queryParts.add('color $_selectedColor');
    if (_selectedStyle != null) queryParts.add(_selectedStyle!);
    if (_selectedShape != null) queryParts.add('forma $_selectedShape');
    if (_customQueryController.text.trim().isNotEmpty) {
      queryParts.add(_customQueryController.text.trim());
    }

    String query = queryParts.isNotEmpty ? queryParts.join(' ') : 'diseño de uñas de manicura';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await ApiService.fetchDesignIdeas(query);
      setState(() {
        _images = results.take(6).toList(); // Limitar estrictamente a 6 resultados
        _searchCount++;
        _totalImagesLoaded += _images.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error al buscar: $e';
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedColor = null;
      _selectedStyle = null;
      _selectedShape = null;
      _customQueryController.clear();
      _images.clear();
    });
  }

  // --- MÉTODOS CABELLO / VISAJISMO ---
  Future<void> _pickFaceImage(ImageSource source) async {
    if (_isLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Límite de sesión alcanzado (máximo 2 búsquedas o 12 imágenes).'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _selectedFaceImage = image;
        _faceImageBytes = bytes;
        _faceAnalysisResult = null;
        _hairImages.clear();
        _faceError = null;
      });

      _analyzeFace();
    } catch (e) {
      setState(() {
        _faceError = 'Error al seleccionar la imagen: $e';
      });
    }
  }

  Future<void> _analyzeFace() async {
    if (_faceImageBytes == null || _selectedFaceImage == null) return;

    setState(() {
      _isAnalyzingFace = true;
      _faceError = null;
    });

    try {
      final response = await ApiService.analyzeFaceShape(
        _faceImageBytes!,
        _selectedFaceImage!.name,
      );

      if (response['success'] == true && response['analysis'] != null) {
        final analysis = response['analysis'];
        final pinterestQuery = analysis['pinterest_query'] ?? 'cortes de cabello mujer';

        // Ahora buscar las imágenes reales de Pinterest usando el query sugerido
        List<Map<String, dynamic>> pinterestImages = [];
        try {
          final searchResults = await ApiService.fetchDesignIdeas(pinterestQuery);
          pinterestImages = searchResults.take(6).toList();
        } catch (searchErr) {
          print('Error buscando imágenes en Pinterest para corte: $searchErr');
        }

        setState(() {
          _faceAnalysisResult = analysis;
          _hairImages = pinterestImages;
          _searchCount++;
          _totalImagesLoaded += pinterestImages.length;
          _isAnalyzingFace = false;
        });
      } else {
        throw Exception('No se recibió la estructura de análisis esperada');
      }
    } catch (e) {
      setState(() {
        _faceError = 'Ocurrió un error en el análisis de rostro: $e';
        _isAnalyzingFace = false;
      });
    }
  }

  void _clearFaceData() {
    setState(() {
      _selectedFaceImage = null;
      _faceImageBytes = null;
      _faceAnalysisResult = null;
      _hairImages.clear();
      _faceError = null;
    });
  }

  // --- DIÁLOGOS Y COMPONENTES ---
  void _showImageFullscreen(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                image['title'] ?? 'Detalle de Idea',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      image['image_url'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.white30, size: 60),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, image['image_url']); // Retorna la imagen para usar en cita
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Referencia seleccionada: ${image['title']}'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Usar como referencia para mi cita', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppTheme.background,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar Foto del Rostro',
                style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickFaceImage(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickFaceImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text('Ideas y Visajismo IA', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _clearFilters();
              _clearFaceData();
            },
            tooltip: 'Limpiar todo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.brush), text: 'Uñas / Manicura'),
            Tab(icon: Icon(Icons.face), text: 'Cabello / Visajismo'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Panel de Control de Límites Compartido
            Container(
              width: double.infinity,
              color: AppTheme.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Búsquedas: $_searchCount / $maxSearches',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _searchCount >= maxSearches ? AppTheme.error : AppTheme.text,
                    ),
                  ),
                  Text(
                    'Imágenes cargadas: $_totalImagesLoaded / $maxImages',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _totalImagesLoaded >= maxImages ? AppTheme.error : AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLimitReached)
              Container(
                width: double.infinity,
                color: AppTheme.errorBg,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Has alcanzado el límite de 2 búsquedas de diseño en esta sesión.',
                        style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNailsTab(),
                  _buildHairTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VISTA PESTAÑA 1: UÑAS ---
  Widget _buildNailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color de esmalte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              return ChoiceChip(
                label: Text(color),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: _isLimitReached
                    ? null
                    : (selected) {
                        setState(() {
                          _selectedColor = selected ? color : null;
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text('Estilo / Decoración:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _styles.map((style) {
              final isSelected = _selectedStyle == style;
              return ChoiceChip(
                label: Text(style),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: _isLimitReached
                    ? null
                    : (selected) {
                        setState(() {
                          _selectedStyle = selected ? style : null;
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text('Forma de uña:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _shapes.map((shape) {
              final isSelected = _selectedShape == shape;
              return ChoiceChip(
                label: Text(shape),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: _isLimitReached
                    ? null
                    : (selected) {
                        setState(() {
                          _selectedShape = selected ? shape : null;
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _customQueryController,
            decoration: AppTheme.inputDecoration(
              hintText: 'ej: flores 3D, mate...',
              prefixIcon: Icons.edit_note,
              labelText: 'Detalle adicional',
            ),
            enabled: !_isLimitReached,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 2,
            ),
            onPressed: _isLoading || _isLimitReached ? null : _searchDesigns,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Buscar 6 Diseños Inspirados en Pinterest',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
          const SizedBox(height: 24),

          _buildImagesGrid(_images, _error),
        ],
      ),
    );
  }

  // --- VISTA PESTAÑA 2: CABELLO ---
  Widget _buildHairTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector / Previsualización de Foto de Rostro
          Center(
            child: Column(
              children: [
                if (_faceImageBytes != null)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 4),
                      image: DecorationImage(
                        image: MemoryImage(_faceImageBytes!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                  )
                else
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Icon(Icons.face_retouching_natural, size: 60, color: AppTheme.primary.withOpacity(0.7)),
                  ),
                const SizedBox(height: 16),
                if (_faceImageBytes == null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isLimitReached ? null : _showImageSourceSelector,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Subir Foto de mi Rostro', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!_isAnalyzingFace)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _showImageSourceSelector,
                        icon: const Icon(Icons.refresh, color: AppTheme.accent),
                        label: const Text('Cambiar foto', style: TextStyle(color: AppTheme.accent)),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _clearFaceData,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Loading de análisis de rostro
          if (_isAnalyzingFace) ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Analizando estructura facial con Inteligencia Artificial...',
                          style: AppTheme.subtitle.copyWith(color: AppTheme.text, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gemini 2.5 Flash está evaluando tus facciones para encontrar el corte ideal.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Resultados de Análisis de Rostro
          if (_faceAnalysisResult != null) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'Rostro Detectado: ${_faceAnalysisResult!["face_shape"]}',
                          style: AppTheme.h1.copyWith(fontSize: 20, color: AppTheme.text),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    Text(
                      _faceAnalysisResult!["explanation"] ?? '',
                      style: AppTheme.body.copyWith(fontSize: 14, color: AppTheme.text),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Cortes Recomendados:',
                      style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    const SizedBox(height: 10),
                    ...(_faceAnalysisResult!["recommended_cuts"] as List<dynamic>).map((cut) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTheme.body.copyWith(color: AppTheme.text),
                                  children: [
                                    TextSpan(
                                      text: '${cut["name"]}: ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: cut["reason"]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Galería Pinterest Cabello
          if (_hairImages.isNotEmpty) ...[
            const Text(
              'Ideas de Pinterest para tu rostro:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hairImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final item = _hairImages[index];
                return GestureDetector(
                  onTap: () => _showImageFullscreen(item),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, size: 40));
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              item['title'] ?? 'Corte recomendado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          if (_faceError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _faceError!,
                style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // --- REUTILIZABLE: GRID DE IMÁGENES ---
  Widget _buildImagesGrid(List<Map<String, dynamic>> imagesList, String? errorMsg) {
    if (imagesList.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diseños Encontrados (Toca para ampliar):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imagesList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final item = imagesList[index];
              return GestureDetector(
                onTap: () => _showImageFullscreen(item),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 40));
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            item['title'] ?? 'Diseño',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    if (errorMsg != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          errorMsg,
          style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
