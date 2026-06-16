// frontend/lib/screens/designs/manicure_ideas_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class ManicureIdeasScreen extends StatefulWidget {
  static Map<String, dynamic>? selectedReference;

  const ManicureIdeasScreen({super.key});

  @override
  State<ManicureIdeasScreen> createState() => _ManicureIdeasScreenState();
}

class _ManicureIdeasScreenState extends State<ManicureIdeasScreen> {
  // --- COMPARTIDO: LÍMITES DE SESIÓN ---
  int _searchCount = 0;
  int _totalImagesLoaded = 0;
  static const int maxSearches = 2;
  static const int maxImages = 12;

  bool get _isLimitReached => _searchCount >= maxSearches || _totalImagesLoaded >= maxImages;

  // --- NAVEGACIÓN DASHBOARD ---
  String? _activeToolId;

  // --- PESTAÑA 1: UÑAS TRADICIONALES ---
  String? _selectedColor;
  String? _selectedStyle;
  String? _selectedShape;
  final TextEditingController _customQueryController = TextEditingController();
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _nailColors = const [
    {'name': 'Rojo', 'color': Color(0xFFC41E3A)},
    {'name': 'Azul', 'color': Color(0xFF1E90FF)},
    {'name': 'Amarillo', 'color': Color(0xFFFFD700)},
    {'name': 'Verde', 'color': Color(0xFF4A5D4E)},
    {'name': 'Morado', 'color': Color(0xFFD8B4F8)},
    {'name': 'Naranja', 'color': Color(0xFFFF7F50)},
    {'name': 'Nude', 'color': Color(0xFFEADBC8)},
    {'name': 'Negro', 'color': Color(0xFF1A1A1A)},
    {'name': 'Blanco', 'color': Color(0xFFF9F9F9), 'border': true},
    {'name': 'Rosa', 'color': Color(0xFFFFC5C5)},
    {'name': 'Gliter', 'color': Color(0xFFD3D3D3)},
  ];
  final List<String> _styles = ['Francesa', 'Minimalista', 'Con Apliques', 'Mano Alzada', 'Efecto Espejo'];
  final List<String> _shapes = ['Almendra', 'Cuadrada', 'Ovalada', 'Stiletto', 'Coffin'];

