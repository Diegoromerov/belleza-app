import 'package:flutter/material.dart';

/// Opportunity List Screen – placeholder UI for listing opportunities.
class OpportunityListScreen extends StatelessWidget {
  const OpportunityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oportunidades')),
      body: const Center(child: Text('Listado de oportunidades (pendiente)')),
    );
  }
}
