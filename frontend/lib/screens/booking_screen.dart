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
    final now = DateTime.now();
    // Default to tomorrow
    selectedDate = DateTime(now.year, now.month, now.day + 1);
    if (widget.services.isNotEmpty) {
      selectedServiceId = widget.services.first['id']?.toString();
    }
    _loadSlots();
    _loadRecommendedProducts();
  }

  String _mapServiceToTag(String category, String name) {
    final cat = category.toLowerCase();
    final nm = name.toLowerCase();

    if (nm.contains('ceja') || nm.contains('eyebrow') || cat.contains('eyebrow')) {
      return 'eyebrow-visagism';
    }
    if (nm.contains('facial') || nm.contains('limpieza') || nm.contains('skin') || cat.contains('skin') || cat.contains('facial')) {
      return 'skin-texture';
    }
    if (cat.contains('nails') || cat.contains('uñas') || nm.contains('manicura') || nm.contains('pedicura') || nm.contains('nails')) {
      return 'nails-classic';
    }
    if (cat.contains('hair') || cat.contains('cabello') || nm.contains('corte') || nm.contains('balayage') || nm.contains('peinado') || nm.contains('tinte')) {
      return 'hair-diagnostic';
    }

    return 'nails-classic';
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
                'tag_especialidad': 'hair-diagnostic'
              };
            } else if (targetId == '2') {
              extraProduct = {
                'id': 2,
                'nombre': 'Aceite de Cutículas Frutales',
                'precio': 15000.00,
                'stock': 50,
                'imagen_url': 'https://images.unsplash.com/photo-1607602132700-068258431c6c?q=80&w=200',
                'tag_especialidad': 'nails-classic'
              };
            } else if (targetId == '4') {
              extraProduct = {
                'id': 4,
                'nombre': 'Sérum Facial Ácido Hialurónico',
                'precio': 55000.00,
                'stock': 30,
                'imagen_url': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?q=80&w=200',
                'tag_especialidad': 'skin-texture'
              };
            } else if (targetId == '6') {
              extraProduct = {
                'id': 6,
                'nombre': 'Gel Moldeador de Cejas Orgánico',
                'precio': 18000.00,
                'stock': 40,
                'imagen_url': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=200',
                'tag_especialidad': 'eyebrow-visagism'
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

      double totalBookingPrice = servicePrice;
      for (final pId in _selectedProductsQty.keys) {
        final prod = _recommendedProducts.firstWhere((p) => p['id'].toString() == pId, orElse: () => <String, dynamic>{});
        if (prod.isNotEmpty) {
          final prodPrice = _parseDouble(prod['precio']);
          final qty = _selectedProductsQty[pId] ?? 0;
          totalBookingPrice += prodPrice * qty;
        }
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reservar con ${widget.providerName}',
          style: TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFFC89D93)))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('1. Selecciona un Servicio'),
                  SizedBox(height: 12),
                  _buildServiceSelectionList(),
                  SizedBox(height: 24),
                  _buildSectionTitle('2. Elige una Fecha'),
                  SizedBox(height: 12),
                  _buildDateSelector(),
                  SizedBox(height: 24),
                  _buildSectionTitle('3. Horarios Disponibles'),
                  SizedBox(height: 12),
                  _buildTimeSelector(),
                  SizedBox(height: 24),
                  _buildSectionTitle('4. Dirección del servicio'),
                  SizedBox(height: 12),
                  _buildAddressField(),
                  SizedBox(height: 24),
                  _buildSectionTitle('5. Notas adicionales (opcional)'),
                  SizedBox(height: 12),
                  _buildNotesField(),
                  SizedBox(height: 24),
                  _buildSectionTitle('6. Añadir productos a domicilio (Consignación Local)'),
                  SizedBox(height: 12),
                  _buildProductsSelector(),
                  SizedBox(height: 36),
                  _buildConfirmButton(),
                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProductsSelector() {
    if (_isLoadingProducts) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    if (_recommendedProducts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay productos sugeridos para este servicio.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recommendedProducts.length,
        itemBuilder: (context, index) {
          final prod = _recommendedProducts[index];
          final id = prod['id'].toString();
          final nombre = prod['nombre']?.toString() ?? 'Producto';
          final precio = _parseDouble(prod['precio']);
          final image = prod['imagen_url']?.toString() ?? '';
          final stock = int.tryParse(prod['stock']?.toString() ?? '0') ?? 0;
          final qty = _selectedProductsQty[id] ?? 0;

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: qty > 0 ? AppTheme.primary :  Color(0xFFF3EAE8),
                width: qty > 0 ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image.isNotEmpty)
                          Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(
                              color: const Color(0xFFF5EBE6),
                              child: Icon(Icons.shopping_bag_outlined,
                                  color: AppTheme.primary),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFFF5EBE6),
                            child: Icon(Icons.shopping_bag_outlined,
                                color: AppTheme.primary),
                          ),
                        if (qty > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '\$${precio.toStringAsFixed(0)} COP',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary),
                        ),
                        SizedBox(height: 6),
                        if (stock <= 0)
                          Text(
                            'Agotado',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          )
                        else if (qty == 0)
                          SizedBox(
                            width: double.infinity,
                            height: 24,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5EBE6),
                                foregroundColor: AppTheme.primary,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedProductsQty[id] = 1;
                                });
                              },
                              child: Text('Agregar',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.remove,
                                      size: 14, color: Colors.black87),
                                ),
                              ),
                              Text('$qty',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () {
                                  if (qty < stock) {
                                    setState(() {
                                      _selectedProductsQty[id] = qty + 1;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Solo hay $stock unidades disponibles')),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add,
                                      size: 14, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.3),
      );

  Widget _buildServiceSelectionList() {
    if (widget.services.isEmpty) {
      return Text('⚠️ No hay servicios disponibles',
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
            padding: const EdgeInsets.all(16),
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
                        color: const Color(0xFFC89D93).withOpacity(0.15),
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
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '\$${price.toStringAsFixed(0)} COP',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC89D93),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days[date.weekday % 7];
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

  Widget _buildDateSelector() {
    final List<DateTime> next7Days = List.generate(7, (index) {
      final date = DateTime.now().add(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    });

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: next7Days.length,
        itemBuilder: (context, index) {
          final date = next7Days[index];
          final isSelected = selectedDate != null &&
              selectedDate!.year == date.year &&
              selectedDate!.month == date.month &&
              selectedDate!.day == date.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
              });
              _loadSlots();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 75,
              margin: const EdgeInsets.only(right: 10, bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _getMonthName(date),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    if (selectedDate == null || selectedServiceId == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Selecciona un servicio y fecha primero.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    if (_isLoadingSlots) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFFDC2626), size: 30),
            SizedBox(height: 8),
            Text(
              'No hay horarios disponibles para esta fecha o el prestador no está activo.',
              style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final String time = slot['time'] as String;
        final bool isAvailable = slot['is_available'] as bool? ?? false;
        final isSelected = _selectedSlotTime == time;

        return InkWell(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedSlotTime = time;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : isAvailable
                      ? AppTheme.accent.withOpacity(0.2)
                      : const Color(0xFFF3F4F6),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : isAvailable
                        ? AppTheme.accent.withOpacity(0.4)
                        : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                SizedBox(width: 6),
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
                    decoration: isAvailable
                        ? TextDecoration.none
                        : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesField() => TextField(
        maxLines: 3,
        style: TextStyle(fontSize: 14),
        decoration: AppTheme.inputDecoration(
          hintText: 'Ej: Quisiera un corte con flequillo...',
          labelText: 'Notas adicionales (opcional)',
          prefixIcon: Icons.note_alt_outlined,
        ),
        onChanged: (value) => notes = value,
      );

  Widget _buildAddressField() => TextField(
        maxLines: 2,
        style: TextStyle(fontSize: 14),
        decoration: AppTheme.inputDecoration(
          hintText: 'Ej: Calle 24 # 95-32, Torre 2, Apto 402, Fontibón',
          labelText: 'Dirección del servicio',
          prefixIcon: Icons.location_on_outlined,
        ),
        onChanged: (value) => serviceAddress = value,
      );

  Widget _buildConfirmButton() => ElevatedButton(
        onPressed:
            isLoading || _selectedSlotTime == null ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.accent.withOpacity(0.5),
          padding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confirmar Reserva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      );

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

  const WompiCheckoutWidget({
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
        decoration: BoxDecoration(
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
            SizedBox(height: 16),
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
                    SizedBox(width: 8),
                    Text(
                      'wompi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5C288D),
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xFFF12A7B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
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
        SizedBox(height: 16),
        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 72),
        SizedBox(height: 16),
        Text(
          '¡Pago Exitoso!',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        SizedBox(height: 8),
        Text(
          'Tu cita con ${widget.providerName} ha sido confirmada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        SizedBox(height: 24),
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
              SizedBox(height: 8),
              _buildReceiptRow(
                  'Valor Pagado', '\$${amount.toStringAsFixed(0)} COP'),
              SizedBox(height: 8),
              _buildReceiptRow('Medio de Pago', method),
              SizedBox(height: 8),
              _buildReceiptRow('Ref. Wompi', ref),
            ],
          ),
        ),
        SizedBox(height: 32),
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
            child: Text('Listo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        SizedBox(height: 16),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Prestador: ${widget.providerName}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.price.toStringAsFixed(0)} COP',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF5C288D)),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
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
          SizedBox(height: 20),
          if (_selectedTab == 0) _buildNequiForm() else _buildCardForm(),
          if (_errorMsg != null) ...[
            SizedBox(height: 16),
            Text(
              '❌ $_errorMsg',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
          SizedBox(height: 24),
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
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
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
          SizedBox(height: 8),
          Row(
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
      style: TextStyle(fontSize: 14),
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
          style: TextStyle(fontSize: 14),
          decoration: _inputDecoration('Número de Tarjeta', Icons.credit_card),
          validator: (val) {
            if (val == null || val.isEmpty)
              return 'El número de tarjeta es requerido';
            if (val.length != 16 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
              return 'Debe tener 16 dígitos';
            }
            return null;
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expCtrl,
                keyboardType: TextInputType.datetime,
                enabled: !_isProcessing,
                style: TextStyle(fontSize: 14),
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
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                enabled: !_isProcessing,
                style: TextStyle(fontSize: 14),
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
        SizedBox(height: 12),
        TextFormField(
          controller: _holderCtrl,
          keyboardType: TextInputType.name,
          enabled: !_isProcessing,
          style: TextStyle(fontSize: 14),
          decoration:
              _inputDecoration('Titular de la tarjeta', Icons.person_outline),
          validator: (val) {
            if (val == null || val.isEmpty)
              return 'El nombre del titular es requerido';
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
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
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
        borderSide: BorderSide(color: Color(0xFF5C288D), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
