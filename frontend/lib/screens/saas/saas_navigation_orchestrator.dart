// frontend/lib/screens/saas/saas_navigation_orchestrator.dart
// NODO-07: Hub Navigation Orchestration Layer (CONTRACT v1.0 RATIFIED)

import 'package:flutter/material.dart';
import '../../models/saas/available_context_model.dart';
import '../../services/hub_salon_service.dart';
import '../../services/saas/saas_agenda_service.dart';
import '../../services/saas/saas_reserva_interna_service.dart';
import '../../services/saas/service_offer_assignment_service.dart';
import '../../services/saas/staff_schedule_service.dart';
import '../../services/saas/crear_desde_cero_service.dart';
import '../../services/saas/saas_customers_service.dart';
import '../../services/saas_staff_service.dart';
import 'available_context_selector_screen.dart';
import 'crear_desde_cero_screen.dart';
import 'customer_directory_screen.dart';
import 'staff_directory_screen.dart';
import 'invitation_acceptance_screen.dart';
import 'service_ticket_checkout_screen.dart';
import '../../services/saas/saas_tickets_service.dart';
import '../../services/saas/saas_cash_service.dart';
import 'cash_drawer_screen.dart';
import 'hub_salon_screen.dart';
import 'service_offer_assignment_screen.dart';
import 'staff_schedule_screen.dart';
import 'agenda_operativa_screen.dart';
import 'reserva_interna_screen.dart';

/// [SaasNavigationOrchestrator]
///
/// Orquestador canónico de navegación para el subsistema GlowApp SaaS.
/// Conecta el Hub Salón (SCR-05) con sus pantallas operativas satélite
/// (SCR-04, SCR-06, SCR-08, SCR-09, SCR-10, SCR-11, SCR-13, SCR-14, SCR-16) y gestiona los
/// retornos y semántica de recarga (Demand Refresh) conforme al contrato
/// ratificado `NODO-07-SAAS-HUB-NAVIGATION-ORCHESTRATION-CONTRACT-v1.0.md`.
class SaasNavigationOrchestrator extends StatelessWidget {
  final HubSalonService? hubService;
  final SaasAgendaService? agendaService;
  final SaasReservaInternaService? reservaService;
  final ServiceOfferAssignmentService? serviceOfferService;
  final StaffScheduleService? staffScheduleService;
  final CrearDesdeCeroService? crearDesdeCeroService;
  final SaasCustomersService? customerService;
  final SaasStaffService? staffService;
  final SaasCashService? cashService;
  final Future<AvailableContextResponse> Function()? contextLoader;

  const SaasNavigationOrchestrator({
    super.key,
    this.hubService,
    this.agendaService,
    this.reservaService,
    this.serviceOfferService,
    this.staffScheduleService,
    this.crearDesdeCeroService,
    this.customerService,
    this.staffService,
    this.cashService,
    this.contextLoader,
  });

