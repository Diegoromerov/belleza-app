# NODO-04 — PHYSICAL ARCHITECTURE DISCOVERY REPORT v1.0
## DOWNSTREAM B2C MATERIALIZATION ADAPTER — PHYSICAL DISCOVERY & DESIGN

**DOCUMENT ID**: `ARCH-DISCOVERY-N04-PHYSICAL-01`  
**NODE**: `NODO-04 (Downstream B2C Materialization Adapter)`  
**DATE**: 2026-09-11  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**GOAL ORIGIN**: `GO — NODO-04-PHYSICAL-ARCHITECTURE-DISCOVERY-01`  
**STATUS**: `PHYSICAL ARCHITECTURE DISCOVERY COMPLETE — READY FOR DIRECTOR REVIEW 🟡`  
**IMPLEMENTATION AUTHORIZATION**: `NOT GRANTED 🔴`

---

## 1. ESTADO DE PARTIDA (BASELINE CONTEXT)

El presente informe de descubrimiento físico se fundamenta en las decisiones y contratos arquitectónicos cerrados y ratificados:

- **NODO-04 Node Contract v1.0**: `CONTRACT APPROVED / CLOSED 🔒` (Mandato canónico de adaptador downstream sin automatismos).
- **DEC-AS-003**: `APPROVED / CLOSED 🔒` (Acto explícito de autorización emitido por `OWNER` / `MANAGER` en Active Context).
- **NODO-03A**: `CLOSED / RATIFIED 🔒` (Disponibilidad operativa y schedules semanales del staff en PostgreSQL).
- **NODO-02**: `CLOSED / RATIFIED 🔒` (`service_offers` y `service_assignments` durables).
- **NODO-01 / Foundation Core (065, 066)**: `CLOSED 🔒` (`tenants`, `establishments`, `memberships`, `usuarios`, `activeContextMiddleware`).
- **DEC-AS-001 a DEC-AS-014, DEC-SE-001, DEC-SE-002, DEC-PUB-001**: Ratificados y vigentes.

> **Principio Metodológico:**  
> Se separa estrictamente la **EVIDENCIA FÍSICA (FACT)** de la **DEDUCCIÓN LÓGICA (INFERENCE)** y de las **PROPUESTAS DE DISEÑO (PROPOSAL — NOT APPROVED)**.

---

## 2. SCOPE (ALCANCE DE LA INVESTIGACIÓN FÍSICA)

La investigación física abarca exclusivamente cuatro áreas técnicas delimitadas:
1. **Área A — Provider Boundary**: Relación física y estructural entre las identidades SaaS (`usuarios`, `memberships`, `service_assignments`) y las entidades B2C (`perfiles_prestador`, `public.services`).
2. **Área B — Provider Provisioning / Reuse**: Comportamiento físico y ciclo de vida de `perfiles_prestador` ante colaboradores SaaS que carecen de registro previo.
3. **Área C — Materialization Persistence & Idempotency**: Mecánica física de persistencia en `public.services`, gaps de rastreo de origen y deduplicación / idempotencia.
4. **Área D — Transport, Transaction Boundary & Security / RLS**: Patrones de transporte HTTP/Service, delimitación atómica transaccional y compatibilidad de seguridad RLS con el usuario de base de datos runtime (`beauty_app_user`).

---

## 3. EVIDENCE INVENTORY (INVENTARIO DE EVIDENCIA EMPÍRICA)

Se realizaron consultas forenses READ-ONLY contra el catálogo de PostgreSQL (`beauty_db`) y el código fuente del backend.

### 3.1. Tablas Involucradas y Esquemas Físicos

| Tabla | Dominio | Primary Key | Llaves Foráneas Relevantes | RLS |
|---|---|---|---|---|
| `usuarios` | Core / Auth | `id (int)` | `tenant_id -> tenants(id)` | Sí |
| `perfiles_prestador` | B2C Prestador | `id (int)` | `id -> usuarios(id) ON DELETE CASCADE` | Sí |
| `services` | B2C Catálogo | `id (uuid)` | `provider_id -> perfiles_prestador(id) ON DELETE CASCADE` | Sí |
| `memberships` | SaaS Staff | `id (uuid)` | `(user_id, tenant_id) -> usuarios`, `(establishment_id, tenant_id) -> establishments` | Sí |
| `service_offers` | SaaS Catálogo | `id (uuid)` | `(establishment_id, tenant_id) -> establishments` | Sí |
| `service_assignments` | SaaS Asignación | `(service_offer_id, membership_id)` | `-> service_offers`, `-> memberships` | Sí |
| `bookings` | B2C Reservas | `id (uuid)` | `provider_id -> perfiles_prestador(id)`, `service_id -> services(id)` | Sí |

