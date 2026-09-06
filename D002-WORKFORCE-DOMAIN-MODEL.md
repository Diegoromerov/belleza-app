# D-002 WORKFORCE DOMAIN MODEL

## CURRENT MODEL (PRE-D-002)

Based on the codebase and schema, the current model includes:

### Tenant
- Represents a salón/negocio that uses the SaaS.
- Implemented via D-001: `tenants` table with `id`, `name`, `slug`.
- Each tenant has isolated data via `tenant_id` column and RLS.

### User
- Represents a person with authentication in the system.
- Table: `usuarios`
- Fields: `id`, `email`, `nombre`, `foto_url`, `auth_provider`, `provider_id`, `password_hash`, `phone`, `rol` (tipo_rol: CLIENTE or PRESTADOR), `onboarding_completo`, `is_active`, `habeas_data_accepted_at`, `creado_en`.
- The `rol` field determines if the user is a client or a service provider (prestador).
- Authentication is handled via local email/password or OAuth (Google, Outlook).
- The tenant context middleware sets `app.tenant_id` based on `req.user.tenant_id` (which is populated from the `usuarios` table via a join or direct column? Actually, the `usuarios` table has a `tenant_id` column after D-001 implementation).

### Professional / Prestador
- A user with `rol = PRESTADOR` is considered a service provider.
- Additional profile information is stored in `perfiles_prestador` table, which has a foreign key to `usuarios.id`.
- Fields in `perfiles_prestador`: `business_name`, `description`, `is_online`, `ubicacion` (geography), `portafolio_servicios` (JSONB), `documento_id_url`, `rut_url`, `certificacion_url`, `estatus_verificacion`, `rating_avg`, etc.
- The prestador is associated with a tenant via the `usuarios.tenant_id` column (set during onboarding or via backfill).

### Client
- A user with `rol = CLIENTE`.
- No additional profile table; client information is stored directly in `usuarios`.

### Administrator
- The system references an 'admin' role in the JWT utility (`toApiRole` function) and in controllers (e.g., `disputeController.js` checks for `req.user.role === 'admin'`).
- However, the `usuarios.rol` column is of type `tipo_rol` which only accepts 'CLIENTE' or 'PRESTADOR'. Therefore, the admin role is not stored in the `rol` column. It is likely determined by other means, such as:
  - A flag in a separate table (e.g., `admin_mfa` suggests there is an admin concept).
  - Perhaps the admin is a user with a special `tenant_id` or a special provider_id.
  - Or the admin role is derived from being the owner of the tenant (maybe the first user in a tenant).
- The `admin_mfa` table exists for multi-factor authentication for administrators, indicating that there is an admin concept separate from regular users.

### Services
- Table: `services` (note: the schema uses `services` but the code may refer to `servicios`; we saw both).
- This table likely contains services offered by the salón or by prestadores.
- We need to check if services are tied to a specific prestador or to the tenant.

### Bookings
- Table: `bookings`
- Likely represents appointments between a client and a prestador.
- We need to see if bookings reference a specific prestador.

## PROPOSED MODEL FOR D-002 (WORKFORCE EXPANSION)

If GlowApp decides to incorporate employee management, the following changes or additions may be considered:

### Employee Entity
- A new table `employees` or a new role type in `tipo_rol` (e.g., 'EMPLEADO').
- Alternatively, employees could be represented as users with `rol = PRESTADOR` but with an additional flag or profile indicating employment status.
- Attributes specific to employees: employment contract type, salary, role (e.g., receptionist, assistant), work schedule, start date, end date, manager, etc.

### Distinction Between Independent Contractor and Employee
- Independent contractors (current prestadores) may have different tax implications, benefits, and labor rights.
- The system may need to distinguish between:
  - Prestador as independent contractor (current model)
  - Empleado as worker with labor contract
- This could be done via:
  - A new column in `usuarios` or `perfiles_prestador` indicating worker type (e.g., `worker_type`: INDEPENDENTE, EMPLEADO)
  - Separate tables for independent contractor profile and employee profile.

### Tenant Owner/Administrator
- Currently, there is no explicit role for the owner or administrator of the tenant.
- The admin role appears to be used for system administration (e.g., managing MFA, perhaps super-admin).
- For salon-level administration (e.g., managing the salón's settings, managing other users within the tenant), there may be a need for a role like 'salon_admin' or 'manager'.
- This could be a role within the tenant, separate from the system admin.

### Workforce Management Features
- If employees are to be managed, the system may need to track:
  - Work schedules and shifts
  - Time off requests
  - Performance evaluations
  - Payroll integration (though not necessarily processing payroll, but providing data for it)
  - Training and certifications

### Impact on Existing Concepts
- The current `prestador` concept may be sufficient to represent both independent contractors and employees if we add attributes to differentiate them.
- Alternatively, we may need to split the concept:
  - `Professional`: anyone who provides beauty services (could be independent or employee)
  - `Employee`: anyone employed by the salón (may or may not provide services)
  - `Contractor`: independent professional who provides services via the platform

### Relationships
- All workforce-related entities (owners, administrators, professionals, employees) would belong to a tenant (via `tenant_id`).
- Services could be associated with specific professionals (whether independent or employee).
- Bookings could be associated with a specific professional and a client.

## RECOMMENDATION FOR MODELING

Given the current architecture, the least invasive way to introduce workforce concepts is to:
1. Add a `worker_type` column to the `usuarios` table (or to a new profile table) with values: INDEPENDENTE (current prestador), EMPLEADO, ADMIN_SALON (salon administrator), etc.
2. Keep the existing `rol` column for client vs. service provider distinction (CLIENTE vs. PRESTADOR).
3. Introduce a new role for salon-level administration if needed, possibly via a separate table or a flag.
4. Ensure that all workforce-related tables include `tenant_id` for multi-tenancy isolation.

This approach allows the system to evolve without breaking existing data and keeps the core tenant isolation intact.

## OPEN QUESTIONS
- How is the salon owner/administrator currently represented? Is it the first user created in the tenant? Or is there a separate entity?
- What specific workforce features are salons expecting? (e.g., just scheduling employees, or also payroll, benefits, etc.)
- How does the current commission model relate to workers? Are commissions only for independent contractors, or do employees also earn commissions?