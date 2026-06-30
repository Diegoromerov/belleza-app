// frontend/lib/screens/designs/manicure_ideas_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';
import '../booking_screen.dart';

// ============================================================================
// NUEVO WIDGET: Escáner Láser Animado (Seguro con Timer)
// ============================================================================
class LaserScannerWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final List<String> scanningTexts;
  
  const LaserScannerWidget({
    super.key,
    required this.imageBytes,
    required this.scanningTexts,
  });

  @override
  State<LaserScannerWidget> createState() => _LaserScannerWidgetState();
}

class _LaserScannerWidgetState extends State<LaserScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentTextIndex = 0;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
    
    // Cambiar texto de diagnóstico cada 1.2 segundos usando un Timer controlado
    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % widget.scanningTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen con bordes redondeados profundos
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(
            widget.imageBytes,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        
        // Overlay oscuro semitransparente
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        
        // Línea láser animada horizontal
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              top: _animation.value * 260,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89D93).withValues(alpha: 0.8),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFFC89D93),
                        Colors.white,
                        Color(0xFFC89D93),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Texto dinámico de diagnóstico
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.scanningTexts[_currentTextIndex],
                key: ValueKey<int>(_currentTextIndex),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB07D62),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// NUEVO WIDGET: Barra de Progreso Glow Credits con Gradiente
// ============================================================================
class GlowCreditsBar extends StatelessWidget {
  final int currentSearches;
  final int maxSearches;
  final int currentImages;
  final int maxImages;
  final VoidCallback? onUpgradeTap;

  const GlowCreditsBar({
    super.key,
    required this.currentSearches,
    required this.maxSearches,
    required this.currentImages,
    required this.maxImages,
    this.onUpgradeTap,
  });