### 3.2. Constraints y Triggers Verificados

- **`perfiles_prestador`**:
  - PK: `id INT` con `FOREIGN KEY (id) REFERENCES usuarios(id) ON DELETE CASCADE`.
  - Trigger: `trg_crear_wallet AFTER INSERT ON perfiles_prestador FOR EACH ROW EXECUTE FUNCTION crear_wallet_prestador()`.
  - RLS Policy: `tenant_isolation_perfiles_prestador USING (tenant_id = (current_setting('app.tenant_id')::integer))`.
- **`public.services`**:
  - PK: `id UUID DEFAULT gen_random_uuid()`.
  - FK: `FOREIGN KEY (provider_id) REFERENCES perfiles_prestador(id) ON DELETE CASCADE`.
  - Check: `duration_minutes > 0`, `price >= 0`.
  - RLS Policy: `tenant_isolation_services USING (tenant_id = (current_setting('app.tenant_id')::integer))`.
  - Gaps de Constraint: **No existe FK hacia `service_offers` ni constraint UNIQUE sobre `(provider_id, name)` o `(tenant_id, provider_id, ...)`**.

---

## 4. ÁREA A — PROVIDER BOUNDARY

### A.1. Evidencia Encontrada (FACTS)
1. En PostgreSQL, `public.services.provider_id` es de tipo `INTEGER` y tiene una restricción de integridad referencial estricta:
   ```sql
   FOREIGN KEY (provider_id) REFERENCES perfiles_prestador(id) ON DELETE CASCADE
   ```
2. `public.perfiles_prestador.id` es de tipo `INTEGER` y es una relación 1:1 con `public.usuarios.id`:
   ```sql
   FOREIGN KEY (id) REFERENCES usuarios(id) ON DELETE CASCADE
   ```
3. En el dominio SaaS, `memberships.user_id` es de tipo `INTEGER` y referencia a `public.usuarios(id, tenant_id)`.
4. En el dominio SaaS, `service_assignments` vincula `(service_offer_id UUID, membership_id UUID)`.
5. **No existe** ninguna tabla, clave foránea ni columna que vincule directamente `memberships.id` (UUID) con `perfiles_prestador.id` (INT).

```text
service_assignments.membership_id ──► memberships.user_id ──► usuarios.id ≡ perfiles_prestador.id
```
- Un colaborador creado o invitado exclusivamente en el SaaS posee registro en `usuarios` y en `memberships`, pero puede **no existir** en `perfiles_prestador`.

### A.3. Gap Identificado
- Si `NODO-04` intenta insertar una fila en `public.services` con `provider_id = memberships.user_id` sin que exista previamente la fila en `perfiles_prestador`, PostgreSQL aborta la transacción inmediatamente con error de violación de clave foránea (`services_provider_id_fkey`).

---

## 5. ÁREA B — PROVIDER PROVISIONING / REUSE

### B.1. Evidencia Encontrada (FACTS)
1. En `authController.js` (flujo legacy B2C), los prestadores se crean mediante:
   ```sql
   INSERT INTO perfiles_prestador (id, documento_id_url, rut_url, certificacion_url, estatus_verificacion, is_active)
   VALUES ($1, $2, $3, $4, 'PENDIENTE', true)
   ON CONFLICT (id) DO UPDATE ...
   ```
2. Al insertarse una fila en `perfiles_prestador`, el trigger `trg_crear_wallet` inserta automáticamente un registro en `provider_wallet (provider_id)`.
3. Todos los campos de datos de negocio en `perfiles_prestador` (`business_name`, `description`, `ubicacion`, `documento_id_url`, `rut_url`, `certificacion_url`, `pila_soporte_url`) son **NULLABLE**.
4. Las columnas obligatorias (o con default) son:
   - `id INT` (PK)
   - `is_online` (default `false`)
   - `estatus_verificacion` (default `'PENDIENTE'`)
   - `rating_avg` (default `0.0`)
   - `is_active` (default `true`)
   - `metodo_retiro` (default `'NEQUI'`)
   - `tenant_id INT` (nullable físicamente, pero requerido por RLS).

### B.2. Opciones de Diseño Físico Evaluadas

