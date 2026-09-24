// frontend/lib/screens/saas/available_context_selector_screen.dart
import 'package:flutter/material.dart';
import '../../models/saas/available_context_model.dart';
import '../../services/active_context_holder.dart';
import '../../services/saas_context_service.dart';

/// AvailableContextSelectorScreen
///
/// Pantalla canónica para presentar los contextos SaaS disponibles y capturar
/// la selección EXPLÍCITA de sede por parte del usuario (DEC-N07-AC-001).
///
/// INVARIANTES ARQUITECTÓNICAS (NODO-07 FASE 3):
/// 1. Cero auto-selección en initState, load, build o post-frame callbacks.
/// 2. ONE_CONTEXT exige confirmación explícita (botón "Ingresar a Sede").
/// 3. MULTIPLE_CONTEXTS exige elección explícita de tarjeta de sede.
/// 4. NO_CONTEXT no muta ActiveContextHolder ni inventa identificadores.
/// 5. La selección alimenta ActiveContextHolder exclusivamente en RAM.
class AvailableContextSelectorScreen extends StatefulWidget {
  final Future<AvailableContextResponse> Function()? contextLoader;
  final void Function(AvailableContextItem selectedItem)? onContextSelected;

  const AvailableContextSelectorScreen({
    Key? key,
    this.contextLoader,
    this.onContextSelected,
  }) : super(key: key);

  @override
  State<AvailableContextSelectorScreen> createState() =>
      _AvailableContextSelectorScreenState();
}

enum _ViewState { loading, success, error }

class _AvailableContextSelectorScreenState
    extends State<AvailableContextSelectorScreen> {
  _ViewState _state = _ViewState.loading;
  AvailableContextResponse? _response;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableContexts();
  }

  Future<void> _loadAvailableContexts() async {
    setState(() {
      _state = _ViewState.loading;
      _errorMessage = null;
    });

    try {
      final response = widget.contextLoader != null
          ? await widget.contextLoader!()
          : await SaaSContextService.fetchAvailableContexts();

      if (mounted) {
        setState(() {
          _response = response;
          _state = _ViewState.success;
        });
        // 🛡️ REGLA DEC-N07-AC-001: CERO AUTO-SELECCIÓN.
        // ActiveContextHolder permanece INTACTO tras la carga.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = _ViewState.error;
        });
      }
    }
  }

  void _handleExplicitSelection(AvailableContextItem item) {
    // Establecer el membership_id explícitamente en el ActiveContextHolder en memoria
    ActiveContextHolder().setActiveMembershipId(item.membershipId);

    if (widget.onContextSelected != null) {
      widget.onContextSelected!(item);
    } else {
      // Intentar navegar al Hub Salón si la ruta existe
      Navigator.of(context).pushReplacementNamed('/saas/hub');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selección de Sede SaaS'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ViewState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando sedes disponibles...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );

      case _ViewState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error consultando sedes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'No fue posible obtener los contextos disponibles.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAvailableContexts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );

      case _ViewState.success:
        final res = _response;
        if (res == null || res.isNoContext) {
          return _buildNoContextView();
        } else if (res.isOneContext) {
          return _buildOneContextView(res.availableContexts.first);
        } else {
          return _buildMultipleContextsView(res.availableContexts);
        }
    }
  }

  /// NO_CONTEXT: Sin sedes asignadas
  Widget _buildNoContextView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sin Sedes Asignadas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu cuenta no posee membresías activas en ninguna sede física de GlowApp SaaS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: null, // Deshabilitado para preservar el Journey Boundary
              icon: const Icon(Icons.add_business),
              label: const Text('Crear Salón Desde Cero (Fase 4)'),
            ),
          ],
        ),
      ),
    );
  }

  /// ONE_CONTEXT: DEC-N07-AC-001 (Confirmación explícita obligatoria)
  Widget _buildOneContextView(AvailableContextItem item) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sede Asignada',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Se encontró 1 sede asociada a ${item.tenantName.isNotEmpty ? item.tenantName : "tu organización"}. Confirma el ingreso para operar.',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildEstablishmentCard(item, isSingle: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('btn_ingresar_sede_unica'),
              onPressed: () => _handleExplicitSelection(item),
              icon: const Icon(Icons.login),
              label: const Text(
                'INGRESAR A ESTA SEDE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// MULTIPLE_CONTEXTS: Selección deliberada en lista
  Widget _buildMultipleContextsView(List<AvailableContextItem> contexts) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu Sede Operativa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tienes acceso a ${contexts.length} sedes. Selecciona con cuál deseas operar hoy:',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: contexts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = contexts[index];
                return _buildEstablishmentCard(item, isSingle: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentCard(AvailableContextItem item, {required bool isSingle}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        key: Key('card_membership_${item.membershipId}'),
        borderRadius: BorderRadius.circular(12),
        onTap: isSingle ? null : () => _handleExplicitSelection(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.establishmentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      item.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.organizationLegalName.isNotEmpty) ...[
                Text(
                  item.organizationLegalName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Tenant: ${item.tenantName.isNotEmpty ? item.tenantName : "N/A"}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (!isSingle) ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Seleccionar',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
