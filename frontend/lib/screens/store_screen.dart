// frontend/lib/screens/store_screen.dart
import 'package:flutter/material.dart';
import '../shared/theme.dart';
import '../services/api_service.dart';

class StoreScreen extends StatefulWidget {
  final String? bookingId;
  const StoreScreen({super.key, this.bookingId});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filtros
  String _selectedCategory = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  // Carrito de compras: { productId: { 'product': product, 'quantity': q } }
  final Map<int, Map<String, dynamic>> _cart = {};
  bool _isCartOpen = false;

  final List<String> _categories = ['Todos', 'Cabello', 'Uñas', 'Maquillaje', 'Estética'];

  double _getProductPrice(Map<String, dynamic> product) {
    if (widget.bookingId != null && product.containsKey('precio_con_reserva')) {
      return double.tryParse(product['precio_con_reserva']?.toString() ?? '0') ?? 0.0;
    }
    return double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final response = await ApiService.get('/api/products');
      if (response != null && response['success'] == true) {
        final List<dynamic> productsData = response['data'] ?? [];
        setState(() {
          _allProducts = List<Map<String, dynamic>>.from(productsData);
          _filteredProducts = _allProducts;
          _isLoading = false;
        });
      } else {
        throw Exception('Respuesta no válida del servidor');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar los productos: $e';
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCat = _selectedCategory == 'Todos' || 
            (p['tag_especialidad']?.toString().toLowerCase() == _selectedCategory.toLowerCase());
        
        final matchesQuery = query.isEmpty ||
            (p['nombre']?.toString().toLowerCase().contains(query) ?? false) ||
            (p['descripcion']?.toString().toLowerCase().contains(query) ?? false);

        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
    });
    _filterProducts();
  }

  void _addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final id = product['id'] as int;
    final stock = product['stock'] as int? ?? 0;
    
    setState(() {
      if (_cart.containsKey(id)) {
        final currentQty = _cart[id]!['quantity'] as int;
        if (currentQty + quantity <= stock) {
          _cart[id]!['quantity'] = currentQty + quantity;
        } else {
          _cart[id]!['quantity'] = stock;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alcanzaste el límite de stock disponible.')),
          );
        }
      } else {
        _cart[id] = {
          'product': product,
          'quantity': quantity > stock ? stock : quantity,
        };
      }
      _isCartOpen = true; // Abrir automáticamente el Cart Drawer
    });
  }

  void _updateCartQuantity(int id, int newQty) {
    if (newQty <= 0) {
      setState(() {
        _cart.remove(id);
      });
      return;
    }
    final product = _cart[id]!['product'] as Map<String, dynamic>;
    final stock = product['stock'] as int? ?? 0;

    setState(() {
      _cart[id]!['quantity'] = newQty > stock ? stock : newQty;
    });
  }

  double _getCartSubtotal() {
    double subtotal = 0.0;
    _cart.forEach((_, item) {
      final product = item['product'] as Map<String, dynamic>;
      final qty = item['quantity'] as int;
      final price = _getProductPrice(product);
      subtotal += price * qty;
    });
    return subtotal;
  }

  int _getCartItemCount() {
    int count = 0;
    _cart.forEach((_, item) {
      count += item['quantity'] as int;
    });
    return count;
  }

  String _formatCOP(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} COP';
  }

  void _showQuickView(Map<String, dynamic> product) {
    int qty = 1;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final price = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
            final stock = product['stock'] as int? ?? 0;
            final imageUrl = product['imagen_url']?.toString() ?? '';

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              backgroundColor: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado con imagen
                      Stack(
                        children: [
                          imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(250),
                                )
                              : _buildPlaceholderImage(250),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.text),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product['tag_especialidad']?.toString() ?? 'Especialidad',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product['nombre']?.toString() ?? 'Producto sin Nombre',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                if (widget.bookingId != null && product.containsKey('precio_con_reserva')) {
                                  final originalPrice = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
                                  final discountPrice = double.tryParse(product['precio_con_reserva']?.toString() ?? '0') ?? 0.0;
                                  return Row(
                                    children: [
                                      Text(
                                        _formatCOP(originalPrice),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatCOP(discountPrice),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Text(
                                  _formatCOP(price),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                );
                              }
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Descripción',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product['descripcion']?.toString() ?? 'Sin descripción disponible.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.text.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Stock disponible: $stock unidades',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: stock > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (stock > 0)
                              Row(
                                children: [
                                  // Selector de Cantidad
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: qty > 1
                                              ? () => setModalState(() => qty--)
                                              : null,
                                        ),
                                        Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: qty < stock
                                              ? () => setModalState(() => qty++)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Botón Añadir
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _addToCart(product, quantity: qty);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Añadir al Carrito',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Agotado temporalmente',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCheckoutDialog() {
    if (_cart.isEmpty) return;

    final double subtotal = _getCartSubtotal();
    final double envio = widget.bookingId != null ? 0.0 : 12000.0;
    final double iva = subtotal * 0.19;
    final double total = subtotal + envio + iva;

    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController addressCtrl = TextEditingController();
    final TextEditingController cardCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool processing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setCheckoutState) {
            if (processing) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 24),
                      const Text(
                        'Procesando tu pago seguro...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conectando con la pasarela de GlowApp...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.text.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 680;

            final Widget formColumn = Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'GlowPay - Pago Seguro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Información de Envío',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección de Entrega',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Detalles del Pago',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de Tarjeta (16 dígitos)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                        hintText: '4111 2222 3333 4444',
                      ),
                      validator: (v) => (v == null || v.length < 16) ? 'Ingresa una tarjeta válida' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setCheckoutState(() {
                                  processing = true;
                                });
                                
                                try {
                                  final itemsList = _cart.values.map((item) {
                                    final prod = item['product'] as Map<String, dynamic>;
                                    final qty = item['quantity'] as int;
                                    return {
                                      'producto_id': prod['id'],
                                      'cantidad': qty
                                    };
                                  }).toList();

                                  final checkoutData = {
                                    'nombre_entrega': nameCtrl.text,
                                    'direccion_entrega': addressCtrl.text,
                                    'items': itemsList,
                                    if (widget.bookingId != null) 'booking_id': widget.bookingId,
                                  };

                                  final response = await ApiService.post('/api/store/checkout', checkoutData);

                                  if (response != null && response['success'] == true) {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _cart.clear();
                                      _isCartOpen = false;
                                    });
                                    _showOrderSuccessDialog();
                                  } else {
                                    throw Exception(response?['error'] ?? 'Error en el pago');
                                  }
                                } catch (e) {
                                  setCheckoutState(() {
                                    processing = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al realizar pedido: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Finalizar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            final Widget summaryColumn = Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del Pedido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (c, index) {
                      final item = _cart.values.elementAt(index);
                      final prod = item['product'] as Map<String, dynamic>;
                      final qty = item['quantity'] as int;
                      final pPrice = _getProductPrice(prod);
                      
                      return Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(prod['imagen_url']?.toString() ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: CircleAvatar(
                                  radius: 9,
                                  backgroundColor: AppTheme.primary,
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              prod['nombre']?.toString() ?? 'Producto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCOP(pPrice * qty),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Subtotal', _formatCOP(subtotal)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Envío', _formatCOP(envio)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('IVA (19%)', _formatCOP(iva)),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      Text(
                        _formatCOP(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              backgroundColor: Colors.white,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 400 : 800,
                ),
                child: SingleChildScrollView(
                  child: isMobile
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            summaryColumn,
                            const Divider(height: 1),
                            formColumn,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: formColumn),
                            Expanded(flex: 4, child: summaryColumn),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Pedido Realizado con Éxito!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu orden ha sido registrada. Pronto recibirás tus productos y la respectiva factura digital en tu correo electrónico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.text.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.text.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade100,
      width: double.infinity,
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'GlowApp Store',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          // Icono Carrito con Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.text),
                onPressed: () {
                  setState(() {
                    _isCartOpen = !_isCartOpen;
                  });
                },
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      '${_getCartItemCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Catálogo Principal
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchProducts,
                                    child: const Text('Reintentar'),
                                  )
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Filtros + Buscador (Shopify Header)
                                Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    children: [
                                      // Filtros Categoría
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: _categories.map((cat) {
                                              final isSelected = _selectedCategory == cat;
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8.0),
                                                child: ChoiceChip(
                                                  label: Text(cat),
                                                  selected: isSelected,
                                                  onSelected: (_) => _selectCategory(cat),
                                                  selectedColor: AppTheme.primary.withOpacity(0.12),
                                                  disabledColor: Colors.transparent,
                                                  backgroundColor: Colors.transparent,
                                                  labelStyle: TextStyle(
                                                    color: isSelected ? AppTheme.primary : AppTheme.text,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(18),
                                                    side: BorderSide(
                                                      color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      // Barra de Búsqueda
                                      Container(
                                        width: 280,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.search, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Buscar productos...',
                                                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Cuadrícula de Productos
                                Expanded(
                                  child: _filteredProducts.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No se encontraron productos disponibles.',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      : GridView.builder(
                                          padding: const EdgeInsets.all(24),
                                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 260,
                                            mainAxisExtent: 350,
                                            crossAxisSpacing: 18,
                                            mainAxisSpacing: 18,
                                          ),
                                          itemCount: _filteredProducts.length,
                                          itemBuilder: (ctx, index) {
                                            final product = _filteredProducts[index];
                                            return _buildProductCard(product);
                                          },
                                        ),
                                ),
                              ],
                            ),
                ),
                // Espacio invisible para cuando el Cart Drawer está abierto en pantallas grandes
                if (_isCartOpen && MediaQuery.of(context).size.width > 750) const SizedBox(width: 380),
              ],
            ),
          ),
          
          // Cart Drawer (Panel Lateral Flotante derecho)
          if (_isCartOpen)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: _buildCartDrawer(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
    final stock = product['stock'] as int? ?? 0;
    final imageUrl = product['imagen_url']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con hover zoom y Quick View
          Expanded(
            child: Stack(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(double.infinity),
                      )
                    : _buildPlaceholderImage(double.infinity),
                // Botón Vista Rápida
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Opacity(
                    opacity: 0.9,
                    child: ElevatedButton(
                      onPressed: () => _showQuickView(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.text,
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Vista Rápida', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['tag_especialidad']?.toString().toUpperCase() ?? 'COSMÉTICOS',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['nombre']?.toString() ?? 'Producto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                // Calificación Ficticia (Shopify Stars)
                Row(
                  children: List.generate(5, (starIdx) {
                    return const Icon(Icons.star, color: Colors.amber, size: 12);
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        if (widget.bookingId != null && product.containsKey('precio_con_reserva')) {
                          final originalPrice = double.tryParse(product['precio']?.toString() ?? '0') ?? 0.0;
                          final discountPrice = double.tryParse(product['precio_con_reserva']?.toString() ?? '0') ?? 0.0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCOP(originalPrice),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                _formatCOP(discountPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          _formatCOP(price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        );
                      }
                    ),
                    if (stock > 0)
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primary, size: 20),
                        onPressed: () => _addToCart(product),
                      )
                    else
                      const Text(
                        'Agotado',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartDrawer() {
    final subtotal = _getCartSubtotal();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth > 380 ? 380.0 : screenWidth;
    
    return Container(
      width: drawerWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Carrito
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: AppTheme.text),
                    SizedBox(width: 8),
                    Text(
                      'Tu Carrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.text),
                  onPressed: () {
                    setState(() {
                      _isCartOpen = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items del Carrito
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'Tu carrito está vacío.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (c, idx) {
                      final item = _cart.values.elementAt(idx);
                      final prod = item['product'] as Map<String, dynamic>;
                      final qty = item['quantity'] as int;
                      final id = prod['id'] as int;
                      final stock = prod['stock'] as int? ?? 0;
                      final pPrice = _getProductPrice(prod);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(prod['imagen_url']?.toString() ?? ''),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod['nombre']?.toString() ?? 'Producto',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCOP(pPrice),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.text.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Modificador de cantidad
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _updateCartQuantity(id, qty - 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.remove, size: 12),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: qty < stock 
                                          ? () => _updateCartQuantity(id, qty + 1)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.add, size: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCOP(pPrice * qty),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                onPressed: () => _updateCartQuantity(id, 0),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Subtotal + Checkout
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      Text(
                        _formatCOP(subtotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showCheckoutDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceder al Pago',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