```text
================================================================================
          OPCIONES DE APROVISIONAMIENTO / REUTILIZACIÓN DE PROVIDER
================================================================================

[OPCIÓN B.1: REUSE ONLY (Strict Precondition)]
  • Consulta si existe perfiles_prestador WHERE id = memberships.user_id.
  • Si existe ➔ Reutiliza provider_id.
  • Si NO existe ➔ Rechaza la materialización con MATERIALIZATION_NOT_EXECUTABLE
    (PROVIDER_PROFILE_REQUIRED).
  • Ventaja: Cero mutaciones accesorias en B2C; no crea prestadores fantasma.
  • Desventaja: Requiere que el colaborador complete un flujo de registro B2C previo.

[OPCIÓN B.2: AUTO-PROVISION BASELINE ON-DEMAND]
  • Consulta si existe perfiles_prestador WHERE id = memberships.user_id.
  • Si existe ➔ Reutiliza provider_id.
  • Si NO existe ➔ Inserta un registro base en perfiles_prestador:
    (id = user_id, tenant_id = activeContext.tenant_id, is_active = true)
    dentro de la misma transacción de materialización.
  • Ventaja: Materialización fluida y sin fricción operativa para salones SaaS.
  • Desventaja: Crea un perfil prestador B2C básico que requerirá posterior
    enriquecimiento si se usa en el marketplace público.

[OPCIÓN B.3: DEDICATED PROVISIONING ADAPTER INTERFACE]
  • NODO-04 delega la creación a un sub-servicio de aprovisionamiento explícito.
================================================================================
```

---

## 6. ÁREA C — MATERIALIZATION PERSISTENCE

### C.1. Evidencia Encontrada (FACTS)
1. Esquema de `public.services`:
   - `id`: UUID (PK, default `gen_random_uuid()`).
   - `provider_id`: INTEGER (NOT NULL, FK -> `perfiles_prestador.id`).
   - `name`: VARCHAR(255) (NOT NULL).
   - `description`: TEXT (NULLABLE).
   - `price`: NUMERIC(10,2) (NOT NULL).
   - `duration_minutes`: INTEGER (NOT NULL).
   - `category`: VARCHAR(50) (NULLABLE).
   - `is_active`: BOOLEAN (DEFAULT `true`).
   - `created_at`: TIMESTAMPTZ (DEFAULT `now()`).
   - `tenant_id`: INTEGER (NULLABLE en esquema, protegido por RLS).
2. **GAP CRÍTICO DE PERSISTENCIA**:  
   `public.services` **NO posee ninguna columna** que almacene el `service_offer_id` de origen, ni el `establishment_id`, ni el `membership_id`.
3. Consumidores downstream de `public.services`:
   - `providerController.js` (lee `services` por `provider_id` y `is_active = true`).
   - `bookings` (referencia `service_id -> services(id)` con `ON DELETE RESTRICT`).

### C.2. Estado Actual (INFERENCE)
- Si `NODO-04` proyecta `(service_offer, assignment)` insertando en `public.services` sin una tabla de mapeo o columna de origen:
  1. No es posible saber qué fila de `public.services` corresponde a qué `service_offer_id`.
  2. No es posible actualizar el precio o duración en B2C si la oferta SaaS cambia.
  3. No es posible implementar re-materialización idempotente sin consultar por campos volátiles (`name`, `provider_id`).

---

## 7. IDEMPOTENCIA (ANALYSIS & CANDIDATE MECHANISMS)

### 7.1. Evidencia Encontrada (FACTS)
1. No existe constraint `UNIQUE` en `public.services` sobre combinaciones de `(tenant_id, provider_id, name)`.
2. Una ejecución repetida de `INSERT INTO services ...` con los mismos datos creará múltiples filas con distintos UUIDs en `public.services`.

### 7.2. Opciones Candidatas de Idempotencia (PROPOSALS — NOT APPROVED)

