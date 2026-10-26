import 'package:flutter/material.dart';

/// Lead Form Screen – placeholder UI for creating a lead.
class LeadFormScreen extends StatelessWidget {
  const LeadFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Lead')),
      body: const Center(child: Text('Formulario de Lead (pendiente)')),
    );
  }
}