  /// Navegación canónica desde Hub hacia SCR-08 (Catálogo de Servicios)
  static Future<void> navigateToCatalog(
    BuildContext context, {
    ServiceOfferAssignmentService? service,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceOfferAssignmentScreen(service: service),
      ),
    );
  }

  /// Navegación canónica desde Hub hacia SCR-09 (Horarios de Personal)
  static Future<void> navigateToStaffSchedules(
    BuildContext context, {
    StaffScheduleService? service,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffScheduleScreen(service: service),
      ),
    );
  }

  /// Navegación canónica desde Hub hacia SCR-10 (Agenda Operativa)
  static Future<void> navigateToAgenda(
    BuildContext context, {
    SaasAgendaService? agendaService,
    SaasReservaInternaService? reservaService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgendaOperativaScreen(
          agendaService: agendaService,
          onNavigateToCreateAppointment: () => navigateToCreateAppointment(
            context,
            reservaService: reservaService,
          ),
        ),
      ),
    );
  }

  /// Navegación canónica desde SCR-10 hacia SCR-11 (Reserva Interna / Slots)
  static Future<bool?> navigateToCreateAppointment(
    BuildContext context, {
    String? initialDate,
    String? preselectedMembershipId,
    SaasReservaInternaService? reservaService,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => ReservaInternaScreen(
          initialDate: initialDate,
          preselectedMembershipId: preselectedMembershipId,
          service: reservaService,
          onAppointmentCreated: () => Navigator.of(ctx).pop(true),
          onCancel: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );
  }

  /// Navegación canónica desde Hub hacia SCR-06 (Crear Desde Cero)
  static Future<bool?> navigateToCreateFromScratch(
    BuildContext context, {
    CrearDesdeCeroService? service,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrearDesdeCeroWizardScreen(service: service),
      ),
    );
  }

  /// Navegación canónica desde Hub hacia SCR-13 (Directorio de Clientes)
  static Future<void> navigateToCustomerDirectory(
    BuildContext context, {
    SaasCustomersService? service,
    String? initialRole,
    Future<AvailableContextResponse> Function()? contextLoader,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDirectoryScreen(
          service: service,
          initialRole: initialRole,
          onNavigateToContextSelector: () => navigateToContextSelector(context, contextLoader: contextLoader),
        ),
      ),
    );
  }

  /// Navegación canónica desde Hub hacia SCR-14 (Directorio y Gestión de Personal)
  static Future<void> navigateToStaffDirectory(
    BuildContext context, {
    SaasStaffService? service,
    String? initialRole,
    int? currentUserId,
    Future<AvailableContextResponse> Function()? contextLoader,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffDirectoryScreen(
          service: service,
          initialRole: initialRole,
          currentUserId: currentUserId,
          onNavigateToContextSelector: () => navigateToContextSelector(context, contextLoader: contextLoader),
        ),
      ),
    );
  }

  /// Navegación canónica hacia SCR-15 (Aceptación Pública de Invitación)
  static Future<bool?> navigateToInvitationAcceptance(
    BuildContext context, {
    required String token,
    SaasStaffService? service,
    VoidCallback? onAcceptanceSuccess,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvitationAcceptanceScreen(
          token: token,
          service: service,
          onAcceptanceSuccess: onAcceptanceSuccess,
        ),
      ),
    );
  }

  /// Navegación canónica hacia SCR-04 (Selector de Contexto / Sedes)
  static Future<bool?> navigateToContextSelector(
    BuildContext context, {
    Future<AvailableContextResponse> Function()? contextLoader,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AvailableContextSelectorScreen(contextLoader: contextLoader),
      ),
    );
  }

  /// Navegación canónica hacia SCR-12 (Punto de Venta / Checkout)
  static Future<bool?> navigateToCheckout(
    BuildContext context, {
    String? ticketId,
    String? appointmentId,
    String? preselectedCustomerId,
    String? initialRole,
    SaasTicketsService? ticketsService,
    ServiceOfferAssignmentService? offerService,
    SaasCashService? cashService,
    Future<AvailableContextResponse> Function()? contextLoader,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceTicketCheckoutScreen(
          ticketId: ticketId,
          appointmentId: appointmentId,
          preselectedCustomerId: preselectedCustomerId,
          initialRole: initialRole,
          ticketsService: ticketsService,
          offerService: offerService,
          onNavigateToContextSelector: () => navigateToContextSelector(context, contextLoader: contextLoader),
          onNavigateToCashDrawer: () => navigateToCashDrawer(context, cashService: cashService, contextLoader: contextLoader),
        ),
      ),
    );
  }

  /// Navegación canónica hacia SCR-16 (Gestión de Caja / Cash Drawer)
  static Future<bool?> navigateToCashDrawer(
    BuildContext context, {
    SaasCashService? cashService,
    String? initialRole,
    Future<AvailableContextResponse> Function()? contextLoader,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CashDrawerScreen(
          service: cashService,
          initialRole: initialRole,
          onNavigateToContextSelector: () => navigateToContextSelector(context, contextLoader: contextLoader),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HubSalonScreen(
      service: hubService,
      onNavigateToCatalog: () => navigateToCatalog(context, service: serviceOfferService),
      onNavigateToStaffSchedules: () => navigateToStaffSchedules(context, service: staffScheduleService),
      onNavigateToAgenda: () => navigateToAgenda(
        context,
        agendaService: agendaService,
        reservaService: reservaService,
      ),
      onNavigateToCustomers: () => navigateToCustomerDirectory(
        context,
        service: customerService,
        contextLoader: contextLoader,
      ),
      onNavigateToStaff: () => navigateToStaffDirectory(
        context,
        service: staffService,
        contextLoader: contextLoader,
      ),
      onNavigateToCashDrawer: () => navigateToCashDrawer(
        context,
        cashService: cashService,
        contextLoader: contextLoader,
      ),
      onNavigateToContextSelector: () => navigateToContextSelector(context, contextLoader: contextLoader),
    );
  }
}