```text
================================================================================
                      OPCIONES FÍSICAS DE IDEMPOTENCIA
================================================================================

[OPCIÓN C.1: DOWNSTREAM MAPPING TABLE (Recomendada - Zero B2C Mutation)]
  • Crear tabla técnica downstream:
    CREATE TABLE saas_service_materializations (
      tenant_id INTEGER NOT NULL,
      establishment_id UUID NOT NULL,
      service_offer_id UUID NOT NULL,
      membership_id UUID NOT NULL,
      provider_id INTEGER NOT NULL,
      service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
      materialized_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (establishment_id, service_offer_id, membership_id),
      UNIQUE (service_id)
    );
  • Idempotencia: Ante una nueva solicitud de materialización para el mismo
    (establishment_id, service_offer_id, membership_id):
    - Si ya existe en la tabla de mapeo ➔ Ejecuta UPDATE en public.services(service_id).
    - Si no existe ➔ Ejecuta INSERT en public.services y registra el mapeo.
  • Impacto en B2C: 0 (No altera la tabla legacy public.services).

[OPCIÓN C.2: SCHEMA EXTENSION ON public.services]
  • Añadir columna: ALTER TABLE services ADD COLUMN source_offer_id UUID;
  • Añadir columna: ALTER TABLE services ADD COLUMN source_membership_id UUID;
  • Añadir UNIQUE constraint: UNIQUE (tenant_id, provider_id, source_offer_id);
  • Impacto en B2C: Altera la tabla central del marketplace legacy.

[OPCIÓN C.3: QUERY-BASED DEDUPLICATION LOOKUP]
  • SELECT id FROM services WHERE provider_id = $1 AND name = $2 AND tenant_id = $3.
  • Fragilidad: Alta ante cambios de nombre o duplicados legítimos.
================================================================================
```

---

## 8. ÁREA D — TRANSPORTE (TRANSPORT PATTERNS)

### 8.1. Evidencia Encontrada (FACTS)
1. El backend GlowApp SaaS utiliza Express.js con una arquitectura estandarizada de 3 capas:
   - **Route Layer**: `router.post('/', authMiddleware, activeContextMiddleware, controllerFn)`
   - **Controller Layer**: Desempaqueta `req.user`, `req.activeContext`, `req.params`, `req.body`, invoca el servicio, maneja códigos HTTP estandarizados (`200`, `201`, `400`, `403`, `404`, `500`).
   - **Service Layer**: Recibe `(tenantId, establishmentId, activeContext, data)`, abre conexión `pool.connect()`, inicia `BEGIN`, fija `set_config('app.tenant_id', ...)` y ejecuta lógica transaccional.
2. Todas las rutas SaaS residen bajo el prefijo canónico `/api/v1/saas/hub/...`.

### 8.2. Propuestas de Transporte (PROPOSAL — NOT APPROVED)

- **Propuesta de Endpoint**:
  ```http
  POST /api/v1/saas/hub/materialization/services
  Headers:
    Authorization: Bearer <jwt>
    x-active-membership-id: <uuid>
  Body:
    {
      "service_offer_id": "<uuid>",
      "membership_id": "<uuid>"  // (Opcional: si se omite, materializa todas las asignaciones de la oferta)
    }
  ```
- **Ruta de Consulta de Estado**:
  ```http
  GET /api/v1/saas/hub/materialization/services
  ```

---

## 9. TRANSACTION BOUNDARY (DELIMITACIÓN TRANSACCIONAL)

### 9.1. Principio de Atomicidad
La operación de materialización en PostgreSQL debe ocurrir dentro de un único bloque transaccional atómico:

```text
================================================================================
                      TRANSACTION BOUNDARY DE NODO-04
================================================================================
BEGIN TRANSACTION;
  1. set_config('app.tenant_id', $tenant_id, true);
  2. SELECT service_offers FOR SHARE / LOCK ... (Verificar existencia y pertenencia)
  3. SELECT memberships FOR SHARE / LOCK ... (Verificar operabilidad status = 'ACTIVE')
  4. SELECT service_assignments ... (Verificar vínculo)
  5. [PROVIDER STEP] Verificar / Resolver perfiles_prestador (id = memberships.user_id)
  6. [MATERIALIZE STEP] INSERT / UPDATE public.services
  7. [MAPPING STEP] INSERT / UPDATE saas_service_materializations
COMMIT;
================================================================================
```

Si cualquier paso falla (ej. FK inexistente, colaborador suspendido, error de validación), se emite `ROLLBACK` completo, garantizando que no queden registros huérfanos en `public.services`.

---

## 10. SEGURIDAD Y RLS (ROW-LEVEL SECURITY)

### 10.1. Evidencia Encontrada (FACTS)
1. El usuario de base de datos runtime `beauty_app_user` posee privilegios completos de `SELECT`, `INSERT`, `UPDATE`, `DELETE` en:
   - `usuarios`
   - `perfiles_prestador`
   - `services`
   - `memberships`
   - `service_offers`
   - `service_assignments`
   - `staff_schedules`
2. Todas estas tablas tienen RLS habilitado con la política:
   ```sql
   USING (tenant_id = current_setting('app.tenant_id')::integer)
   ```
