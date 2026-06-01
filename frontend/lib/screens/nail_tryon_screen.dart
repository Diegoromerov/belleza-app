import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'booking_screen.dart';

class NailTryonScreen extends StatefulWidget {
  const NailTryonScreen({super.key});

  @override
  State<NailTryonScreen> createState() => _NailTryonScreenState();
}

class _NailTryonScreenState extends State<NailTryonScreen> {
  // Parámetros de estilo seleccionados
  String _selectedColorHex = '#C82C40'; // Rojo clásico por defecto
  String _selectedShape = 'almond';
  String _selectedFinish = 'glossy';
  String _selectedDecoration = 'solid';

  // Estados de Imagen
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String? _originalImageUrl;
  String? _previewImageUrl;

  // Estados de Proceso
  bool _isUploading = false;
  bool _isProcessing = false;
  String _statusMessage = 'Preparando imagen...';
  String? _jobId;
  String? _userId;
  String? _errorMessage;

  // WebSocket y Polling
  WebSocketChannel? _wsChannel;
  Timer? _pollingTimer;

  // Comparación antes/después
  bool _showOriginal = false;

  // Paleta de colores premium sugerida
  final List<Map<String, String>> _colorPalette = [
    {'name': 'Rojo Carmín', 'hex': '#C82C40'},
    {'name': 'Rosa Nude', 'hex': '#E6C2B9'},
    {'name': 'Cereza Oscuro', 'hex': '#5D1224'},
    {'name': 'Lavanda', 'hex': '#B0A8D9'},
    {'name': 'Verde Esmeralda', 'hex': '#1E5E4E'},
    {'name': 'Coral Brillante', 'hex': '#FF6B57'},
    {'name': 'Blanco Francés', 'hex': '#FFFFFF'},
    {'name': 'Nude Café', 'hex': '#8D6E63'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  @override
  void dispose() {
    _closeWebSocket();
    _stopPolling();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      if (_userId == null) {
        // Fallback: cargar del perfil
        final profile = await ApiService.fetchUserProfile();
        _userId = profile['id']?.toString();
      }
    } catch (_) {}
  }

  // Gestión de WebSockets
  void _connectWebSocket() {
    if (_wsChannel != null || _userId == null) return;
    try {
      final wsUrl = ApiService.baseUrl.replaceAll('http://', 'ws://');
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Registrar cliente
      _wsChannel!.sink
          .add(json.encode({'type': 'register', 'userId': _userId}));

      _wsChannel!.stream.listen((message) {
        final data = json.decode(message);
        if (data['type'] == 'nail_tryon_update' && data['data'] != null) {
          final job = data['data'];
          if (job['id'] == _jobId) {
            _handleJobUpdate(job);
          }
        }
      }, onError: (err) {
        print('🔌 WebSocket Error: $err. Activando fallback de polling.');
        _startPolling();
      }, onDone: () {
        print('🔌 WebSocket cerrado. Activando fallback de polling.');
        _startPolling();
      });
    } catch (e) {
      print('🔌 Error conectando WebSocket: $e. Activando fallback.');
      _startPolling();
    }
  }

  void _closeWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  // Fallback de Polling
  void _startPolling() {
    _stopPolling();
    if (_jobId == null) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isProcessing || _jobId == null) {
        timer.cancel();
        return;
      }
      try {
        final res = await ApiService.getNailTryonJobStatus(_jobId!);
        if (res['success'] == true && res['job'] != null) {
          _handleJobUpdate(res['job']);
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _handleJobUpdate(Map<String, dynamic> job) {
    final status = job['status'];
    final previewUrl = job['preview_url'];
    final errorMsg = job['error_message'];

    setState(() {
      if (status == 'completed') {
        _isProcessing = false;
        _previewImageUrl = previewUrl;
        _errorMessage = null;
        _closeWebSocket();
        _stopPolling();
      } else if (status == 'failed') {
        _isProcessing = false;
        _errorMessage =
            errorMsg ?? 'Error desconocido al procesar en IA Worker.';
        _closeWebSocket();
        _stopPolling();
      } else {
        // Encolado o procesando
        _statusMessage = status == 'pending'
            ? 'En cola de espera de IA (Redis)...'
            : 'Mapeando contornos y pintando uñas...';
      }
    });
  }

  // Selección de Imagen
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImage = file;
        _imageBytes = bytes;
        _previewImageUrl = null;
        _originalImageUrl = null;
        _jobId = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo seleccionar la imagen: $e';
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      )),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Seleccione origen de la foto',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tomar Foto con Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC89D93),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Elegir de Galería'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC89D93),
                    side: const BorderSide(color: Color(0xFFC89D93)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enviar a procesar
  Future<void> _processImage() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = 'Subiendo imagen al servidor...';
    });

    try {
      final res = await ApiService.submitNailTryon(
        imageBytes: _imageBytes!,
        filename: _selectedImage!.name,
        colorHex: _selectedColorHex,
        shape: _selectedShape,
        finish: _selectedFinish,
        decorationStyle: _selectedDecoration,
      );

      if (res['success'] == true && res['job'] != null) {
        final job = res['job'];
        _jobId = job['id']?.toString();

        setState(() {
          _isUploading = false;
          _statusMessage = 'Encolando en cola de procesamiento...';
        });

        // Conectar WebSocket y habilitar Polling de respaldo
        _connectWebSocket();
        _startPolling();
      } else {
        throw Exception('El servidor no retornó un ID de trabajo válido.');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isProcessing = false;
        _errorMessage = 'Error al enviar diseño a procesar: $e';
      });
    }
  }

  // Flujo de Reserva Integrado
  Future<void> _bookAppointment() async {
    if (_previewImageUrl == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Cargar proveedores y buscar los que hagan uñas
      final allProviders = await ApiService.fetchProvidersSecured();
      final nailProviders = allProviders.where((p) {
        final desc = p.description.toLowerCase();
        final biz = p.businessName.toLowerCase();
        return desc.contains('nail') ||
            desc.contains('uña') ||
            desc.contains('manicur') ||
            biz.contains('nail') ||
            biz.contains('manicur');
      }).toList();

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      if (nailProviders.isEmpty) {
        _showNoProvidersDialog();
        return;
      }

      // 2. Mostrar selector de salones / manicuristas recomendadas en Fontibón
      _showProviderSelectionSheet(nailProviders);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al preparar reserva: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNoProvidersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reservar Cita',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Actualmente no hay salones de manicura aprobados cerca en la localidad de Fontibón. '
          'Su diseño virtual ha sido guardado. Inténtelo más tarde para agendar con un profesional.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido',
                style: TextStyle(
                    color: Color(0xFFC89D93), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showProviderSelectionSheet(List<dynamic> providers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seleccione un Profesional de Uñas',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hemos filtrado salones en Fontibón para agendar su diseño virtual',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xFFF5EBE6).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE8D7D3),
                          backgroundImage: provider.avatarUrl.isNotEmpty
                              ? NetworkImage(provider.avatarUrl)
                              : null,
                          child: provider.avatarUrl.isEmpty
                              ? Text(provider.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFFC89D93),
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(
                          provider.businessName.isNotEmpty
                              ? provider.businessName
                              : provider.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFC89D93), size: 14),
                            const SizedBox(width: 4),
                            Text(
                                '${provider.ratingAvg.toStringAsFixed(1)} (${provider.ratingCount})',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on,
                                color: Colors.grey, size: 14),
                            const SizedBox(width: 2),
                            Text(
                                '${(provider.distanceMeters / 1000).toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Color(0xFFC89D93)),
                        onTap: () async {
                          Navigator.pop(context); // Cerrar bottom sheet
                          _navigateToBookingScreen(
                              provider.id,
                              provider.businessName.isNotEmpty
                                  ? provider.businessName
                                  : provider.fullName);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToBookingScreen(
      String providerId, String providerName) async {
    setState(() {
      _isUploading = true;
    });
    try {
      // Cargar detalles del proveedor para obtener sus servicios
      final details = await ApiService.fetchProviderDetails(providerId);
      final List<dynamic> rawServices = details['services'] ?? [];

      // Filtrar servicios de uñas
      final List<Map<String, dynamic>> services =
          rawServices.map((s) => Map<String, dynamic>.from(s)).where((s) {
        final name = s['name'].toString().toLowerCase();
        return name.contains('uña') ||
            name.contains('nail') ||
            name.contains('manicur') ||
            name.contains('esmalte');
      }).toList();

      final List<Map<String, dynamic>> finalServices = services.isNotEmpty
          ? services
          : rawServices.map((s) => Map<String, dynamic>.from(s)).toList();

      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;

      // Traducir parámetros para la nota de reserva
      final shapeEs = _selectedShape == 'almond'
          ? 'Almendra'
          : (_selectedShape == 'square'
              ? 'Cuadrada'
              : (_selectedShape == 'coffin' ? 'Ataúd' : 'Stiletto'));
      final finishEs = _selectedFinish == 'glossy'
          ? 'Brillante'
          : (_selectedFinish == 'matte'
              ? 'Mate'
              : (_selectedFinish == 'chrome' ? 'Cromado' : 'Escarchado'));
      final decorEs = _selectedDecoration == 'solid'
          ? 'Liso/Sólido'
          : (_selectedDecoration == 'french'
              ? 'Francesa'
              : 'Degradado (Ombré)');

      final String notes = '💅 DISEÑO VIRTUAL DE UÑAS SELECCIONADO (IA):\n'
          '- Color: $_selectedColorHex\n'
          '- Forma: $shapeEs\n'
          '- Acabado: $finishEs\n'
          '- Decoración: $decorEs\n'
          '- Vista Previa: $_previewImageUrl';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            providerId: providerId,
            providerName: providerName,
            services: finalServices,
            initialNotes: notes,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error cargando servicios del profesional: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageBytes != null;
    final hasResult = _previewImageUrl != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Prueba de Uñas Virtual',
          style: TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ÁREA DE VISUALIZACIÓN DE IMAGEN
              Expanded(
                flex: 4,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EBE6).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: const Color(0xFFE8D7D3).withOpacity(0.8),
                        width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      // Mostrar imagen según estado (original, resultado con toggle o placeholder)
                      if (!hasImage)
                        _buildPlaceholder()
                      else if (hasResult)
                        Image.network(
                          _showOriginal
                              ? _selectedImage!.path
                              : _previewImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            // En web o entornos locales a veces la URL de red falla por CORS, usamos fallback local de bytes si falla
                            return Image.memory(_imageBytes!,
                                fit: BoxFit.cover);
                          },
                        )
                      else
                        Image.memory(_imageBytes!, fit: BoxFit.cover),

                      // Filtro oscuro de procesamiento
                      if (_isProcessing)
                        Container(
                          color: Colors.black45,
                          child: Center(
                            child: Card(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                        color: Color(0xFFC89D93)),
                                    const SizedBox(height: 16),
                                    Text(
                                      _statusMessage,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tiempo estimado: 5-8 segundos',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Botón Comparativo Antes/Después
                      if (hasResult && !_isProcessing)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _showOriginal = true),
                            onTapUp: (_) =>
                                setState(() => _showOriginal = false),
                            onTapCancel: () =>
                                setState(() => _showOriginal = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.compare_arrows,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _showOriginal
                                        ? 'Viendo Original'
                                        : 'Mantener para comparar',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. PANEL DE DISEÑO ESTÉTICO
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, -6))
                      ]),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COLOR SELECTOR
                        const Text(
                          '1. Color del Esmalte',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _colorPalette.length,
                            itemBuilder: (context, index) {
                              final item = _colorPalette[index];
                              final hexStr = item['hex']!;
                              final color = Color(
                                  int.parse(hexStr.replaceFirst('#', '0xFF')));
                              final isSelected = _selectedColorHex == hexStr;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColorHex = hexStr;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                      border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFC89D93)
                                              : Colors.grey[300]!,
                                          width: isSelected ? 3 : 1),
                                      boxShadow: isSelected
                                          ? const [
                                              BoxShadow(
                                                  color: Color(0x33C89D93),
                                                  blurRadius: 8,
                                                  spreadRadius: 2)
                                            ]
                                          : null),
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          color: hexStr == '#FFFFFF'
                                              ? Colors.black
                                              : Colors.white,
                                          size: 18)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // SHAPE SELECTOR
                        const Text(
                          '2. Forma de la Uña',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildShapeChip('Almendra', 'almond'),
                            _buildShapeChip('Ataúd', 'coffin'),
                            _buildShapeChip('Cuadrada', 'square'),
                            _buildShapeChip('Stiletto', 'stiletto'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // FINISH SELECTOR
                        const Text(
                          '3. Acabado',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFinishChip('Brillante', 'glossy'),
                            _buildFinishChip('Mate', 'matte'),
                            _buildFinishChip('Metalizado', 'chrome'),
                            _buildFinishChip('Escarchado', 'glitter'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // DECORATION SELECTOR
                        const Text(
                          '4. Decoración / Estilo',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildDecorationChip('Sólido / Liso', 'solid'),
                            _buildDecorationChip('Francesa', 'french'),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Error message
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ACCIONES PRINCIPALES
                        if (!hasResult && !_isProcessing)
                          ElevatedButton.icon(
                            onPressed: hasImage
                                ? _processImage
                                : _showImageSourcePicker,
                            icon: Icon(hasImage
                                ? Icons.auto_awesome
                                : Icons.camera_alt_outlined),
                            label: Text(hasImage
                                ? 'Aplicar Esmalte con IA'
                                : 'Subir Foto para Comenzar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC89D93),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                          )
                        else if (_isProcessing)
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFFC89D93)),
                            ),
                            label: const Text('Procesando Estilo...'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28)),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _previewImageUrl = null;
                                      _jobId = null;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC89D93),
                                    side: const BorderSide(
                                        color: Color(0xFFC89D93)),
                                    minimumSize: const Size(0, 54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28)),
                                  ),
                                  child: const Text('Reiniciar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _bookAppointment,
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('Reservar Cita',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC89D93),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),

          // Pantalla de carga opaca (reserva/proveedores)
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFC89D93)),
              ),
            ),
        ],
      ),
    );
  }

  // Elementos Auxiliares de Interfaz
  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined,
            size: 56, color: const Color(0xFFC89D93).withOpacity(0.7)),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Prueba de Uñas en Tiempo Real',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'Tome una foto de su mano sobre fondo plano y descubra cómo lucen los colores y formas.',
            style:
                TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showImageSourcePicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC89D93),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Tomar Foto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildShapeChip(String label, String shapeVal) {
    final isSelected = _selectedShape == shapeVal;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 11.5)),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedShape = shapeVal;
            });
          },
          selectedColor: const Color(0xFFC89D93),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
              color: isSelected ? Colors.transparent : const Color(0xFFE8D7D3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildFinishChip(String label, String finishVal) {
    final isSelected = _selectedFinish == finishVal;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 11.5)),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedFinish = finishVal;
            });
          },
          selectedColor: const Color(0xFFC89D93),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
              color: isSelected ? Colors.transparent : const Color(0xFFE8D7D3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildDecorationChip(String label, String decorVal) {
    final isSelected = _selectedDecoration == decorVal;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedDecoration = decorVal;
          });
        },
        selectedColor: const Color(0xFFC89D93),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFE8D7D3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