  double get _searchProgress => currentSearches / maxSearches;
  double get _imagesProgress => currentImages / maxImages;
  double get _overallProgress => [_searchProgress, _imagesProgress].reduce((a, b) => a > b ? a : b);
  bool get _isLimitReached => currentSearches >= maxSearches || currentImages >= maxImages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC89D93).withValues(alpha: 0.25),
            const Color(0xFFB07D62).withValues(alpha: 0.25),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: _isLimitReached ? AppTheme.error : const Color(0xFFC89D93),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Glow Credits',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isLimitReached ? AppTheme.error : AppTheme.text,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentSearches/$maxSearches búsquedas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isLimitReached ? AppTheme.error : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Barra de progreso con gradiente
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: Colors.grey.shade200,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double fullWidth = constraints.maxWidth;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLimitReached
                              ? [AppTheme.error, AppTheme.error.withValues(alpha: 0.7)]
                              : [const Color(0xFFC89D93), const Color(0xFFB07D62)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: fullWidth * (_overallProgress > 1.0 ? 1.0 : _overallProgress),
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentImages/$maxImages imágenes cargadas',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_isLimitReached && onUpgradeTap != null)
                GestureDetector(
                  onTap: onUpgradeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC89D93), Color(0xFFB07D62)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Desbloquear Ilimitado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NUEVO WIDGET: Tarjeta Premium para Límite Alcanzado
// ============================================================================
class PremiumUpgradeCard extends StatelessWidget {
  final VoidCallback onScheduleTap;

  const PremiumUpgradeCard({
    super.key,
    required this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC89D93).withValues(alpha: 0.2),
            const Color(0xFFB07D62).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC89D93).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC89D93).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.diamond_rounded,
              color: Color(0xFFC89D93),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Límite de sesión alcanzado!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agenda tu cita ahora y obtén créditos de consulta ilimitados + beneficios exclusivos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: onScheduleTap,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text(
                'Agendar Cita Ahora',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  bool _privacyConsentAccepted = false;

  // Textos dinámicos para el escáner láser según el tipo de análisis
  final Map<String, List<String>> _scanningTexts = {
    'skin-tone': [
      'Identificando tono de piel...',
      'Analizando subtonos...',
      'Detectando características faciales...',
      'Generando paleta de colores...',
    ],
    'hair-diagnostic': [
      'Evaluando hebra capilar...',
      'Analizando nivel de hidratación...',
      'Detectando daño y porosidad...',
      'Generando recomendaciones...',
    ],
    'skin-texture': [
      'Identificando pigmentación de la piel...',
      'Evaluando poros e hidratación...',
      'Analizando textura superficial...',
      'Generando rutina personalizada...',
    ],
    'eyebrow-visagism': [
      'Midiendo proporciones faciales...',
      'Analizando simetría...',
      'Detectando forma natural...',
      'Diseñando cejas ideales...',
    ],
    'nails-style': [
      'Analizando forma de mano...',
      'Evaluando longitud de dedos...',
      'Detectando subtono de piel...',
      'Recomendando formas ideales...',
    ],
    'care-routine': [
      'Analizando tipo de piel/cabello...',
      'Evaluando necesidades específicas...',
      'Detectando condiciones especiales...',
      'Planificando rutina semanal...',
    ],
    'hair-color': [
      'Analizando subtono de piel...',
      'Evaluando forma de rostro...',
      'Detectando características únicas...',
      'Recomendando tonos ideales...',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadLocalCredits();
  }

  Future<void> _loadLocalCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchCount = prefs.getInt('glow_search_count') ?? 0;
        _totalImagesLoaded = prefs.getInt('glow_total_images_loaded') ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading local credits: $e');
    }
  }

  Future<void> _incrementSearchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchCount++;
      });
      await prefs.setInt('glow_search_count', _searchCount);
      debugPrint('📊 [Analytics EVENT] tool_search_performed: toolId=$_activeToolId, searchCount=$_searchCount');
    } catch (e) {
      debugPrint('Error saving search count: $e');
    }
  }

  Future<void> _incrementImagesCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _totalImagesLoaded += count;
      });
      await prefs.setInt('glow_total_images_loaded', _totalImagesLoaded);
      debugPrint('📊 [Analytics EVENT] images_loaded: count=$count, totalImages=$_totalImagesLoaded');
    } catch (e) {
      debugPrint('Error saving image count: $e');
    }
  }

  @override
  void dispose() {
    _customQueryController.dispose();
    super.dispose();
  }

  // --- MÉTODOS UÑAS TRADICIONALES ---
  Future<void> _searchDesigns() async {
    if (_isLimitReached) {
      _showPremiumUpgradeBottomSheet();
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
      final List<Map<String, dynamic>> updatedResults = results.take(5).toList();
      updatedResults.insert(0, _getSimulatedProduct());
      setState(() {
        _images = updatedResults;
        _isLoading = false;
      });
      _incrementSearchCount();
      _incrementImagesCount(_images.length);
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
      _privacyConsentAccepted = false;
    });
  }

  void _showPremiumUpgradeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                PremiumUpgradeCard(
                  onScheduleTap: () {
                    Navigator.pop(context);
                    // Redirigir al agendamiento directamente
                    _handleUpgradeBookingRedirect();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpgradeBookingRedirect() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text(
                  'Conectando con la agenda...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final providers = await ApiService.fetchProvidersSecured();
      if (!mounted) return;
      Navigator.pop(context); // Cerrar cargando

      if (providers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay profesionales disponibles en este momento.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final provider = providers.first;
      final details = await ApiService.fetchProviderDetails(provider.id);
      if (!mounted) return;

      final services = List<Map<String, dynamic>>.from(details['services'] ?? []);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            providerId: provider.id,
            providerName: provider.businessName,
            services: services,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar cargando
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con la agenda: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showPrivacyInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC89D93).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFFC89D93)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Privacidad y Protección de Datos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Cómo protegemos tu información:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem(
              Icons.hourglass_empty_rounded,
              'Análisis Temporal',
              'Las imágenes se procesan temporalmente con Inteligencia Artificial (Gemini API) y se eliminan automáticamente después del análisis.',
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem(
              Icons.lock_outline,
              'Sin Almacenamiento Permanente',
              'GlowApp no almacena datos biométricos sensibles de forma permanente en nuestros servidores.',
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem(
              Icons.security,
              'Cifrado de Datos',
              'Todas las imágenes se transmiten y procesan con cifrado de extremo a extremo.',
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem(
              Icons.visibility_off,
              'Uso Exclusivo para Diagnóstico',
              'Tus imágenes solo se utilizan para generar recomendaciones personalizadas de belleza.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    color: Color(0xFFC89D93),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFC89D93)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAnalysisImage(ImageSource source) async {
    if (_isLimitReached) {
      _showPremiumUpgradeBottomSheet();
      return;
    }

    if (!_privacyConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos de privacidad primero'),
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
          final List<Map<String, dynamic>> updatedResults = searchResults.take(5).toList();
          updatedResults.insert(0, _getSimulatedProduct());
          images = updatedResults;
        } catch (searchErr) {
          debugPrint('Error buscando imágenes en Pinterest: $searchErr');
        }

        setState(() {
          _analysisResult = analysis;
          _pinterestImages = images;
          _isAnalyzing = false;
        });
        _incrementSearchCount();
        _incrementImagesCount(images.length);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC89D93),
                      side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close preview
                      Navigator.pop(context, {
                        'action': 'filter_map',
                        'toolId': _activeToolId ?? 'nails-classic',
                        'category': _activeToolId == 'nails-classic' ? 'nails' : 'all'
                      });
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver en el mapa quién hace este estilo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
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
      if (_activeToolId == 'nails-classic') {
        screenTitle = 'Buscador de Uñas';
      } else if (_activeToolId == 'skin-tone') screenTitle = 'Colorimetría IA';
      else if (_activeToolId == 'hair-diagnostic') screenTitle = 'Diagnóstico Capilar';
      else if (_activeToolId == 'skin-texture') screenTitle = 'Escáner de Poros';
      else if (_activeToolId == 'eyebrow-visagism') screenTitle = 'Visagismo de Cejas';
      else if (_activeToolId == 'nails-style') screenTitle = 'Estilo de Uñas IA';
      else if (_activeToolId == 'care-routine') screenTitle = 'Planificador Skincare';
      else if (_activeToolId == 'hair-color') screenTitle = 'Colorimetría Capilar';
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
            // Panel de Control de Límites Compartido (Glow Credits)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GlowCreditsBar(
                currentSearches: _searchCount,
                maxSearches: maxSearches,
                currentImages: _totalImagesLoaded,
                maxImages: maxImages,
                onUpgradeTap: _isLimitReached ? _showPremiumUpgradeBottomSheet : null,
              ),
            ),

            if (_isLimitReached)
              PremiumUpgradeCard(
                onScheduleTap: _handleUpgradeBookingRedirect,
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

  Widget _buildDashboard() {
    final tools = [
      {
        'id': 'nails-classic',
        'title': 'Buscador de Diseños de Uñas',
        'description': 'Filtra ideas de Pinterest por color, estilo y forma.',
        'icon': Icons.brush_rounded,
        'tag': 'TRADICIONAL',
        'image': 'assets/images/design_ideas_nails_classic_1781572880027.png',
      },
      {
        'id': 'skin-tone',
        'title': 'Analizador de Colorimetría',
        'description': 'Determina tu paleta de color ideal según tu tono de piel.',
        'icon': Icons.palette_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_skin_tone_1781572896303.png',
      },
      {
        'id': 'hair-diagnostic',
        'title': 'Diagnóstico Capilar Inteligente',
        'description': 'Evalúa tu hebra capilar para sugerir tratamientos.',
        'icon': Icons.spa_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_hair_diagnostic_1781572914936.png',
      },
      {
        'id': 'skin-texture',
        'title': 'Escáner de Textura y Poros',
        'description': 'Analiza poros e hidratación para tu rutina facial.',
        'icon': Icons.face_retouching_natural_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_skin_texture_1781572933469.png',
      },
      {
        'id': 'eyebrow-visagism',
        'title': 'Simulador de Visagismo de Cejas',
        'description': 'Sugerencias de cejas según tus proporciones faciales.',
        'icon': Icons.remove_red_eye_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_eyebrow_visagism_1781572947958.png',
      },
      {
        'id': 'nails-style',
        'title': 'Guía de Estilo de Uñas IA',
        'description': 'Recomendación de formas y esmaltes según tu mano.',
        'icon': Icons.back_hand_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_nails_style_1781572969602.png',
      },
      {
        'id': 'care-routine',
        'title': 'Planificador Skincare & Haircare',
        'description': 'Genera tu rutina semanal de cuidado personal con IA.',
        'icon': Icons.calendar_month_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_skin_texture_1781572933469.png',
      },
      {
        'id': 'hair-color',
        'title': 'Colorimetría Capilar IA',
        'description': 'Determina tus tonos de tinte y corte según tu rostro y piel.',
        'icon': Icons.face_retouching_natural_rounded,
        'tag': 'IA',
        'image': 'assets/images/design_ideas_hair_diagnostic_1781572914936.png',
      },
    ];

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Elige una herramienta para comenzar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.70,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tool = tools[index];
                final isIA = tool['tag'] == 'IA';
                final imageAsset = tool['image'] as String;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeToolId = tool['id'] as String;
                    });
                    _resetAnalysisState();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isIA ? const Color(0xFFC89D93).withValues(alpha: 0.25) : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                          child: Image.asset(
                            imageAsset,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isIA
                                      ? [const Color(0xFFC89D93), const Color(0xFFEADBC8)]
                                      : [const Color(0xFFB07D62), const Color(0xFFEADBC8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                tool['icon'] as IconData,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      tool['icon'] as IconData,
                                      color: isIA ? const Color(0xFFC89D93) : const Color(0xFFB07D62),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isIA ? const Color(0xFFF3ECE6) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tool['tag'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isIA ? const Color(0xFFC89D93) : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tool['title'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    tool['description'] as String,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: tools.length,
            ),
          ),
        ),
      ],
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
            height: 52,
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
                    message: _isLimitReached 
                        ? '$colorName (Límite alcanzado, agenda tu cita para créditos ilimitados)' 
                        : colorName,
                    child: GestureDetector(
                      onTap: () {
                        if (_isLimitReached) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('⚠️ Límite alcanzado. Agenda tu cita para tener créditos ilimitados.'),
                              backgroundColor: AppTheme.error,
                              action: SnackBarAction(
                                label: 'Agendar',
                                textColor: Colors.white,
                                onPressed: _showPremiumUpgradeBottomSheet,
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedColor = isSelected ? null : colorName;
                        });
                      },
                      child: Semantics(
                        label: 'Esmalte color $colorName',
                        selected: isSelected,
                        button: true,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          color: Colors.transparent,
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
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_selectedColor != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC89D93).withValues(alpha: 0.2),
                    const Color(0xFFB07D62).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC89D93).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.color_lens,
                    color: Color(0xFFC89D93),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Color seleccionado: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _selectedColor!,
                      key: ValueKey<String>(_selectedColor!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB07D62),
                      ),
                    ),
                  ),
                ],
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
    } else if (_activeToolId == 'care-routine') {
      instructionText = 'Sube una foto de tu rostro o cabello para planificar tu rutina semanal de cuidado.';
      cameraIcon = Icons.calendar_month_rounded;
    } else if (_activeToolId == 'hair-color') {
      instructionText = 'Sube una foto de tu rostro para recibir recomendaciones de tinte y corte ideal.';
      cameraIcon = Icons.color_lens_rounded;
    }

    final List<String> currentScanningTexts = _scanningTexts[_activeToolId] ?? [
      'Analizando imagen...',
      'Procesando con IA...',
      'Generando diagnóstico...',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                if (_analysisImageBytes != null)
                  _isAnalyzing
                      ? LaserScannerWidget(
                          imageBytes: _analysisImageBytes!,
                          scanningTexts: currentScanningTexts,
                        )
                      : Container(
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Icon(
                          cameraIcon,
                          size: 50,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sube tu foto para análisis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (!_isAnalyzing)
                  Text(
                    instructionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 16),
                
                // Switch de Consentimiento Biométrico Contextual Inline
                if (_analysisImageBytes == null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CheckboxListTile(
                      activeColor: AppTheme.primary,
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Acepto el análisis temporal biométrico',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 18, color: Color(0xFFC89D93)),
                            onPressed: _showPrivacyInfoBottomSheet,
                            tooltip: 'Más información de privacidad',
                          ),
                        ],
                      ),
                      value: _privacyConsentAccepted,
                      onChanged: (val) {
                        setState(() {
                          _privacyConsentAccepted = val ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_analysisImageBytes == null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: _privacyConsentAccepted ? 2 : 0,
                    ),
                    onPressed: _isLimitReached || !_privacyConsentAccepted 
                        ? null 
                        : _showGenericImageSourceSelector,
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
                          'Generando sugerencias con Inteligencia Artificial...',
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
                return _buildGalleryCard(item);
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
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
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
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'care-routine') {
      details.add(_buildResultRow('Tipo de piel/cabello:', _analysisResult!['skin_type']));
      details.add(_buildResultRow('Estado/Condición:', _analysisResult!['scalp_status']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Rutina semanal recomendada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Column(
        children: ((_analysisResult!['recommended_routine'] ?? []) as List<dynamic>).map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }).toList(),
      ));
    } else if (_activeToolId == 'hair-color') {
      details.add(_buildResultRow('Subtono de piel:', _analysisResult!['skin_undertone']));
      details.add(_buildResultRow('Forma de rostro:', _analysisResult!['face_shape']));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Tonos de tinte recomendados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ((_analysisResult!['recommended_shades'] ?? []) as List<dynamic>).map((s) {
          return Chip(
            label: Text(s.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
      details.add(const SizedBox(height: 12));
      details.add(const Text('Colores ideales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text)));
      details.add(const SizedBox(height: 6));
      details.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ((_analysisResult!['recommended_colors'] ?? []) as List<dynamic>).map((c) {
          return Chip(
            label: Text(c.toString(), style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
            side: BorderSide.none,
          );
        }).toList(),
      ));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: AppTheme.primary, size: 28),
                SizedBox(width: 10),
                Text(
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC89D93),
                  side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // Mapear el ID de la herramienta activa a la categoría de la base de datos
                  String category = 'all';
                  if (_activeToolId == 'nails-style') {
                    category = 'nails';
                  } else if (_activeToolId == 'hair-diagnostic' || _activeToolId == 'hair-color') category = 'hair';
                  else if (_activeToolId == 'skin-texture' || _activeToolId == 'skin-tone' || _activeToolId == 'care-routine') category = 'facials';

                  Navigator.pop(context, {
                    'action': 'filter_map',
                    'toolId': _activeToolId,
                    'category': category
                  });
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en el mapa quién hace este estilo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
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
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = imagesList[index];
              if (item['is_product'] == true) {
                return _buildProductCard(item);
              }
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
                            ),
                          );
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

  Map<String, dynamic> _getSimulatedProduct() {
    final tool = _activeToolId ?? 'nails-classic';
    if (tool.contains('hair')) {
      return {
        'is_product': true,
        'id': '1',
        'title': 'Kit Balayage Pro',
        'price': '45.000 COP',
        'description': 'Champú y acondicionador para el mantenimiento de tonos rubios y balayage en casa.',
        'image_url': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=200',
      };
    } else if (tool.contains('skin') || tool.contains('facial')) {
      return {
        'is_product': true,
        'id': '4',
        'title': 'Sérum Facial Ácido Hialurónico',
        'price': '55.000 COP',
        'description': 'Sérum hidratante concentrado para uso post-limpieza facial.',
        'image_url': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=200',
      };
    } else if (tool.contains('eyebrow') || tool.contains('ceja')) {
      return {
        'is_product': true,
        'id': '6',
        'title': 'Gel Moldeador de Cejas Orgánico',
        'price': '18.000 COP',
        'description': 'Fijador de cejas efecto laminado de larga duración.',
        'image_url': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=200',
      };
    } else {
      return {
        'is_product': true,
        'id': '2',
        'title': 'Aceite de Cutículas Frutales',
        'price': '15.000 COP',
        'description': 'Aceite hidratante enriquecido con vitamina E para uñas de gel y acrílicas.',
        'image_url': 'https://images.unsplash.com/photo-1607602132700-068258431c6c?q=80&w=200',
      };
    }
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item['image_url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (c, o, s) => Container(
                    color: const Color(0xFFF5EBE6),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 40),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TIENDA GLOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['price'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _handleProductBooking(item),
                      child: const Text(
                        'Comprar / Reservar',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProductBooking(Map<String, dynamic> product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text(
                  'Buscando profesional disponible...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final providers = await ApiService.fetchProvidersSecured();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (providers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay profesionales disponibles en este momento.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final provider = providers.first;
      final details = await ApiService.fetchProviderDetails(provider.id);
      if (!mounted) return;

      final services = List<Map<String, dynamic>>.from(details['services'] ?? []);
      if (services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.businessName} no tiene servicios activos.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreen(
            providerId: provider.id,
            providerName: provider.businessName,
            services: services,
            preselectedProductId: product['id']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con la agenda: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildGalleryCard(Map<String, dynamic> item) {
    if (item['is_product'] == true) {
      return _buildProductCard(item);
    }
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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
                  ),
                );
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
  }
}
