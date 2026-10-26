import 'package:flutter/material.dart';

/// Opportunity Detail Screen – placeholder UI for a single opportunity.
class OpportunityDetailScreen extends StatelessWidget {
  final String id;
  const OpportunityDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Oportunidad')),
      body: Center(child: Text('Detalle de la oportunidad: $id')),
    );
  }
}
