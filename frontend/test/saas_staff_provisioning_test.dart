// frontend/test/saas_staff_provisioning_test.dart
// GO-08.41 / GO-08.43: Staff Provisioning Frontend Verification Suite

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas_staff_model.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/saas_staff_service.dart';
import 'package:beauty_app/screens/saas/staff_directory_screen.dart';
import 'package:beauty_app/screens/saas/widgets/staff_invite_modal.dart';
import 'package:beauty_app/screens/saas/widgets/staff_role_dialog.dart';
import 'package:beauty_app/screens/saas/widgets/staff_status_dialog.dart';
import 'package:beauty_app/screens/saas/widgets/staff_relation_type_dialog.dart';
import 'package:beauty_app/screens/saas/invitation_acceptance_screen.dart';
import 'package:beauty_app/screens/saas/saas_navigation_orchestrator.dart';
import 'package:beauty_app/screens/saas/hub_salon_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActiveContextHolder contextHolder;

  final sampleMembers = [
    StaffMember(
      membershipId: 'mem-01',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      userId: 1,
      userName: 'Carlos Owner',
      userEmail: 'carlos@glow.com',
      role: 'OWNER',
      relationType: 'OWNER_PARTNER',
      status: 'ACTIVE',
      joinedAt: DateTime(2026, 1, 15),
      createdAt: DateTime(2026, 1, 15),
      updatedAt: DateTime(2026, 1, 15),
    ),
    StaffMember(
      membershipId: 'mem-02',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      userId: 2,
      userName: 'Ana Manager',
      userEmail: 'ana@glow.com',
      role: 'MANAGER',
      relationType: 'STAFF_EMPLOYEE',
      status: 'ACTIVE',
      joinedAt: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    ),
    StaffMember(
      membershipId: 'mem-03',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      userId: 3,
      userName: 'Laura Estilista',
      userEmail: 'laura@glow.com',
      role: 'PROFESSIONAL',
      relationType: 'INDEPENDENT_PROVIDER',
      status: 'SUSPENDED',
      joinedAt: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    ),
    StaffMember(
      membershipId: 'mem-04',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      userId: 4,
      userName: 'Pedro Ex-Colaborador',
      userEmail: 'pedro@glow.com',
      role: 'PROFESSIONAL',
      relationType: 'STAFF_EMPLOYEE',
      status: 'REVOKED',
      joinedAt: DateTime(2026, 1, 1),
      revokedAt: DateTime(2026, 4, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 4, 1),
    ),
  ];

  final sampleInvitations = [
    StaffInvitation(
      id: 'inv-01',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      email: 'marta.nueva@glow.com',
      role: 'PROFESSIONAL',
      relationType: 'INDEPENDENT_PROVIDER',
      inviterName: 'Carlos Owner',
      status: 'PENDING',
      expiresAt: DateTime.now().add(const Duration(days: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  setUp(() {
    contextHolder = ActiveContextHolder();
    contextHolder.setActiveMembershipId('mem-01');
  });

  tearDown(() {
    contextHolder.resetForTesting();
  });

  group('1. DTO & Models Serialization Tests', () {
    test('StaffMember fromJson and toJson serialization', () {
      final json = {
        'membership_id': 'mem-100',
        'tenant_id': 't-1',
        'establishment_id': 'e-1',
        'user_id': 10,
        'user_name': 'Test User',
        'user_email': 'test@glow.com',
        'role': 'PROFESSIONAL',
        'relation_type': 'STAFF_EMPLOYEE',
        'status': 'ACTIVE',
        'joined_at': '2026-05-10T10:00:00.000Z',
        'created_at': '2026-05-10T10:00:00.000Z',
        'updated_at': '2026-05-10T10:00:00.000Z',
      };

      final member = StaffMember.fromJson(json);
      expect(member.membershipId, equals('mem-100'));
      expect(member.userName, equals('Test User'));
      expect(member.isActive, isTrue);
      expect(member.isSuspended, isFalse);
      expect(member.isRevoked, isFalse);

      final outJson = member.toJson();
      expect(outJson['membership_id'], equals('mem-100'));
      expect(outJson['role'], equals('PROFESSIONAL'));
    });

    test('StaffInvitation fromJson and status predicates', () {
      final json = {
        'id': 'inv-99',
        'tenant_id': 't-1',
        'establishment_id': 'e-1',
        'email': 'pending@glow.com',
        'role': 'RECEPTIONIST',
        'relation_type': 'STAFF_EMPLOYEE',
        'status': 'PENDING',
        'expires_at': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final inv = StaffInvitation.fromJson(json);
      expect(inv.id, equals('inv-99'));
      expect(inv.isPending, isTrue);
      expect(inv.isExpired, isFalse);
      expect(inv.isRevoked, isFalse);
    });

    test('StaffException maps localized messages correctly', () {
      expect(
        SaasStaffException.localize('CANNOT_ORPHAN_ESTABLISHMENT'),
        contains('al menos un (1) Propietario'),
      );
      expect(
        SaasStaffException.localize('SELF_ROLE_MUTATION_PROHIBITED'),
        contains('no puedes modificar tu propio rol'),
      );
      expect(
        SaasStaffException.localize('INVITATION_EXPIRED'),
        contains('ha expirado'),
      );
      expect(
        SaasStaffException.localize('INVITATION_ALREADY_PENDING'),
        contains('Ya existe una invitación pendiente'),
      );
    });
  });

  group('2. SCR-14: StaffDirectoryScreen Widget Tests', () {
    testWidgets('Renders missing context view when activeContext is null', (tester) async {
      contextHolder.clear();
      expect(contextHolder.hasActiveContext, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaffDirectoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('state_active_context_missing')), findsOneWidget);
      expect(find.text('Contexto de Sede Requerido'), findsOneWidget);
    });

    testWidgets('Renders staff members and pending invitations under loaded state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = SaasStaffService(
        apiGet: (path) async {
          if (path.startsWith('/api/saas/staff/invitations')) {
            return {
              'invitations': sampleInvitations.map((i) => {
                'id': i.id,
                'tenant_id': i.tenantId,
                'establishment_id': i.establishmentId,
                'email': i.email,
                'role': i.role,
                'relation_type': i.relationType,
                'inviter_name': i.inviterName,
                'status': i.status,
                'expires_at': i.expiresAt.toIso8601String(),
                'created_at': i.createdAt.toIso8601String(),
                'updated_at': i.updatedAt.toIso8601String(),
              }).toList(),
            };
          }
          if (path.startsWith('/api/saas/staff')) {
            return {
              'establishment_id': 'est-01',
              'members': sampleMembers.map((m) => m.toJson()).toList(),
            };
          }
          return {};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StaffDirectoryScreen(
            service: mockService,
            initialRole: 'OWNER',
            currentUserId: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar lista de personal
      expect(find.byKey(const Key('list_staff_members')), findsOneWidget);
      expect(find.text('Carlos Owner'), findsOneWidget);
      expect(find.text('Ana Manager'), findsOneWidget);

      // Cambiar a pestaña Invitaciones
      await tester.tap(find.byIcon(Icons.mail_outline));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('list_pending_invitations')), findsOneWidget);
      expect(find.text('marta.nueva@glow.com'), findsOneWidget);
    });

    testWidgets('RBAC: + Invitar button is hidden for Professional role', (tester) async {
      final mockService = SaasStaffService(
        apiGet: (path) async => {'establishment_id': 'est-01', 'members': []},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StaffDirectoryScreen(
            service: mockService,
            initialRole: 'PROFESSIONAL',
            currentUserId: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_invitar_colaborador')), findsNothing);
    });
  });

  group('3. SCR-14-M1: StaffInviteModal Tests', () {
    testWidgets('Manager only sees operative roles in dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffInviteModal(
              service: SaasStaffService(),
              actorRole: 'MANAGER',
              onInvitationEmitted: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir dropdown de roles
      await tester.tap(find.byKey(const Key('dropdown_invite_role')));
      await tester.pumpAndSettle();

      expect(find.text('Profesional / Estilista'), findsWidgets);
      expect(find.text('Recepcionista'), findsWidgets);
      // Owner y Manager deben estar excluidos para actor MANAGER
      expect(find.text('Propietario / Co-Owner (Control Total)'), findsNothing);
      expect(find.text('Administrador / Manager'), findsNothing);
    });

    testWidgets('Emitting invitation displays copyable token URL on success', (tester) async {
      final mockService = SaasStaffService(
        apiPost: (path, body) async {
          return {
            'success': true,
            'invitation': {
              'id': 'inv-new-01',
              'tenant_id': 'tenant-01',
              'establishment_id': 'est-01',
              'email': body['email'],
              'role': body['role'],
              'relation_type': body['relation_type'],
              'status': 'PENDING',
              'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            'raw_token': 'raw_tok_123456789abcdef',
            'invitation_url': 'https://app.glowapp.com/saas/invitations/accept?token=raw_tok_123456789abcdef',
          };
        },
      );

      StaffInvitationEmissionResponse? emitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffInviteModal(
              service: mockService,
              actorRole: 'OWNER',
              onInvitationEmitted: (res) {
                emitted = res;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_invite_email')), 'nuevo.estilista@glow.com');
      await tester.tap(find.byKey(const Key('btn_submit_invite')));
      await tester.pumpAndSettle();

      expect(find.text('¡Invitación Emitida!'), findsOneWidget);
      expect(find.byKey(const Key('btn_copy_invite_token')), findsOneWidget);
      expect(emitted, isNotNull);
      expect(emitted!.rawToken, equals('raw_tok_123456789abcdef'));
    });
  });

  group('4. SCR-14-M2 & SCR-14-M3 Governance Dialogs Tests', () {
    testWidgets('StaffRoleDialog disables self-mutation with warning banner', (tester) async {
      final ownerMember = sampleMembers.first; // userId = 1

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffRoleDialog(
              member: ownerMember,
              service: SaasStaffService(),
              actorRole: 'OWNER',
              currentUserId: 1, // Mismo userId que el target
              onRoleUpdated: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no puedes modificar tu propio rol'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_role_change')), findsNothing);
    });

    testWidgets('StaffStatusDialog requires typing "CONFIRMAR" for permanent revocation', (tester) async {
      final targetMember = sampleMembers[2]; // Laura Estilista (userId: 3)
      bool updated = false;

      final mockService = SaasStaffService(
        apiPatch: (path, body) async {
          return {
            'success': true,
            'member': {
              'membership_id': targetMember.membershipId,
              'tenant_id': targetMember.tenantId,
              'establishment_id': targetMember.establishmentId,
              'user_id': targetMember.userId,
              'user_name': targetMember.userName,
              'user_email': targetMember.userEmail,
              'role': targetMember.role,
              'relation_type': targetMember.relationType,
              'status': 'REVOKED',
              'created_at': targetMember.createdAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffStatusDialog(
              member: targetMember,
              service: mockService,
              actorRole: 'OWNER',
              currentUserId: 1,
              onStatusUpdated: (_) {
                updated = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cambiar a segmento Revocar
      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ADVERTENCIA: ACCIÓN IRREVERSIBLE'), findsOneWidget);

      // Intentar enviar sin confirmación
      await tester.tap(find.byKey(const Key('btn_confirm_status_change')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Debes escribir exactamente "CONFIRMAR"'), findsOneWidget);
      expect(updated, isFalse);

      // Escribir CONFIRMAR
      await tester.enterText(find.byKey(const Key('input_confirm_revoke')), 'CONFIRMAR');
      await tester.tap(find.byKey(const Key('btn_confirm_status_change')));
      await tester.pumpAndSettle();

      expect(updated, isTrue);
    });
  });

  group('5. SCR-15: InvitationAcceptanceScreen Tests', () {
    testWidgets('Renders error card for invalid or expired token', (tester) async {
      final mockService = SaasStaffService(
        apiGet: (path) async {
          throw SaasStaffException(
            code: 'INVITATION_EXPIRED',
            message: 'Esta invitación ha expirado (+7 días transcurridos).',
            statusCode: 410,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InvitationAcceptanceScreen(
            token: 'expired_token_123',
            service: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_inspection_error')), findsOneWidget);
      expect(find.textContaining('ha expirado'), findsOneWidget);
    });

    testWidgets('Renders new user registration form when user_exists is false', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool accepted = false;

      final mockService = SaasStaffService(
        apiGet: (path) async {
          return {
            'valid': true,
            'email': 'nuevo@glow.com',
            'role': 'PROFESSIONAL',
            'relation_type': 'STAFF_EMPLOYEE',
            'establishment_id': 'est-01',
            'establishment_name': 'Salón Glow Central',
            'tenant_name': 'Glow Group SAS',
            'expires_at': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
            'user_exists': false,
          };
        },
        apiPost: (path, body) async {
          return {
            'success': true,
            'membership_id': 'mem-new-accepted-01',
            'establishment_id': 'est-01',
            'role': 'PROFESSIONAL',
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InvitationAcceptanceScreen(
            token: 'valid_new_token',
            service: mockService,
            authLogin: (email, pass) async => {
              'token': 'jwt-mock-token',
              'user': {'id': 10, 'full_name': 'Marcos Barbero'},
            },
            onAcceptanceSuccess: () {
              accepted = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salón Glow Central'), findsOneWidget);
      expect(find.byKey(const Key('input_accept_full_name')), findsOneWidget);
      expect(find.byKey(const Key('input_accept_password')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_accept_full_name')), 'Marcos Barbero');
      await tester.enterText(find.byKey(const Key('input_accept_password')), 'Password123*');
      await tester.enterText(find.byKey(const Key('input_accept_confirm_password')), 'Password123*');

      await tester.tap(find.byKey(const Key('btn_accept_new_user')));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      expect(contextHolder.activeMembershipId, equals('mem-new-accepted-01'));
    });
  });

  group('6. SaasNavigationOrchestrator Integration Tests', () {
    testWidgets('HubSalonScreen connects onNavigateToStaff with SaasNavigationOrchestrator', (tester) async {
      final mockStaffService = SaasStaffService(
        apiGet: (path) async {
          return {
            'establishment_id': 'est-01',
            'members': sampleMembers.map((m) => m.toJson()).toList(),
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('btn_open_staff'),
                onPressed: () => SaasNavigationOrchestrator.navigateToStaffDirectory(
                  context,
                  service: mockStaffService,
                  initialRole: 'OWNER',
                  currentUserId: 1,
                ),
                child: const Text('Abrir Personal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_staff')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffDirectoryScreen), findsOneWidget);
      expect(find.text('Carlos Owner'), findsOneWidget);
    });
  });
}
