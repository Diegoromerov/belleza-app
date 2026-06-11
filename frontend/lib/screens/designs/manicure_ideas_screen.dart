// frontend/lib/screens/designs/manicure_ideas_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class ManicureIdeasScreen extends StatefulWidget {
  const ManicureIdeasScreen({super.key});

  @override
  State<ManicureIdeasScreen> createState() => _ManicureIdeasScreenState();
}

class _ManicureIdeasScreenState extends State<ManicureIdeasScreen> {
  // Filtros seleccionados
  String? _selectedColor;
  String? _selectedStyle;
  String? _selectedShape;

  final TextEditingController _customQueryController = TextEditingController();

  List<Map<String, dynamic>> _images = [];
  bool _isLoading = false;
  String? _error;

  // Rastrear límites de búsqueda por sesión
  int _searchCount = 0;
  int _totalImagesLoaded = 0;
  static const int maxSearches = 2;
  static const int maxImages = 12;

  // Opciones de filtros usuales en el mercado
  final List<String> _colors = ['Nude', 'Rojo', 'Negro', 'Blanco', 'Rosa Pastel', 'Gliter/Brillos'];
  final List<String> _styles = ['Francesa', 'Minimalista', 'Con Apliques', 'Mano Alzada', 'Efecto Espejo'];
  final List<String> _shapes = ['Almendra', 'Cuadrada', 'Ovalada', 'Stiletto', 'Coffin'];

  @override
  void dispose() {
    _customQueryController.dispose();
    super.dispose();
  }

  bool get _isLimitReached => _searchCount >= maxSearches || _totalImagesLoaded >= maxImages;

  Future<void> _searchDesigns() async {
    if (_isLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Límite de sesión alcanzado (máximo 2 búsquedas o 12 imágenes).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Construir la consulta
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
    });
  }

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
                image['title'] ?? 'Detalle del Diseño',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideas de Manicura', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearFilters,
            tooltip: 'Restaurar filtros',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Panel de Control de Límites
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
                      color: _searchCount >= maxSearches ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    'Imágenes cargadas: $_totalImagesLoaded / $maxImages',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _totalImagesLoaded >= maxImages ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            if (_isLimitReached)
              Container(
                width: double.infinity,
                color: Colors.redAccent.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Has alcanzado el límite máximo de 2 búsquedas de diseño en esta sesión.',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro de Color
                    const Text('Color de esmalte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            color: isSelected ? Colors.white : Colors.black87,
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

                    // Filtro de Estilo
                    const Text('Estilo / Decoración:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            color: isSelected ? Colors.white : Colors.black87,
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

                    // Filtro de Forma
                    const Text('Forma de uña:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            color: isSelected ? Colors.white : Colors.black87,
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

                    // Búsqueda Manual / Notas de consulta
                    TextField(
                      controller: _customQueryController,
                      decoration: const InputDecoration(
                        labelText: 'Detalle adicional (ej: flores 3D, mate...)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                      enabled: !_isLimitReached,
                    ),
                    const SizedBox(height: 20),

                    // Botón de Acción para Buscar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _isLoading || _isLimitReached ? null : _searchDesigns,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Buscar 6 Diseños Inspirados en Pinterest',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Resultados en Grid
                    if (_images.isNotEmpty) ...[
                      const Text(
                        'Diseños Encontrados (Toca para ampliar):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _images.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final item = _images[index];
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

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
  }
}