  // --- VARIABLES GENÉRICAS DE ANÁLISIS DE IA ---
  XFile? _selectedAnalysisImage;
  Uint8List? _analysisImageBytes;
  bool _isAnalyzing = false;
  String? _analysisError;
  Map<String, dynamic>? _analysisResult;
  List<Map<String, dynamic>> _pinterestImages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _customQueryController.dispose();
    super.dispose();
  }

  // --- MÉTODOS UÑAS TRADICIONALES ---
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
        _images = results.take(6).toList(); // Limitar a 6
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

  // --- MÉTODOS ANÁLISIS DE IA GENÉRICOS ---
  void _resetAnalysisState() {
    setState(() {
      _selectedAnalysisImage = null;
      _analysisImageBytes = null;
      _isAnalyzing = false;
      _analysisError = null;
      _analysisResult = null;
      _pinterestImages = [];
    });
  }

  Future<bool> _showBiometricConsentDialog() async {
    bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Consentimiento de Datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Para ofrecerte un diagnóstico preciso asistido por Inteligencia Artificial (Gemini API), necesitamos analizar temporalmente la imagen que proporciones.\n\n'
                'GlowApp no almacena permanentemente datos biométricos sensibles de tu rostro. Las imágenes procesadas se gestionan con cifrado y se eliminan tras el análisis.',
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Autorizar y Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return accepted ?? false;
  }

  Future<void> _pickAnalysisImage(ImageSource source) async {
    if (_isLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Límite de sesión alcanzado (máximo 2 búsquedas o 12 imágenes).'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final bool consent = await _showBiometricConsentDialog();
    if (!consent) return;

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
        _selectedAnalysisImage = image;
        _analysisImageBytes = bytes;
        _analysisResult = null;
        _pinterestImages.clear();
        _analysisError = null;
      });

      _analyzeWithAI();
    } catch (e) {
      setState(() {
        _analysisError = 'Error al seleccionar la imagen: $e';
      });
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_analysisImageBytes == null || _selectedAnalysisImage == null || _activeToolId == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final response = await ApiService.analyzeDesignWithAI(
        _analysisImageBytes!,
        _selectedAnalysisImage!.name,
        _activeToolId!,
      );

      if (response['success'] == true && response['analysis'] != null) {
        final analysis = response['analysis'];
        final pinterestQuery = analysis['pinterest_query'] ?? 'diseño de belleza';

        List<Map<String, dynamic>> images = [];
        try {
          final searchResults = await ApiService.fetchDesignIdeas(pinterestQuery);
          images = searchResults.take(6).toList();
        } catch (searchErr) {
          debugPrint('Error buscando imágenes en Pinterest: $searchErr');
        }

        setState(() {
          _analysisResult = analysis;
          _pinterestImages = images;
          _searchCount++;
          _totalImagesLoaded += images.length;
          _isAnalyzing = false;
        });
      } else {
        throw Exception('No se recibió la estructura de análisis esperada');
      }
    } catch (e) {
      setState(() {
        _analysisError = 'Ocurrió un error en el análisis de IA: $e';
        _isAnalyzing = false;
      });
    }
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
                  final ref = {
                    'image_url': image['image_url'],
                    'title': image['title'] ?? 'Referencia',
                    'category': _activeToolId ?? 'nails-classic'
                  };
                  ManicureIdeasScreen.selectedReference = ref;
                  Navigator.pop(context);
                  Navigator.pop(context, ref);
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



  bool _argsChecked = false;

  @override
  Widget build(BuildContext context) {
    // Check if arguments contain a pre-loaded toolId from the chat assistant
    if (!_argsChecked) {
      _argsChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null && args['toolId'] != null) {
            setState(() {
              _activeToolId = args['toolId'] as String;
            });
            _resetAnalysisState();
          }
        } catch (_) {}
      });
    }

    String screenTitle = 'Ideas y Visajismo IA';
    if (_activeToolId != null) {
      if (_activeToolId == 'nails-classic') screenTitle = 'Buscador de Uñas';
      else if (_activeToolId == 'skin-tone') screenTitle = 'Colorimetría IA';
      else if (_activeToolId == 'hair-diagnostic') screenTitle = 'Diagnóstico Capilar';
      else if (_activeToolId == 'skin-texture') screenTitle = 'Escáner de Poros';
      else if (_activeToolId == 'eyebrow-visagism') screenTitle = 'Visagismo de Cejas';
      else if (_activeToolId == 'nails-style') screenTitle = 'Estilo de Uñas IA';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _activeToolId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _activeToolId = null;
                  });
                },
              )
            : null,
        actions: [
          if (_activeToolId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_activeToolId == 'nails-classic') {
                  _clearFilters();
                } else {
                  _resetAnalysisState();
                }
              },
              tooltip: 'Reiniciar herramienta',
            ),
        ],
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
                        'Has alcanzado el límite de búsquedas de diseño en esta sesión.',
                        style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _activeToolId == null
                  ? _buildDashboard()
                  : (_activeToolId == 'nails-classic'
                      ? _buildNailsTab()
                      : _buildGenericAIToolTab()),
            ),
          ],
        ),
      ),
    );
  }

  // --- VISTA: DASHBOARD DE HERRAMIENTAS ---
  Widget _buildDashboard() {
    final tools = [
      {
        'id': 'nails-classic',
        'title': 'Buscador de Diseños de Uñas',
        'description': 'Filtra ideas de Pinterest por color, estilo y forma de uña.',
        'icon': Icons.brush_rounded,
        'tag': 'TRADICIONAL',
      },
      {
        'id': 'skin-tone',
        'title': 'Analizador de Colorimetría',
        'description': 'Determina tu tono y subtono de piel para encontrar tu paleta de color ideal.',
        'icon': Icons.palette_rounded,
        'tag': 'IA',
      },
      {
        'id': 'hair-diagnostic',
        'title': 'Diagnóstico Capilar Inteligente',
        'description': 'Evalúa el nivel de daño y tipo de tu hebra capilar para sugerir tratamientos.',
        'icon': Icons.spa_rounded,
        'tag': 'IA',
      },
      {
        'id': 'skin-texture',
        'title': 'Escáner de Textura y Poros',
        'description': 'Detecta el tipo de piel, poros e imperfecciones para una rutina de skincare.',
        'icon': Icons.face_retouching_natural_rounded,
        'tag': 'IA',
      },
      {
        'id': 'eyebrow-visagism',
        'title': 'Simulador de Visagismo de Cejas',
        'description': 'Estudia las proporciones de tu rostro para sugerir la ceja ideal.',
        'icon': Icons.remove_red_eye_rounded,
        'tag': 'IA',
      },
      {
        'id': 'nails-style',
        'title': 'Guía de Estilo de Uñas IA',
        'description': 'Analiza tu mano y dedos para recomendarte formas y esmaltes.',
        'icon': Icons.back_hand_rounded,
        'tag': 'IA',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige una herramienta para comenzar:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final tool = tools[index];
              final isIA = tool['tag'] == 'IA';
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activeToolId = tool['id'] as String;
                  });
                  _resetAnalysisState();
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isIA ? AppTheme.primary.withOpacity(0.25) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isIA ? AppTheme.primary : AppTheme.accent).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tool['icon'] as IconData,
                                color: isIA ? AppTheme.primary : AppTheme.accent,
                                size: 24,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isIA ? const Color(0xFFE8D7D3) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tool['tag'] as String,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: isIA ? AppTheme.primary : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tool['title'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            tool['description'] as String,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nailColors.length,
              itemBuilder: (context, index) {
                final nailColor = _nailColors[index];
                final colorName = nailColor['name'] as String;
                final colorVal = nailColor['color'] as Color;
                final hasBorder = nailColor['border'] == true;
                final isSelected = _selectedColor == colorName;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Tooltip(
                    message: colorName,
                    child: GestureDetector(
                      onTap: _isLimitReached
                          ? null
                          : () {
                              setState(() {
                                _selectedColor = isSelected ? null : colorName;
                              });
                            },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorVal,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : (hasBorder ? Colors.grey.shade400 : Colors.transparent),
                            width: isSelected ? 3.0 : 1.5,
                          ),
                          boxShadow: isSelected ? AppTheme.softShadow : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: colorVal.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

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

  // --- VISTA: ANÁLISIS DE IA GENÉRICA ---
  Widget _buildGenericAIToolTab() {
    String instructionText = 'Sube una foto clara con buena iluminación.';
    IconData cameraIcon = Icons.add_a_photo;
    
    if (_activeToolId == 'skin-tone') {
      instructionText = 'Sube una foto frontal de tu rostro con iluminación natural.';
      cameraIcon = Icons.face_retouching_natural;
    } else if (_activeToolId == 'hair-diagnostic') {
      instructionText = 'Sube una foto de cerca del estado de tu hebra capilar.';
      cameraIcon = Icons.spa;
    } else if (_activeToolId == 'skin-texture') {
      instructionText = 'Sube una foto de primer plano de la piel de tus mejillas o zona T.';
      cameraIcon = Icons.camera_front;
    } else if (_activeToolId == 'eyebrow-visagism') {
      instructionText = 'Sube una foto frontal centrada de tu rostro para visagismo.';
      cameraIcon = Icons.remove_red_eye;
    } else if (_activeToolId == 'nails-style') {
      instructionText = 'Sube una foto plana de tu mano abierta para analizar la forma.';
      cameraIcon = Icons.back_hand;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                if (_analysisImageBytes != null)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 4),
                      image: DecorationImage(
                        image: MemoryImage(_analysisImageBytes!),
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
                    child: Icon(cameraIcon, size: 60, color: AppTheme.primary.withOpacity(0.7)),
                  ),
                const SizedBox(height: 12),
                Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                if (_analysisImageBytes == null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isLimitReached ? null : _showGenericImageSourceSelector,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Subir Foto para Análisis', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!_isAnalyzing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _showGenericImageSourceSelector,
                        icon: const Icon(Icons.refresh, color: AppTheme.accent),
                        label: const Text('Cambiar foto', style: TextStyle(color: AppTheme.accent)),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _resetAnalysisState,
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Loader
          if (_isAnalyzing) ...[
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
                          'Analizando imagen con Inteligencia Artificial...',
                          style: AppTheme.subtitle.copyWith(color: AppTheme.text, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gemini 2.5 Flash está evaluando tu imagen para darte las mejores sugerencias.',
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

          // Resultados
          if (_analysisResult != null) ...[
            _buildAnalysisResultsCard(),
            const SizedBox(height: 24),
          ],

          // Galería Pinterest
          if (_pinterestImages.isNotEmpty) ...[
            const Text(
              'Ideas de inspiración en Pinterest:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pinterestImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final item = _pinterestImages[index];
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
                              item['title'] ?? 'Recomendación',
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

          if (_analysisError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _analysisError!,
                style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultsCard() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final List<Widget> details = [];

    if (_activeToolId == 'skin-tone') {
      details.add(_buildResultRow('Tono general:', _analysisResult!['skin_tone']));
      details.add(_buildResultRow('Subtono:', _analysisResult!['undertone']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Colores sugeridos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ((_analysisResult!['recommended_colors'] ?? []) as List<dynamic>).map((c) {
          return Chip(
            label: Text(c.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'hair-diagnostic') {
      details.add(_buildResultRow('Nivel de daño:', _analysisResult!['damage_level']));
      details.add(_buildResultRow('Condición general:', _analysisResult!['scalp_status']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Tratamientos sugeridos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Column(
        children: ((_analysisResult!['recommended_treatments'] ?? []) as List<dynamic>).map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(t.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'skin-texture') {
      details.add(_buildResultRow('Tipo de piel:', _analysisResult!['skin_type']));
      details.add(_buildResultRow('Estado de poros:', _analysisResult!['pore_status']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Rutina facial recomendada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Column(
        children: ((_analysisResult!['recommended_routine'] ?? []) as List<dynamic>).map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'eyebrow-visagism') {
      details.add(_buildResultRow('Proporciones del rostro:', _analysisResult!['face_proportions']));
      details.add(_buildResultRow('Cejas recomendadas:', _analysisResult!['eyebrow_shape']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Diseños y Técnicas sugeridas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Column(
        children: ((_analysisResult!['recommended_designs'] ?? []) as List<dynamic>).map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(d.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'nails-style') {
      details.add(_buildResultRow('Proporción dedos:', _analysisResult!['finger_proportion']));
      details.add(_buildResultRow('Subtono mano:', _analysisResult!['skin_undertone']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Formas de uñas ideales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Wrap(
        spacing: 8,
        children: ((_analysisResult!['recommended_shapes'] ?? []) as List<dynamic>).map((s) {
          return Chip(
            label: Text(s.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.accent.withOpacity(0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Esmaltes recomendados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Wrap(
        spacing: 8,
        children: ((_analysisResult!['recommended_colors'] ?? []) as List<dynamic>).map((c) {
          return Chip(
            label: Text(c.toString(), style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
    }

    return Card(
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
                const Icon(Icons.stars_rounded, color: AppTheme.primary, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Resultado del Análisis IA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.text),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Text(
              _analysisResult!['explanation'] ?? '',
              style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.45),
            ),
            const SizedBox(height: 16),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13.5, color: AppTheme.text),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  void _showGenericImageSourceSelector() {
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
                'Seleccionar Foto para Análisis',
                style: AppTheme.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAnalysisImage(ImageSource.camera);
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
                      _pickAnalysisImage(ImageSource.gallery);
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
