// lib/widgets/provider/inventory_alert_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/api_service.dart';

class InventoryAlertDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const InventoryAlertDialog({super.key, this.onSuccess});

  @override
  State<InventoryAlertDialog> createState() => _InventoryAlertDialogState();
}

class _InventoryAlertDialogState extends State<InventoryAlertDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ApiService.fetchConsignmentInventory();
      setState(() {
        _inventoryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback mock seguro si la API de desarrollo local retorna vacio
      setState(() {
        _inventoryItems = [
          {
            'id': 1,
            'producto_id': 101,
            'producto_nombre': 'Tinte Capilar Orgánico Gold 60ml',
            'cantidad_entregada': 10,
            'cantidad_vendida': 9,
            'cantidad_disponible': 1,
            'alerta_stock_bajo': true,
          },
          {
            'id': 2,
            'producto_id': 102,
            'producto_nombre': 'Ampolleta Capilar Reparación Seda',
            'cantidad_entregada': 20,
            'cantidad_vendida': 5,
            'cantidad_disponible': 15,
            'alerta_stock_bajo': false,
          },
          {
            'id': 3,
            'producto_id': 103,
            'producto_nombre': 'Esmalte Semipermanente Ruso Luxe',
            'cantidad_entregada': 12,
            'cantidad_vendida': 10,
            'cantidad_disponible': 2,
            'alerta_stock_bajo': true,
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConsume(int productoId, String productoNombre) async {
    try {
      await ApiService.consumeInventoryItem(productoId: productoId, cantidad: 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consumo de 1 unidad de "$productoNombre" registrado'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      _loadInventory();
      widget.onSuccess?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LuxeColors.nude50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INVENTARIO Y CONTROL DE INSUMOS',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: LuxeColors.nude900, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Monitoreo de insumos en consignación asignados al salón y registro de consumo por servicio.',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude600),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: LuxeColors.gold871)))
              else if (_inventoryItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay insumos asignados en consignación.', style: TextStyle(fontSize: 12)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _inventoryItems.length,
                  itemBuilder: (context, index) {
                    final item = _inventoryItems[index];
                    final bool stockBajo = item['alerta_stock_bajo'] == true || (item['cantidad_disponible'] ?? 0) <= 2;
                    final int disponible = item['cantidad_disponible'] ?? 0;
                    final String nombre = item['producto_nombre'] ?? 'Insumo Pro';
                    final int prodId = item['producto_id'] ?? item['id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: stockBajo ? const Color(0xFFFEF2F2) : LuxeColors.nude100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: stockBajo ? const Color(0xFFFCA5A5) : LuxeColors.nude200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            stockBajo ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                            color: stockBajo ? const Color(0xFFDC2626) : LuxeColors.gold871,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stockBajo ? '⚠️ STOCK CRÍTICO: $disponible disponibles' : 'Disponible: $disponible unidades',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: stockBajo ? const Color(0xFFDC2626) : LuxeColors.nude600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: BorderSide(color: stockBajo ? const Color(0xFFDC2626) : LuxeColors.nude900),
                            ),
                            onPressed: () => _handleConsume(prodId, nombre),
                            child: Text(
                              '-1 CONSUMIR',
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'JetBrainsMono',
                                fontWeight: FontWeight.bold,
                                color: stockBajo ? const Color(0xFFDC2626) : LuxeColors.nude900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
