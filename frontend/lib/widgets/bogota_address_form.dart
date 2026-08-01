import 'package:flutter/material.dart';

class AddressData {
  final String tipoVia; // Calle, Carrera, Avenida, Diagonal, Transversal
  final String numeroVia; // acepta sufijo Bis, A
  final String numeroPlaca;
  final String numeroComplemento;
  final String? complementoInterior;
  final String localidad;
  final String barrio;
  final String? referencia;

  AddressData({
    required this.tipoVia,
    required this.numeroVia,
    required this.numeroPlaca,
    required this.numeroComplemento,
    this.complementoInterior,
    required this.localidad,
    required this.barrio,
    this.referencia,
  });

  String get formatted {
    final compInt = (complementoInterior != null && complementoInterior!.trim().isNotEmpty) ? ', ${complementoInterior!.trim()}' : '';
    final barrioPart = (barrio.trim().isNotEmpty) ? ', ${barrio.trim()}' : '';
    return '$tipoVia $numeroVia # $numeroPlaca-$numeroComplemento$compInt$barrioPart, $localidad, Bogotá';
  }

  Map<String, dynamic> toJson() => {
        'tipo_via': tipoVia,
        'numero_via': numeroVia,
        'numero_placa': numeroPlaca,
        'numero_complemento': numeroComplemento,
        'complemento_interior': complementoInterior,
        'barrio': barrio,
        'localidad': localidad,
        'referencia': referencia,
      };
}

class BogotaAddressForm extends StatefulWidget {
  final void Function(AddressData) onAddressChanged;
  final AddressData? initialValue;

  const BogotaAddressForm({Key? key, required this.onAddressChanged, this.initialValue}) : super(key: key);

  @override
  State<BogotaAddressForm> createState() => _BogotaAddressFormState();
}

class _BogotaAddressFormState extends State<BogotaAddressForm> {
  static const List<String> tiposVia = ['Calle', 'Carrera', 'Avenida', 'Diagonal', 'Transversal'];
  static const List<String> localidades = [
    'Usaquén', 'Chapinero', 'Santa Fe', 'San Cristóbal', 'Usme', 'Tunjuelito', 'Bosa', 'Kennedy', 'Fontibón', 'Engativá',
    'Suba', 'Barrios Unidos', 'Teusaquillo', 'Los Mártires', 'Antonio Nariño', 'Puente Aranda', 'La Candelaria', 'Rafael Uribe Uribe', 'Ciudad Bolívar', 'Sumapaz'
  ];

  String? _tipoVia;
  final TextEditingController _numeroViaController = TextEditingController();
  final TextEditingController _numeroPlacaController = TextEditingController();
  final TextEditingController _numeroComplementoController = TextEditingController();
  final TextEditingController _complementoInteriorController = TextEditingController();
  String? _localidad;
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    if (v != null) {
      _tipoVia = v.tipoVia;
      _numeroViaController.text = v.numeroVia;
      _numeroPlacaController.text = v.numeroPlaca;
      _numeroComplementoController.text = v.numeroComplemento;
      _complementoInteriorController.text = v.complementoInterior ?? '';
      _localidad = v.localidad;
      _barrioController.text = v.barrio;
      _referenciaController.text = v.referencia ?? '';
    }
  }

  @override
  void dispose() {
    _numeroViaController.dispose();
    _numeroPlacaController.dispose();
    _numeroComplementoController.dispose();
    _complementoInteriorController.dispose();
    _barrioController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _emitChange() {
    if (_tipoVia == null || _tipoVia!.trim().isEmpty) return;
    if (_localidad == null || _localidad!.trim().isEmpty) return;
    final addr = AddressData(
      tipoVia: _tipoVia!,
      numeroVia: _numeroViaController.text.trim(),
      numeroPlaca: _numeroPlacaController.text.trim(),
      numeroComplemento: _numeroComplementoController.text.trim(),
      complementoInterior: _complementoInteriorController.text.trim().isEmpty ? null : _complementoInteriorController.text.trim(),
      localidad: _localidad!,
      barrio: _barrioController.text.trim(),
      referencia: _referenciaController.text.trim().isEmpty ? null : _referenciaController.text.trim(),
    );
    widget.onAddressChanged(addr);
  }

  Widget _buildDropdown<T>(T? value, List<T> items, void Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdown<String?>(_tipoVia, tiposVia, (v) => setState(() { _tipoVia = v; _emitChange(); })),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _numeroViaController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'N° vía', border: OutlineInputBorder()),
                onChanged: (_) => _emitChange(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _numeroPlacaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'N° placa', border: OutlineInputBorder()),
                onChanged: (_) => _emitChange(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _numeroComplementoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'N° complemento', border: OutlineInputBorder()),
                onChanged: (_) => _emitChange(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _complementoInteriorController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(labelText: 'Complemento interior (ej. Apto 502)', border: OutlineInputBorder()),
          onChanged: (_) => _emitChange(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String?>(_localidad, localidades, (v) => setState(() { _localidad = v; _emitChange(); })),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _barrioController,
                decoration: const InputDecoration(labelText: 'Barrio', border: OutlineInputBorder()),
                onChanged: (_) => _emitChange(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referenciaController,
          decoration: const InputDecoration(labelText: 'Referencia adicional (opcional)', border: OutlineInputBorder()),
          onChanged: (_) => _emitChange(),
        ),
      ],
    );
  }
}
