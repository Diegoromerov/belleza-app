import 'package:flutter/material.dart';

class ReservasScreen extends StatelessWidget {
  const ReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: const Center(child: Text('Pantalla de Reservas del salón')),
    );
  }
}
