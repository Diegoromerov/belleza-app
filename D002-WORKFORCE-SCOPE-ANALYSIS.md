# D-002 WORKFORCE SCOPE ANALYSIS

## EVIDENCE FOUND

- No references to "employee", "staff", or "empleado" in the codebase (search in backend/src and schema.sql).
- The schema defines a `tipo_rol` ENUM with values 'CLIENTE' and 'PRESTADOR'.
- The `perfiles_prestador` table exists and is linked to `usuarios` via `provider_id`.
- The `usuarios` table contains fields for authentication and basic profile.
- There is a table `profesionales_medicos` referenced in designsController.js, but this appears to be for a medical professional context (maybe a different module).
- The system currently distinguishes between clients and service providers (prestadores).
- There is no explicit concept of an employee separate from a prestador or user.
- The JWT configuration includes a role mapping that can return 'admin' for dbRole 'ADMIN', indicating that the system already has an admin role concept, though the `tipo_rol` enum does not currently include 'ADMIN'. This suggests that the admin role is handled via application logic (e.g., in `toApiRole` function) but not stored in the `usuarios.rol` column as a defined enum value. However, the `usuarios.rol` column is of type `tipo_rol` which only accepts 'CLIENTE' or 'PRESTADOR'. The `toApiRole` function maps 'ADMIN' from dbRole, but since the column cannot store 'ADMIN', this mapping is likely unused or the column is intended to be changed.

## ANALYSIS

The current system supports:
- Tenants (salones) via D-001 multi-tenancy.
- Users that can be either CLIENTE or PRESTADOR.
- A prestador is a service provider that belongs to a tenant (via the user's tenant_id, which is set through tenantContext middleware).
- The prestador can have a profile (perfiles_prestador) that includes location, etc.
- There is an admin role referenced in the JWT utility and in controllers (e.g., disputeController.js checks for `req.user.role === 'admin'`), but the database schema does not currently support storing 'ADMIN' in the `rol` column. This indicates that the admin role is likely derived from other criteria (e.g., a flag in a separate table or a special tenant_id) or the schema is incomplete.

There is no distinction between:
- Owner/administrator of the tenant and a prestador.
- A prestador that is an independent contractor vs. an employee.

All prestadores are treated equally in terms of tenant association (they have a tenant_id).

## QUESTIONS

1. Should the system differentiate between a tenant owner/administrator and a prestador?
2. Should the system support the concept of an employee (with labor relations) separate from a prestador (independent contractor)?
3. If employees are to be supported, what attributes are needed (e.g., employment contract, salary, role, schedule, etc.)?
4. How should the admin role be properly represented in the system?

## CONCLUSION BASED ON EVIDENCE

Currently, GlowApp does not have an employee concept. The decision D-002 is about whether to introduce such a concept.

The system already has a latent admin role concept that is not fully integrated into the schema. This presents an opportunity to formalize roles without necessarily introducing an employee entity, depending on the decision.

## RECOMMENDATION FOR FURTHER ANALYSIS

To properly answer D-002, we need to examine:
- The existing usage of roles in controllers (auth, booking, dispute, etc.)
- The tenant context middleware to see how tenant_id is associated with users.
- Any existing concepts of professional vs. employee in the business logic (e.g., in commission calculations, booking assignments).
- The frontend to see what user interfaces exist for managing professionals.

This analysis will inform whether the current prestador concept can be extended to cover both independent contractors and employees, or whether a separate employee entity is needed.