3. `activeContextMiddleware` resuelve y valida el `tenant_id` y `establishment_id` server-side a partir de la sesión autenticada del usuario.

### 10.2. Conclusión de Seguridad
`beauty_app_user` cuenta con la totalidad de permisos físicos requeridos para operar `NODO-04` dentro de PostgreSQL sin necesidad de alterar roles, grants ni crear funciones `SECURITY DEFINER`.

---

## 11. PHYSICAL DEPENDENCY MAP

```text
================================================================================
                    MAPA DE DEPENDENCIAS FÍSICAS DE NODO-04
================================================================================

      [SaaS Active Context] (tenant_id, establishment_id, role, status)
                │
                ▼
     ┌─────────────────────────────────────────────────────────────┐
     │ 1. service_offers (id, base_price, base_duration, name)    │
     │    (FK -> establishments, tenant_id)                        │
     └──────────────────────────────┬──────────────────────────────┘
                                    │
                                    ▼
     ┌─────────────────────────────────────────────────────────────┐
     │ 2. service_assignments (service_offer_id, membership_id)   │
     └──────────────────────────────┬──────────────────────────────┘
                                    │
                                    ▼
     ┌─────────────────────────────────────────────────────────────┐
     │ 3. memberships (id, user_id, status = 'ACTIVE')            │
     │    (FK -> usuarios.id)                                      │
     └──────────────────────────────┬──────────────────────────────┘
                                    │
                                    ▼
     ┌─────────────────────────────────────────────────────────────┐
     │ 4. [FRONTERA] perfiles_prestador (id = memberships.user_id) │
     │    (FK -> usuarios.id)                                      │
     └──────────────────────────────┬──────────────────────────────┘
                                    │
                                    ▼
     ┌─────────────────────────────────────────────────────────────┐
     │ 5. [DESTINO] public.services (id, provider_id, price, ...)  │
     │    (FK -> perfiles_prestador.id)                            │
     └─────────────────────────────────────────────────────────────┘
================================================================================
```

---

## 12. CANDIDATE ARCHITECTURES (ARQUITECTURAS FÍSICAS CANDIDATAS)

### Arquitectura Candidata 1: "Downstream Adapter con Tabla de Mapeo Técnica" (Recomendada)
- **Componentes**:
  - `materializationRoutes.js` + `materializationController.js` + `materializationService.js`.
  - Migración física `070_saas_service_materializations.sql` creando la tabla técnica de mapeo downstream.
  - Resolución de Provider: Reutiliza `perfiles_prestador` si existe; si no existe, aprovisiona registro baseline `(id = user_id, tenant_id, is_active = true)` en la misma transacción.
- **Idempotencia**: Garantizada por `PRIMARY KEY (establishment_id, service_offer_id, membership_id)` en la tabla de mapeo.
- **Impacto B2C**: Cero modificaciones a tablas legacy.

### Arquitectura Candidata 2: "Mutación Directa sobre public.services con Schema Alteration"
- **Componentes**:
  - Altera `public.services` añadiendo columnas `source_offer_id` y `source_membership_id`.
  - Idempotencia vía `UNIQUE (tenant_id, provider_id, source_offer_id)`.
- **Desventaja**: Modifica el esquema central B2C acoplando columnas SaaS en una tabla legacy.

### Arquitectura Candidata 3: "Strict Precondition sin Auto-provisioning"
- **Componentes**:
  - Idéntica a Candidata 1, pero rechaza la materialización con `MATERIALIZATION_NOT_EXECUTABLE` si el usuario no tiene `perfiles_prestador`.
- **Desventaja**: Mayor fricción para salones que incorporan nuevos colaboradores.

---

## 13. COMPARATIVE MATRIX (MATRIZ COMPARATIVA)

| Criterio | Candidata 1 (Mapping Table + Auto-provision) | Candidata 2 (Alter services) | Candidata 3 (Mapping Table + Strict Reject) |
|---|---|---|---|
| **Aislamiento SaaS / B2C** | ⭐⭐⭐⭐⭐ Excelente (Sin tocar B2C) | ⭐⭐ Pobre (Altera B2C) | ⭐⭐⭐⭐⭐ Excelente |
| **Idempotencia Técnica** | ⭐⭐⭐⭐⭐ Clave primaria natural en mapeo | ⭐⭐⭐⭐ Unique constraint | ⭐⭐⭐⭐⭐ Clave primaria en mapeo |
| **Fricción Operativa** | ⭐⭐⭐⭐⭐ Cero fricción (Auto-provision) | ⭐⭐⭐⭐⭐ Cero fricción | ⭐⭐ Alta fricción (Rechazo 400) |
| **Rastreabilidad y Auditoría**| ⭐⭐⭐⭐⭐ Timestamps y vínculos exactos | ⭐⭐⭐ Parcial | ⭐⭐⭐⭐⭐ Timestamps y vínculos exactos |
| **Riesgo de Regresión B2C** | ⭐⭐⭐⭐⭐ Cero riesgo (public.services intacta) | ⭐⭐ Riesgo de impacto en queries legacy | ⭐⭐⭐⭐⭐ Cero riesgo |

