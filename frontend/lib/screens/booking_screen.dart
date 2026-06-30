import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../shared/theme.dart';
import '../services/booking_recovery_service.dart';
import 'designs/manicure_ideas_screen.dart';

class BookingScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final List<Map<String, dynamic>> services;
  final String? initialNotes;
  final String? preselectedProductId;

  const BookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.services,
    this.initialNotes,
    this.preselectedProductId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool isLoading = false;
  DateTime? selectedDate;
  String? selectedServiceId;
  String serviceAddress = '';
  String notes = '';

  // slots variables
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  String? _selectedSlotTime;

  // products variables
  List<Map<String, dynamic>> _recommendedProducts = [];
  bool _isLoadingProducts = false;
  Map<String, int> _selectedProductsQty = {};

  // step navigation variables
  int _currentStep = 0;
  final PageController _pageController = PageController();
  DateTime _calendarMonth = DateTime.now();

  // text controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    notes = widget.initialNotes ?? '';
    try {
      final ref = ManicureIdeasScreen.selectedReference;
      if (ref != null && ref['image_url'] != null) {
        if (notes.isNotEmpty) {
          notes += '\n';
        }
        notes += 'Referencia visual: ${ref['image_url']} (${ref['title']})';
        // Clear it once consumed so it doesn't leak to future unrelated bookings
        ManicureIdeasScreen.selectedReference = null;
      }
    } catch (_) {}
    _notesController.text = notes;
    final now = DateTime.now();
    // Default to tomorrow
    selectedDate = DateTime(now.year, now.month, now.day + 1);
    _calendarMonth = selectedDate!;
    if (widget.services.isNotEmpty) {
      selectedServiceId = widget.services.first['id']?.toString();
    }
    _loadSlots();
    _loadRecommendedProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _mapServiceToTag(String category, String name) {
    final cat = category.toLowerCase();
    final nm = name.toLowerCase();

    if (nm.contains('ceja') || nm.contains('eyebrow') || cat.contains('eyebrow')) {
      return 'Maquillaje';
    }
    if (nm.contains('facial') || nm.contains('limpieza') || nm.contains('skin') || cat.contains('skin') || cat.contains('facial')) {
      return 'Estética';
    }
    if (cat.contains('nails') || cat.contains('uñas') || nm.contains('manicura') || nm.contains('pedicura') || nm.contains('nails')) {
      return 'Uñas';
    }
    if (cat.contains('hair') || cat.contains('cabello') || nm.contains('corte') || nm.contains('balayage') || nm.contains('peinado') || nm.contains('tinte')) {
      return 'Cabello';
    }

    return 'Uñas';
  }

  Future<void> _loadRecommendedProducts() async {
    if (selectedServiceId == null) return;
    final selectedService = widget.services.firstWhere(
      (s) => s['id']?.toString() == selectedServiceId,
      orElse: () => <String, dynamic>{},
    );
    if (selectedService.isEmpty) return;

    final name = selectedService['name']?.toString() ?? '';
    final category = selectedService['category']?.toString() ?? '';
    final tag = _mapServiceToTag(category, name);

    setState(() {
      _isLoadingProducts = true;
      _recommendedProducts = [];
      _selectedProductsQty = {};
    });

    try {
      final products = await ApiService.fetchProductsByTag(tag);
      setState(() {
        _recommendedProducts = products;
        _isLoadingProducts = false;
        if (widget.preselectedProductId != null) {
          final targetId = widget.preselectedProductId!;
          final hasProduct = products.any((p) => p['id']?.toString() == targetId);
          if (hasProduct) {
            _selectedProductsQty[targetId] = 1;
          } else {
            // Inject extra product info if not matching tag but explicitly requested
            Map<String, dynamic>? extraProduct;
            if (targetId == '1') {
              extraProduct = {
                'id': 1,
                'nombre': 'Kit Balayage Pro',
                'precio': 45000.00,
                'stock': 20,
                'imagen_url': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=200',
                'tag_especialidad': 'Cabello'
              };
            } else if (targetId == '2') {
              extraProduct = {
                'id': 2,
                'nombre': 'Aceite de Cutículas Frutales',
                'precio': 15000.00,
                'stock': 50,
                'imagen_url': 'https://images.unsplash.com/photo-1607602132700-068258431c6c?q=80&w=200',
                'tag_especialidad': 'Uñas'
              };
            } else if (targetId == '4') {
              extraProduct = {
                'id': 4,
                'nombre': 'Sérum Facial Ácido Hialurónico',
                'precio': 55000.00,
                'stock': 30,
                'imagen_url': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=200',
                'tag_especialidad': 'Estética'
              };
            } else if (targetId == '6') {
              extraProduct = {
                'id': 6,
                'nombre': 'Gel Moldeador de Cejas Orgánico',
                'precio': 18000.00,
                'stock': 40,
                'imagen_url': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=200',
                'tag_especialidad': 'Maquillaje'
              };
            }
            if (extraProduct != null) {
              _recommendedProducts.insert(0, extraProduct);
              _selectedProductsQty[targetId] = 1;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _loadSlots() async {
    if (selectedDate == null || selectedServiceId == null) {
      return;
    }
    setState(() {
      _isLoadingSlots = true;
      _slots = [];
      _selectedSlotTime = null;
    });

    try {
      final dateStr =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      final data = await ApiService.fetchAvailableSlots(
        providerId: widget.providerId,
        date: dateStr,
        serviceId: selectedServiceId!,
      );
      setState(() {
        _slots = data;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Error al cargar horarios: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (selectedServiceId == null || selectedServiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Selecciona un servicio'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (selectedDate == null || _selectedSlotTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Selecciona fecha y hora de la cuadrícula'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (serviceAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '⚠️ Ingresa la dirección donde llegará el prestador'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final timeParts = _selectedSlotTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final scheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    final List<Map<String, dynamic>> productosAdicionales = [];
    _selectedProductsQty.forEach((id, qty) {
      productosAdicionales.add({
        'id': int.parse(id),
        'cantidad': qty,
      });
    });

    setState(() => isLoading = true);
    try {
      final res = await ApiService.createBooking(
        providerId: widget.providerId,
        serviceId: selectedServiceId!,
        scheduledAt: scheduledDateTime.toIso8601String(),
        serviceAddress: serviceAddress.trim(),
        notes: notes.isNotEmpty ? notes : null,
        productosAdicionales: productosAdicionales.isNotEmpty ? productosAdicionales : null,
      );

      final bookingId = res['booking_id']?.toString();
      if (bookingId == null) {
        throw Exception('No se recibió el ID de la reserva');
      }

      final selectedService = widget.services.firstWhere(
        (s) => s['id']?.toString() == selectedServiceId,
        orElse: () => <String, dynamic>{},
      );
      final serviceName =
          selectedService['name']?.toString() ?? 'Servicio de Belleza';
      final servicePrice = _parseDouble(selectedService['price']);

      double productsSubtotal = 0.0;
      int totalProductsQty = 0;
      _selectedProductsQty.forEach((id, qty) {
        final prod = _recommendedProducts.firstWhere((p) => p['id'].toString() == id, orElse: () => <String, dynamic>{});
        if (prod.isNotEmpty) {
          final price = _parseDouble(prod['precio']);
          productsSubtotal += price * qty;
          totalProductsQty += qty;
        }
      });

      double discount = 0.0;
      if (totalProductsQty >= 2) {
        discount = productsSubtotal * 0.15;
      }

      double subtotal = servicePrice + productsSubtotal - discount;
      double tax = subtotal * 0.19;
      double totalBookingPrice = subtotal + tax;

      if (mounted) {
        setState(() => isLoading = false);
        BookingRecoveryService.savePendingBooking(
          bookingId: bookingId,
          serviceName: serviceName,
          price: totalBookingPrice,
          providerName: widget.providerName,
        );
        _showWompiCheckoutSheet(
          context: context,
          bookingId: bookingId,
          serviceName: serviceName,
          price: totalBookingPrice,
          providerName: widget.providerName,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reservar con ${widget.providerName}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: _prevStep,
              )
            : const BackButton(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)))
          : Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepLogistics(),
                      _buildStep2CrossSelling(),
                      _buildStep3SummaryAndPay(),
                    ],
                  ),
                ),
                _buildStickyBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: List.generate(3, (index) {
          bool isCompleted = index < _currentStep;
          bool isActive = index == _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 6,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? AppTheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepLogistics() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      children: [
        _buildSectionTitle('1. Selecciona un Servicio'),
        const SizedBox(height: 12),
        _buildServiceSelectionList(),
        const SizedBox(height: 24),
        _buildSectionTitle('2. Elige una Fecha (Calendario)'),
        const SizedBox(height: 12),
        _buildCalendarCard(),
        const SizedBox(height: 24),
        _buildSectionTitle('3. Horarios Disponibles'),
        const SizedBox(height: 12),
        _buildTimeSelector(),
        const SizedBox(height: 24),
        _buildSectionTitle('4. Dirección del servicio'),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: AppTheme.inputDecoration(
            hintText: 'Ej: Calle 24 # 95-32, Torre 2, Apto 402, Fontibón',
            labelText: 'Dirección del servicio',
            prefixIcon: Icons.location_on_outlined,
          ),
          onChanged: (value) {
            setState(() {
              serviceAddress = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildNotesExpandable(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final firstDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final startOffset = firstDayOfMonth.weekday - 1;
    final daysCount = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final totalCells = startOffset + daysCount;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFF3EAE8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                    });
                  },
                ),
                Text(
                  '${_getMonthNameLong(_calendarMonth.month)} ${_calendarMonth.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: weekdays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < startOffset) {
                  return const SizedBox.shrink();
                }
                final day = index - startOffset + 1;
                final cellDate = DateTime(_calendarMonth.year, _calendarMonth.month, day);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final isPast = cellDate.isBefore(today);
                final isSelected = selectedDate != null &&
                    selectedDate!.year == cellDate.year &&
                    selectedDate!.month == cellDate.month &&
                    selectedDate!.day == cellDate.day;

                return GestureDetector(
                  onTap: isPast ? null : () {
                    setState(() {
                      selectedDate = cellDate;
                      _selectedSlotTime = null;
                    });
                    _loadSlots();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: (cellDate.year == today.year && cellDate.month == today.month && cellDate.day == today.day)
                          ? Border.all(color: AppTheme.primary, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isPast
                                ? Colors.grey[300]
                                : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthNameLong(int month) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month];
  }

  Widget _buildTimeSelector() {
    if (selectedDate == null || selectedServiceId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Selecciona un servicio y fecha primero.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Color(0xFFC89D93)),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFFDC2626), size: 24),
            SizedBox(height: 8),
            Text(
              'No hay horarios disponibles para esta fecha o el prestador no está activo.',
              style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots.map((slot) {
        final String time = slot['time'] as String;
        final bool isAvailable = slot['is_available'] as bool? ?? false;
        final isSelected = _selectedSlotTime == time;
        return _buildTimeSlotButton(time, isAvailable, isSelected);
      }).toList(),
    );
  }

  Widget _buildTimeSlotButton(String time, bool isAvailable, bool isSelected) {
    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedSlotTime = time;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : isAvailable
                  ? const Color(0xFFF5EBE6).withValues(alpha: 0.4)
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : isAvailable
                    ? const Color(0xFFC89D93).withValues(alpha: 0.3)
                    : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_filled,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : isAvailable
                      ? AppTheme.primary
                      : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? Colors.black87
                        : Colors.grey[400],
                decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesExpandable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFF3EAE8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            'Notas adicionales (opcional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          leading: const Icon(Icons.note_alt_outlined, color: AppTheme.primary),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ej: Quisiera un corte con flequillo o tengo alergias...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => notes = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2CrossSelling() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFFE8A2B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.spa_outlined, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa tu experiencia',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Productos sugeridos para el cuidado posterior',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            border: Border.all(color: const Color(0xFFFDE68A)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.people_alt, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⭐ 87% de las clientas añaden estos productos para el cuidado posterior.',
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            border: Border.all(color: const Color(0xFFA7F3D0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_offer, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Oferta Especial! Lleva 2 o más productos y obtén 15% de descuento en tu kit.',
                  style: TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_recommendedProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No hay productos sugeridos para este servicio.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ..._recommendedProducts.map((prod) {
            final id = prod['id'].toString();
            final nombre = prod['nombre']?.toString() ?? 'Producto';
            final precio = _parseDouble(prod['precio']);
            final image = prod['imagen_url']?.toString() ?? '';
            final stock = int.tryParse(prod['stock']?.toString() ?? '0') ?? 0;
            final qty = _selectedProductsQty[id] ?? 0;
            final isSelected = qty > 0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF5EBE6).withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFF3EAE8),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF5EBE6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
                            )
                          : const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${precio.toStringAsFixed(0)} COP',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: stock <= 0
                        ? const Text('Agotado', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
                        : !isSelected
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5EBE6),
                                  foregroundColor: AppTheme.primary,
                                  elevation: 0,
                                  minimumSize: const Size(60, 28),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedProductsQty[id] = 1;
                                  });
                                },
                                child: const Text('Añadir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            : Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (qty > 1) {
                                          _selectedProductsQty[id] = qty - 1;
                                        } else {
                                          _selectedProductsQty.remove(id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.remove, size: 12, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      if (qty < stock) {
                                        setState(() {
                                          _selectedProductsQty[id] = qty + 1;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Solo hay $stock unidades disponibles')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, size: 12, color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep3SummaryAndPay() {
    final selectedService = widget.services.firstWhere(
      (s) => s['id']?.toString() == selectedServiceId,
      orElse: () => <String, dynamic>{},
    );
    final serviceName = selectedService['name']?.toString() ?? 'Servicio';
    final servicePrice = _parseDouble(selectedService['price']);

    double productsSubtotal = 0.0;
    int totalProductsQty = 0;
    _selectedProductsQty.forEach((id, qty) {
      final prod = _recommendedProducts.firstWhere((p) => p['id'].toString() == id, orElse: () => <String, dynamic>{});
      if (prod.isNotEmpty) {
        final price = _parseDouble(prod['precio']);
        productsSubtotal += price * qty;
        totalProductsQty += qty;
      }
    });

    double discount = 0.0;
    bool hasBundleDiscount = totalProductsQty >= 2;
    if (hasBundleDiscount) {
      discount = productsSubtotal * 0.15;
    }

    double subtotal = servicePrice + productsSubtotal - discount;
    double tax = subtotal * 0.19;
    double grandTotal = subtotal + tax;

    final formattedDate = selectedDate != null
        ? '${selectedDate!.day} ${_getMonthName(selectedDate!)}, ${selectedDate!.year}'
        : '';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      children: [
        const Text(
          'Revisa tu Reserva',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa los detalles logísticos y de pago para continuar',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFF3EAE8)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow(Icons.content_cut, 'Servicio', serviceName),
                const Divider(height: 24, color: Color(0xFFF3EAE8)),
                _buildSummaryRow(Icons.calendar_today, 'Fecha y hora', '$formattedDate a las $_selectedSlotTime'),
                const Divider(height: 24, color: Color(0xFFF3EAE8)),
                _buildSummaryRow(Icons.location_on, 'Dirección', serviceAddress),
                const Divider(height: 24, color: Color(0xFFF3EAE8)),
                _buildSummaryRow(Icons.person, 'Prestador', widget.providerName),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFFFDFBFB),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFF3EAE8)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPriceRow('Servicio Base', servicePrice),
                if (productsSubtotal > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Productos de Venta Cruzada', productsSubtotal),
                ],
                if (hasBundleDiscount) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Descuento Kit (15%)',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '-\$${discount.toStringAsFixed(0)} COP',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceRow('Impuestos (IVA 19%)', tax),
                const Divider(height: 24, color: Color(0xFFF3EAE8), thickness: 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a Pagar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      '\$${grandTotal.toStringAsFixed(0)} COP',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Pago seguro con Wompi • Verificación OTP',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SSL',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text('\$${value.toStringAsFixed(0)} COP', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.3),
      );

  Widget _buildServiceSelectionList() {
    if (widget.services.isEmpty) {
      return const Text('⚠️ No hay servicios disponibles',
          style: TextStyle(color: Colors.orange));
    }
    return Column(
      children: widget.services.map((service) {
        final price = _parseDouble(service['price']);
        final name = service['name']?.toString() ?? 'Sin nombre';
        final id = service['id']?.toString() ?? '';
        final description = service['description']?.toString() ?? '';
        final isSelected = selectedServiceId == id;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedServiceId = id;
            });
            _loadSlots();
            _loadRecommendedProducts();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF5EBE6) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC89D93)
                    : const Color(0xFFF3EAE8),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC89D93).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: const Color(0xFFC89D93),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${price.toStringAsFixed(0)} COP',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC89D93),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickyBottomButtons() {
    bool canNext = false;
    if (_currentStep == 0) {
      canNext = selectedServiceId != null &&
          selectedDate != null &&
          _selectedSlotTime != null &&
          serviceAddress.trim().isNotEmpty;
    } else if (_currentStep == 1) {
      canNext = true;
    } else if (_currentStep == 2) {
      canNext = true;
    }

    bool hasProducts = _selectedProductsQty.values.any((qty) => qty > 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF3EAE8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Color(0xFFC89D93)),
                ),
                onPressed: _prevStep,
                child: const Text('Atrás', style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 2 ? Colors.green.shade700 : AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: canNext ? _handleBottomButtonPress : null,
                child: Text(
                  _currentStep == 2
                      ? 'Confirmar y Pagar'
                      : _currentStep == 1
                          ? (hasProducts ? 'Continuar' : 'Omitir y Ver Resumen')
                          : 'Continuar',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomButtonPress() {
    if (_currentStep < 2) {
      _nextStep();
    } else {
      _confirmBooking();
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[date.month];
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// =========================================================================
// Pasarela de Pagos Wompi (Simulación de Checkout y Pago Seguro)
// =========================================================================

void _showWompiCheckoutSheet({
  required BuildContext context,
  required String bookingId,
  required String serviceName,
  required double price,
  required String providerName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WompiCheckoutWidget(
      bookingId: bookingId,
      serviceName: serviceName,
      price: price,
      providerName: providerName,
    ),
  );
}

class WompiCheckoutWidget extends StatefulWidget {
  final String bookingId;
  final String serviceName;
  final double price;
  final String providerName;

  const WompiCheckoutWidget({super.key, 
    required this.bookingId,
    required this.serviceName,
    required this.price,
    required this.providerName,
  });

  @override
  State<WompiCheckoutWidget> createState() => _WompiCheckoutWidgetState();
}

class _WompiCheckoutWidgetState extends State<WompiCheckoutWidget> {
  int _selectedTab = 0; // 0: Nequi, 1: Card
  final _nequiCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  Map<String, dynamic>? _successData;
  String? _errorMsg;

  @override
  void dispose() {
    _nequiCtrl.dispose();
    _cardCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      final method = _selectedTab == 0 ? 'NEQUI' : 'CARD';
      final res = await ApiService.payBooking(widget.bookingId, method);

      // Clear pending booking recovery since payment succeeded
      await BookingRecoveryService.clearPendingBooking();

      // Respuesta táctil háptica en caso de éxito
      await HapticFeedback.lightImpact();

      setState(() {
        _isProcessing = false;
        _successData = res;
      });
    } catch (e) {
      // Respuesta táctil háptica en caso de error
      await HapticFeedback.vibrate();
      setState(() {
        _isProcessing = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C288D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'wompi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5C288D),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF12A7B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_successData != null)
              _buildSuccessView()
            else
              _buildPaymentForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final ref = _successData!['reference'] ?? 'N/A';
    final amount = _successData!['amount'] ?? widget.price;
    final method = _successData!['payment_method'] ??
        (_selectedTab == 0 ? 'NEQUI' : 'CARD');

    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 72),
        const SizedBox(height: 16),
        const Text(
          '¡Pago Exitoso!',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu cita con ${widget.providerName} ha sido confirmada.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5DEEB)),
          ),
          child: Column(
            children: [
              _buildReceiptRow('Servicio', widget.serviceName),
              const SizedBox(height: 8),
              _buildReceiptRow(
                  'Valor Pagado', '\$${amount.toStringAsFixed(0)} COP'),
              const SizedBox(height: 8),
              _buildReceiptRow('Medio de Pago', method),
              const SizedBox(height: 8),
              _buildReceiptRow('Ref. Wompi', ref),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C288D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context); // Cerrar bottom sheet
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/client-bookings',
                (route) => route.settings.name == '/home',
              );
            },
            child: const Text('Listo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prestador: ${widget.providerName}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.price.toStringAsFixed(0)} COP',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF5C288D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDFA),
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => setState(() => _selectedTab = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: _selectedTab == 0
                            ? const [
                                BoxShadow(
                                    color: Color(0x1F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Nequi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _selectedTab == 0
                              ? const Color(0xFF5C288D)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => setState(() => _selectedTab = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: _selectedTab == 1
                            ? const [
                                BoxShadow(
                                    color: Color(0x1F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Tarjeta de Crédito',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _selectedTab == 1
                              ? const Color(0xFF5C288D)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedTab == 0) _buildNequiForm() else _buildCardForm(),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Text(
              '❌ $_errorMsg',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C288D),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFBCABC7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            onPressed: _isProcessing ? null : _handlePayment,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Pagar de forma segura',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 12, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Transacción protegida por Wompi Colombia',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNequiForm() {
    return TextFormField(
      controller: _nequiCtrl,
      keyboardType: TextInputType.phone,
      enabled: !_isProcessing,
      style: const TextStyle(fontSize: 14),
      decoration:
          _inputDecoration('Número de celular (Nequi)', Icons.phone_android),
      validator: (val) {
        if (val == null || val.isEmpty) return 'El número es requerido';
        if (val.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
          return 'Debe ser un número celular de 10 dígitos';
        }
        return null;
      },
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardCtrl,
          keyboardType: TextInputType.number,
          enabled: !_isProcessing,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDecoration('Número de Tarjeta', Icons.credit_card),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'El número de tarjeta es requerido';
            }
            if (val.length != 16 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
              return 'Debe tener 16 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expCtrl,
                keyboardType: TextInputType.datetime,
                enabled: !_isProcessing,
                style: const TextStyle(fontSize: 14),
                decoration:
                    _inputDecoration('Exp (MM/AA)', Icons.calendar_month),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(val)) {
                    return 'Formato MM/AA';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                enabled: !_isProcessing,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration('CVV', Icons.lock_outline),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (val.length != 3 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                    return '3 dígitos';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _holderCtrl,
          keyboardType: TextInputType.name,
          enabled: !_isProcessing,
          style: const TextStyle(fontSize: 14),
          decoration:
              _inputDecoration('Titular de la tarjeta', Icons.person_outline),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'El nombre del titular es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF5C288D)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: const Color(0xFFF9F7FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF5C288D), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
