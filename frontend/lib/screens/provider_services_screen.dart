// frontend/lib/screens/provider_services_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/service_model.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchProviderServices();
      if (mounted) {
        setState(() {
          _services = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitServiceHelper({
    ServiceModel? service,
    required String name,
    required double price,
    required int duration,
    String? description,
    String? category,
    required bool isActive,
  }) async {
    setState(() => _isLoading = true);
    try {
      if (service == null) {
        await ApiService.createService(
          name: name,
          price: price,
          durationMinutes: duration,
          description: description,
          category: category,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Servicio creado con éxito'), 
              backgroundColor: const Color(0xFFC89D93),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }
      } else {
        await ApiService.updateService(
          id: service.id,
          name: name,
          price: price,
          durationMinutes: duration,
          description: description,
          category: category,
          isActive: isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Servicio actualizado con éxito'), 
              backgroundColor: const Color(0xFFC89D93),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }
      }
      _loadServices();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showServiceForm({ServiceModel? service}) async {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    final priceCtrl = TextEditingController(text: service?.price.toString() ?? '');
    final durationCtrl = TextEditingController(text: service?.durationMinutes.toString() ?? '');
    final categoryCtrl = TextEditingController(text: service?.category ?? '');
    final formKey = GlobalKey<FormState>();
    bool isActive = service?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        service == null ? 'Nuevo Servicio' : 'Editar Servicio',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _inputDecoration('Nombre del servicio *', Icons.cut),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        decoration: _inputDecoration('Descripción (opcional)', Icons.description_outlined),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              decoration: _inputDecoration('Precio (\$) *', Icons.attach_money_outlined),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Requerido';
                                }
                                final cleanVal = v.replaceAll(',', '.');
                                final price = double.tryParse(cleanVal);
                                if (price == null || price < 0) {
                                  return 'Precio inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: durationCtrl,
                              decoration: _inputDecoration('Duración (min) *', Icons.access_time_outlined),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Requerido';
                                }
                                final dur = int.tryParse(v);
                                if (dur == null || dur <= 0) {
                                  return 'Duración inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: categoryCtrl,
                        decoration: _inputDecoration('Categoría (opcional)', Icons.category_outlined),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (service != null)
                        SwitchListTile(
                          title: const Text('Servicio activo'),
                          subtitle: Text(isActive ? 'Visible para clientes' : 'Oculto para clientes'),
                          value: isActive,
                          activeThumbColor: Colors.green,
                          activeTrackColor: const Color(0xFFDCFCE7),
                          onChanged: (v) => setModalState(() => isActive = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC89D93),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            _submitServiceHelper(
                              service: service,
                              name: nameCtrl.text.trim(),
                              price: double.parse(priceCtrl.text.replaceAll(',', '.')),
                              duration: int.parse(durationCtrl.text),
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              category: categoryCtrl.text.trim().isNotEmpty ? categoryCtrl.text.trim() : null,
                              isActive: isActive,
                            );
                          }
                        },
                        child: Text(service == null ? 'Crear Servicio' : 'Guardar Cambios', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFC89D93)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: const Color(0xFFF5EBE6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _confirmDelete(ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('¿Desactivar servicio?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text('¿Estás seguro de que deseas desactivar "${service.name}"? Los clientes no podrán reservarlo, pero el historial de citas se mantendrá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Desactivar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.deleteService(service.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Servicio desactivado'), 
              backgroundColor: const Color(0xFFC89D93),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }
        _loadServices();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFC89D93)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showServiceForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primer Servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    final statusColor = service.isActive ? const Color(0xFF16A34A) : Colors.grey;
    final statusBgColor = service.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showServiceForm(service: service),
        child: Opacity(
          opacity: service.isActive ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (service.category.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              service.category,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${service.durationMinutes} min', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC89D93)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showServiceForm(service: service),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC89D93),
                          side: const BorderSide(color: Color(0xFFE5CECA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(service),
                        icon: const Icon(Icons.block_outlined, size: 16),
                        label: Text(service.isActive ? 'Desactivar' : 'Activar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: service.isActive ? Colors.red : Colors.green,
                          side: BorderSide(color: (service.isActive ? Colors.red : Colors.green)[200]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _services.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Servicios', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))),
      );
    }

    if (_error != null && _services.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Servicios', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text('Error de conexión:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadServices,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC89D93), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final active = _services.where((s) => s.isActive).toList();
    final inactive = _services.where((s) => !s.isActive).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mis Servicios', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadServices,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC89D93),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFC89D93),
          tabs: [
            Tab(text: 'Activos (${active.length})'),
            Tab(text: 'Inactivos (${inactive.length})'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                color: const Color(0xFFC89D93),
                onRefresh: _loadServices,
                child: active.isEmpty
                    ? _buildEmptyState('No tienes servicios activos.\nToca el botón + para agregar uno.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: active.length,
                        itemBuilder: (context, index) => _buildServiceCard(active[index]),
                      ),
              ),
              RefreshIndicator(
                color: const Color(0xFFC89D93),
                onRefresh: _loadServices,
                child: inactive.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No tienes servicios inactivos.',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: inactive.length,
                        itemBuilder: (context, index) => _buildServiceCard(inactive[index]),
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: const Color(0x1E000000),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(),
        backgroundColor: const Color(0xFFC89D93),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}