---

## 14. ARCHITECTURAL GAPS IDENTIFICADOS

1. **Gap de Vínculo Físico SaaS ➔ B2C**: No existe en el esquema actual ninguna columna ni tabla que vincule `service_offers` con `services`. Requiere la creación de la tabla técnica downstream de mapeo (`saas_service_materializations`).
2. **Gap de Preexistencia de `perfiles_prestador`**: Colaboradores creados en SaaS carecen de fila en `perfiles_prestador`. Requiere definir la política física oficial (Auto-provisioning baseline vs Strict Precondition).

---

## 15. DECISIONES REQUERIDAS DEL DIRECTOR (DECISIONS REQUIRED)

Para proceder a la fase de **Architectural Bundle Físico / Implementation Contract**, el Director debe decidir sobre:

1. **Decisión Física 1 (Provider Policy)**:  
   ¿Debe NODO-04 aprovisionar automáticamente un registro baseline en `perfiles_prestador` para `memberships.user_id` si no existe al momento de materializar (**Opción B.2**), o debe rechazar la materialización exigiendo registro previo (**Opción B.1**)?
2. **Decisión Física 2 (Modelo de Mapeo e Idempotencia)**:  
   ¿Se aprueba el modelo de **Tabla Técnica de Mapeo Downstream** (`saas_service_materializations`) para garantizar idempotencia y trazabilidad sin alterar el esquema de `public.services` (**Opción C.1**)?
3. **Decisión Física 3 (Granularidad del Comando de Transporte)**:  
   ¿El endpoint de materialización debe permitir materializar por oferta individual (`service_offer_id`), por asignación específica (`service_offer_id` + `membership_id`), o por lote completo de sede?

---

## 16. RECOMENDACIÓN TÉCNICA

Se recomienda formalmente la adopción de la **Arquitectura Candidata 1**:
1. **Creación de `saas_service_materializations`**: Aísla completamente la relación SaaS → B2C, garantiza idempotencia estricta a nivel de base de datos y mantiene inalterado el esquema físico legacy de `public.services`.
2. **Auto-provisioning Baseline de `perfiles_prestador`**: Permite que cualquier colaborador con membresía activa y asignación válida en el SaaS sea materializado como prestador en B2C de forma transparente y consistente dentro de la misma transacción.
3. **Comando de Materialización Unidireccional en `/api/v1/saas/hub/materialization`**: Mantiene consistencia total con los patrones de Express, `activeContextMiddleware`, transacciones atómicas y seguridad RLS existentes.

---

## 17. NON-SCOPE (FUERA DE ALCANCE)

Se ratifica que permanecen estrictamente fuera de este reporte y de NODO-04:
- Bookings, citas y reservas (`public.reservas`, `public.bookings`).
- Lifecycle de publicación o activación en marketplace B2C.
- Sincronización inversa o bidireccional B2C → SaaS.
- Gestión o mutación de tablas de nodos cerrados (`065`, `066`, `067`, `068`, `069`).

---

## 18. VALIDACIÓN DE NO-MUTACIÓN

```text
================================================================================
                    VALIDACIÓN DE NO-MUTACIÓN FÍSICA
================================================================================
ARCHIVOS DE CÓDIGO MODIFICADOS:     0
ARCHIVOS DE MIGRACIÓN CREADOS:      0
TABLAS O VISTAS MUTADAS:            0
NODOS CERRADOS MODIFICADOS:         0
FRONTEND MODIFICADO:                0
================================================================================
```

---

## 19. ESTADO DE AUTORIZACIÓN DE IMPLEMENTACIÓN

```text
================================================================================
PHYSICAL ARCHITECTURE DISCOVERY COMPLETE 🟡
READY FOR DIRECTOR ARCHITECTURE REVIEW & PHYSICAL DECISIONS
IMPLEMENTATION AUTHORIZATION: NOT GRANTED 🔴
================================================================================
```
