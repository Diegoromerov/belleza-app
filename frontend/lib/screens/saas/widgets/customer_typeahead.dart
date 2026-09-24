// frontend/lib/screens/saas/widgets/customer_typeahead.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/saas/customer_model.dart';
import '../../../services/saas/saas_customers_service.dart';

/// CustomerTypeahead
///
/// Componente reutilizable de búsqueda rápida de clientes (debounce 400ms, min 3 chars).
/// Reutilizado en:
/// - SCR-13 (CustomerDirectoryScreen)
/// - SCR-11 (ReservaInternaScreen)
/// - SCR-12 (ServiceTicketCheckoutScreen)
class CustomerTypeahead extends StatefulWidget {
  final void Function(SaasCustomerSummary customer) onCustomerSelected;
  final VoidCallback? onAddNewCustomerRequested;
  final String hintText;
  final int minQueryLength;
  final SaasCustomersService? service;
  final TextEditingController? controller;

  const CustomerTypeahead({
    super.key,
    required this.onCustomerSelected,
    this.onAddNewCustomerRequested,
    this.hintText = 'Buscar cliente por nombre, teléfono o email...',
    this.minQueryLength = 3,
    this.service,
    this.controller,
  });

  @override
  State<CustomerTypeahead> createState() => _CustomerTypeaheadState();
}

class _CustomerTypeaheadState extends State<CustomerTypeahead> {
  late final SaasCustomersService _service;
  late final TextEditingController _controller;
  bool _ownsController = false;

  Timer? _debounceTimer;
  bool _isSearching = false;
  List<SaasCustomerSummary> _results = [];
  bool _showDropdown = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SaasCustomersService();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < widget.minQueryLength) {
      setState(() {
        _results = [];
        _isSearching = false;
        _showDropdown = false;
        _searchError = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _showDropdown = true;
    });

    try {
      final results = await _service.searchCustomers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString().replaceFirst('SaasCustomerException: ', '');
          _isSearching = false;
        });
      }
    }
  }

  void _selectCustomer(SaasCustomerSummary customer) {
    setState(() {
      _showDropdown = false;
      _controller.text = customer.fullName;
    });
    widget.onCustomerSelected(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('input_customer_typeahead'),
          controller: _controller,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.indigo),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
            ),
          ),
        ),
        if (_showDropdown) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildDropdownContent(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownContent() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Buscando clientes...', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    if (_searchError != null) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('Error: $_searchError', style: const TextStyle(color: Colors.red, fontSize: 12)),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se encontraron clientes coincidentes.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (widget.onAddNewCustomerRequested != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('btn_typeahead_create_new'),
                onPressed: () {
                  setState(() => _showDropdown = false);
                  widget.onAddNewCustomerRequested!();
                },
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: const Text('Registrar nuevo cliente'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = _results[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.indigo.shade100,
            child: Text(
              customer.firstName.isNotEmpty ? customer.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(
            '${customer.phone ?? 'Sin teléfono'} • ${customer.email ?? 'Sin email'}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          trailing: customer.isAssociatedWithActiveEstablishment
              ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Otra Sede', style: TextStyle(fontSize: 9, color: Colors.blueAccent)),
                ),
          onTap: () => _selectCustomer(customer),
        );
      },
    );
  }
}
