// frontend/lib/screens/saas/widgets/customer_duplicate_modal.dart
import 'package:flutter/material.dart';
import '../../../models/saas/customer_model.dart';

/// CustomerDuplicateModal
///
/// Modal Human-in-the-Loop desplegado ante respuesta 409 POSSIBLE_DUPLICATE_FOUND.
/// Permite al operador humano decidir explícitamente:
/// A) Usar Cliente Existente
/// B) Crear como Cliente Distinto (confirm_duplicate: true)
class CustomerDuplicateModal extends StatelessWidget {
  final List<CustomerDuplicateCandidate> candidates;
  final VoidCallback onUseExisting;
  final VoidCallback onCreateDistinct;
  final VoidCallback onCancel;

  const CustomerDuplicateModal({
    super.key,
    required this.candidates,
    required this.onUseExisting,
    required this.onCreateDistinct,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CustomerDuplicateCandidate> candidates,
    required VoidCallback onUseExisting,
    required VoidCallback onCreateDistinct,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomerDuplicateModal(
        candidates: candidates,
        onUseExisting: () {
          Navigator.of(ctx).pop();
          onUseExisting();
        },
        onCreateDistinct: () {
          Navigator.of(ctx).pop();
          onCreateDistinct();
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          onCancel();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Posible Duplicado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se encontraron clientes registrados con datos de contacto coincidentes (teléfono o correo). Verifica si deseas utilizar el registro existente o crear una persona distinta:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (candidates.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  candidate.firstName.isNotEmpty ? candidate.firstName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  candidate.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: candidate.status == 'ACTIVE' ? Colors.green.shade50 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: candidate.status == 'ACTIVE' ? Colors.green.shade300 : Colors.grey.shade400,
                                  ),
                                ),
                                child: Text(
                                  candidate.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: candidate.status == 'ACTIVE' ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (candidate.phone != null && candidate.phone!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(candidate.phone!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            ),
                          if (candidate.email != null && candidate.email!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(candidate.email!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
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
      actions: [
        TextButton(
          key: const Key('btn_duplicate_cancel'),
          onPressed: onCancel,
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        OutlinedButton(
          key: const Key('btn_duplicate_use_existing'),
          onPressed: onUseExisting,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.indigo),
          ),
          child: const Text('Usar Existente', style: TextStyle(color: Colors.indigo)),
        ),
        ElevatedButton(
          key: const Key('btn_duplicate_create_distinct'),
          onPressed: onCreateDistinct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('Crear Distinto'),
        ),
      ],
    );
  }
}
