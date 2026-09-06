// frontend/lib/screens/designs/medical_validation_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../shared/theme.dart';

class MedicalValidationScreen extends StatefulWidget {
  const MedicalValidationScreen({super.key});

  @override
  State<MedicalValidationScreen> createState() => _MedicalValidationScreenState();
}

class _MedicalValidationScreenState extends State<MedicalValidationScreen> {
  int? _passedDiagnosticId;
  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _validations = [];
  Map<String, dynamic>? _selectedDoctor;
  String _plan = 'free';

  Timer? _pollingTimer;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map<String, dynamic>) {
      _passedDiagnosticId = args['diagnostic_id'];
    } else if (args is int) {
      _passedDiagnosticId = args;
    }
    _loadInitialData();
  }

  @override
  void initState() {
    super.initState();
    // Iniciar polling para simular la respuesta médica en segundo plano
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ApiService.fetchUserProfile();
      final docs = await ApiService.fetchRecommendedDoctors();
      final history = await ApiService.fetchValidationHistory();

      setState(() {
        _plan = profile['glowai_plan'] ?? 'free';
        _doctors = docs;
        _validations = history;
        if (docs.isNotEmpty) {
          _selectedDoctor = docs.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isSubmitting || _isLoading) return;

      try {
        final newHistory = await ApiService.fetchValidationHistory();
        
        // Comparar si alguna validación pendiente cambió a revisado
        for (var oldVal in _validations) {
          final newVal = newHistory.firstWhere((element) => element['id'] == oldVal['id'], orElse: () => <String, dynamic>{});
          if (newVal.isNotEmpty && oldVal['estado'] == 'pendiente' && newVal['estado'] == 'revisado') {
            // Gatillar notificación local
            NotificationService().triggerMockNotification(
              title: '🩺 Validación Médica Lista',
              body: '${newVal['profesional_nombre']} ha revisado tu diagnóstico de piel.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ¡Validación médica de ${newVal['profesional_nombre']} lista!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        setState(() {
          _validations = newHistory;
        });
      } catch (e) {
        debugPrint('Error polling validations: $e');
      }
    });
  }

  Future<void> _submitRequestPremium() async {
    if (_selectedDoctor == null) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.requestMedicalValidation(_passedDiagnosticId, _selectedDoctor!['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Solicitud médica enviada con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showWompiPaymentModal() {
    if (_selectedDoctor == null) return;
    
    final cardNumberController = TextEditingController(text: '4000 1234 5678 9010');
    final cardHolderController = TextEditingController(text: 'USUARIO PRUEBAS');
    final cardExpiryController = TextEditingController(text: '12/29');
    final cardCvvController = TextEditingController(text: '123');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Pasarela de Pago Wompi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transacción Segura de Micro-pago. Monto: \$15.000 COP',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Formulario de Tarjeta Simulado
                  TextFormField(
                    controller: cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Tarjeta',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cardExpiryController,
                          decoration: const InputDecoration(
                            labelText: 'Vence (MM/AA)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cardCvvController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cardHolderController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Titular',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            Navigator.pop(context);
                            setState(() {
                              _isSubmitting = true;
                            });

                            try {
                              await ApiService.payMedicalValidation(_passedDiagnosticId, _selectedDoctor!['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Pago exitoso vía Wompi. Solicitud enviada.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadInitialData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('⚠️ Error al procesar pago: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          },
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirmar y Pagar \$15.000 COP', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Validación Médica', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Validación Médica',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFFAF8F5),
        foregroundColor: const Color(0xFF1F1A15),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar dermatólogos:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadInitialData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD CLÍNICA PRINCIPAL: Selección de Especialista
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Red de Dermatólogos Calificados',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Profesionales médicos activos en la alianza para validación de diagnósticos IA.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          // Dropdown / Selector de médico
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedDoctor,
                            decoration: const InputDecoration(
                              labelText: 'Selecciona un Dermatólogo',
                              border: OutlineInputBorder(),
                            ),
                            items: _doctors.map((doc) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: doc,
                                child: Text(doc['nombre'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDoctor = val;
                              });
                            },
                          ),
                          if (_selectedDoctor != null) ...[
                            const SizedBox(height: 16),
                            // Detalles del médico seleccionado
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Especialidad: ${_selectedDoctor!['especialidad']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.text),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Registro Médico: ${_selectedDoctor!['registro_medico']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Condiciones Tratadas:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: ((_selectedDoctor!['condiciones_tratadas'] ?? []) as List<dynamic>).map((c) {
                                      return Chip(
                                        label: Text(c.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFFF3EAE8)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Botones de acción según plan
                          if (_plan == 'premium')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _isSubmitting ? null : _submitRequestPremium,
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Solicitar Validación Gratis (Premium)', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _isSubmitting ? null : _showWompiPaymentModal,
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Pagar y Solicitar con Wompi (\$15.000 COP)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECCIÓN: Historial de Validaciones Solicitadas
                  const Text(
                    'Historial de Validaciones Clínicas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text),
                  ),
                  const SizedBox(height: 12),
                  if (_validations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF3EAE8)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Aún no has solicitado validaciones clínicas para tus escaneos.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _validations.length,
                      itemBuilder: (context, index) {
                        final val = _validations[index];
                        final isRevisado = val['estado'] == 'revisado';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFF3EAE8), width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      val['profesional_nombre'] ?? 'Médico',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isRevisado ? Colors.green.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isRevisado ? 'REVISADO' : 'PENDIENTE',
                                        style: TextStyle(
                                          color: isRevisado ? Colors.green.shade700 : Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Especialidad: ${val['profesional_especialidad']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                if (isRevisado) ...[
                                  const Text(
                                    'Nota del Dermatólogo:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.text),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    val['nota_profesional'] ?? 'Sin nota.',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                                  ),
                                ] else ...[
                                  const Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Esperando revisión del especialista (Simulación: 15s)...',
                                        style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
