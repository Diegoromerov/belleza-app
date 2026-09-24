# NODO-06 — PHYSICAL ARCHITECTURE SPECIFICATION v1.1
## SaaS Internal Appointments & Operational Agenda Engine

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-06  
NODE NAME: SaaS Internal Appointments & Operational Agenda Engine  
CORPUS / REPOSITORY: Diegoromerov/belleza-app  
WORKTREE: `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\database_audit_read_only`  
CLASSIFICATION: FORMAL PHYSICAL ARCHITECTURE RECONCILIATION — ZERO IMPLEMENTATION  
BASELINE: NODO-06 NODE CONTRACT v1.0 APPROVED / DISCOVERY v1.0 REVIEWED  
STATUS: ARCHITECTURAL STOP — DECISION REQUIRED 🛑  
================================================================================

---

## 1. RECONCILIACIÓN FORENSE DE BLOQUEADORES ARQUITECTÓNICOS

---

### BLOQUEADOR 1 — CONCURRENCIA CROSS-TABLE (`saas_appointments` vs `public.bookings`)

```
================================================================================
           DICTAMEN FORENSE DE CONCURRENCIA CROSS-TABLE Y LÍMITES FÍSICOS
================================================================================

PROBLEMA:
Determinar si NODO-06 puede garantizar físicamente y a nivel de motor de base de datos
la exclusión mutua de agenda (cero doble ocupación) bajo concurrencia real entre:
  (A) Citas SaaS internas ('saas_appointments')
  (B) Reservas B2C Marketplace existentes ('public.bookings')
manteniendo la tabla 'public.bookings' y los endpoints marketplace 100% INTACTOS.

EVIDENCIA TÉCNICA Y FÍSICA:
1. 'saas_appointments' y 'public.bookings' son dos tablas físicamente independientes.
2. La restricción 'EXCLUDE USING gist' en PostgreSQL es estrictamente INTRA-TABLA.
   PostgreSQL NO permite construir restricciones de exclusión declarativas cross-table.
3. En PostgreSQL, un 'SELECT ... FROM bookings' dentro de una transacción 'READ COMMITTED'
   o 'REPEATABLE READ' NO bloquea inserciones concurrentes de nuevas filas en 'public.bookings'.
4. Un 'SELECT ... FOR UPDATE' sobre 'public.bookings' solo bloquea filas YA EXISTENTES;
   no previene la inserción concurrente de una nueva reserva B2C en el mismo slot.
5. Los bloqueos consultivos ('pg_advisory_xact_lock') o bloqueos de fila en 'usuarios'
   requieren OBLIGATORIAMENTE que el motor de reservas B2C marketplace existente
   adquiera el mismo lock bajo el mismo protocolo. Dado que 'public.bookings' y su
   código legacy permanecen INTACTOS y fuera del alcance de este GO, el flujo B2C
   no adquiere dichos locks.
6. El aislamiento 'SERIALIZABLE' en NODO-06 solo detecta anomalías si la transacción
   concurrente externa también participa en el grafo de dependencias SSI. Si el backend
   B2C opera en 'READ COMMITTED', no se previene la inserción concurrente.

DICTAMEN FÍSICO CONCLUYENTE:
¿Puede NODO-06 garantizar físicamente exclusión mutua SaaS vs public.bookings
bajo concurrencia real sin modificar public.bookings ni el motor B2C?

---> RESPUESTA: NO. FÍSICAMENTE IMPOSIBLE A NIVEL DE MOTOR DB UNILATERAL. <---

IMPACTO:
- La garantía FÍSICA Y MATEMÁTICA de exclusión mutua (a nivel motor) existe ÚNICAMENTE
  para concurrencia intra-SaaS ('saas_appointments' <-> 'saas_appointments').
- Para 'public.bookings', NODO-06 solo puede ofrecer una garantía TRANSACCIONAL OPTIMISTA
  (Pre-Check en NODO-05 + lectura en transacción). Existe una ventana de carrera crítica
  si un cliente B2C y una recepcionista SaaS intentan reservar el mismo milisegundo exacto.

OPCIONES DE ARQUITECTURA:
- Opción A: Modelo Híbrido Asimétrico (Recomendado para NODO-06):
  * SaaS vs SaaS: Garantizado 100% FÍSICAMENTE mediante 'EXCLUDE USING gist'.
  * SaaS vs B2C: Coordinación transaccional optimista (Pre-Check NODO-05 + SELECT).
  * Frontera: Aceptar formalmente que la exclusión mutua cross-table absoluta requiere
    unificar ambos motores en un futuro hito de convergencia (ej. NODO-05 v1.1 / Unified Booking Bridge).
- Opción B: Modificación del Motor B2C Marketplace:
  * Alterar el código legacy de creación de reservas B2C para consultar 'saas_appointments'
    o compartir un Advisory Lock en PostgreSQL. (Requiere violar la inmutabilidad de B2C).
- Opción C: Tabla Única Unificada de Ocupación:
  * Migrar 'public.bookings' hacia 'saas_appointments' o una tabla puente unificada.
    (Requiere refactor mayor de todo el Marketplace B2C).

RECOMENDACIÓN TÉCNICA:
Opción A. Asumir soberanía física total sobre 'saas_appointments' y coordinación optimista
con 'public.bookings', documentando explícitamente el límite de frontera.

ESTADO: PROPOSAL — NOT APPROVED
DECISIÓN REQUERIDA: El Director del Proyecto debe autorizar formalmente la Opción A o instruir
la estrategia de frontera requerida.
================================================================================
```

---

### BLOQUEADOR 2 — INVARIANTE FÍSICO EXACTO DE `END_TIME`

- **Problema:** Evitar dos fuentes de verdad entre `scheduled_at`, `duration_minutes_snapshot` y `end_time`.
- **Análisis de Opciones:**
  - *Opción A (Rechazada):* Solo `CHECK (scheduled_at < end_time)`. Insuficiente porque permite registrar `end_time` arbitrario.
  - *Opción B (Rechazada):* Columna generada `GENERATED ALWAYS AS (scheduled_at + interval) STORED`. Rechazada porque PostgreSQL clasifica el casteo a intervalo como `STABLE` en ciertas configuraciones de zona horaria, impidiendo su indexación directa en GiST.
  - *Opción C (Sancionada):* **Persistencia Dual con Constraint Físico de Equivalencia Exacta**.
- **Especificación Física Exacta:**
  ```sql
  CONSTRAINT chk_saas_appointments_end_time_exact 
      CHECK (end_time = scheduled_at + (duration_minutes_snapshot * INTERVAL '1 minute'))
  ```
- **Evidencia en Motor:** Probado y validado en PostgreSQL 15/16. Garantiza físicamente que:
  1. `end_time` es matemáticamente idéntico al instante exacto $t_{\text{start}} + \text{duración}$.
  2. Si la aplicación intenta insertar un `end_time` inconsistente, PostgreSQL aborta la transacción con `23514 check_violation`.
  3. `end_time` se puede indexar limpiamente en la restricción `EXCLUDE USING gist (..., tstzrange(scheduled_at, end_time, '[)'))`.
- **Clasificación:** `PHYSICAL DESIGN DECISION`.

---

### BLOQUEADOR 3 — AISLAMIENTO MULTI-TENANT DE CLIENTE REGISTRADO

- **Evidencia Física Existente en Foundation 065:**
  Inspección directa del catálogo PostgreSQL en `usuarios`:
  ```text
  Indexes:
      "uq_usuarios_id_tenant" UNIQUE CONSTRAINT, btree (id, tenant_id)
  Foreign-key constraints:
      "usuarios_tenant_id_fkey" FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
  Referenced by:
      TABLE "memberships" CONSTRAINT "fk_membership_user_tenant" 
          FOREIGN KEY (user_id, tenant_id) REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT
  ```
- **Solución Física Sancionada:**
  En `saas_appointments`, la relación con el cliente registrado se define mediante:
  ```sql
  CONSTRAINT fk_saas_appointments_customer_user_tenant 
      FOREIGN KEY (customer_user_id, tenant_id) 
      REFERENCES usuarios(id, tenant_id) 
      ON DELETE RESTRICT
  ```
- **Garantía:** Apoyada en la estructura física preexistente de Foundation `065`. Es matemáticamente imposible asociar un `customer_user_id` de otro inquilino a una cita de la sede.
- **Clasificación:** `SUPPORTED BY EXISTING ARCHITECTURE`.

---

### BLOQUEADOR 4 — MODELO DE TIMEZONE vs OPERATIONAL TIMEZONE

1. **`TIMESTAMPTZ` (Instante Universal UTC):**
   - En PostgreSQL, `TIMESTAMPTZ` almacena un valor numérico absoluto de 8 bytes (microsegundos desde epoch UTC). **NO almacena el nombre de la zona horaria**.
2. **`Operational Timezone` (`America/Bogota`):**
   - Es una **decisión arquitectónica global ya cerrada y ratificada** (NODO-05 Timezone Decision Analysis v1.0, Foundation `065`, NODO-03A).
   - Zona horaria de referencia: `America/Bogota` (UTC-5 fijo, sin variaciones estacionales DST).
3. **Mapeo Físico para Consultas de Agenda (`target_date`):**
   Para proyectar la agenda de una fecha local (ej. `'2026-09-15'`), la consulta SQL convierte los límites locales de `America/Bogota` a instantes absolutos UTC:
   ```sql
   -- Límites locales convertidos a TIMESTAMPTZ
   WHERE scheduled_at >= ('2026-09-15 00:00:00'::timestamp AT TIME ZONE 'America/Bogota')
     AND scheduled_at <  ('2026-09-16 00:00:00'::timestamp AT TIME ZONE 'America/Bogota')
   ```
   - Cero nuevas columnas de timezone en la tabla.
   - Cero modificaciones a tablas preexistentes.
- **Clasificación:** `APPROVED DERIVATION`.

---

### BLOQUEADOR 5 — SEMÁNTICA DE BORRADO, CANCELACIÓN Y PRESERVACIÓN

1. **Semántica Física de Claves Foráneas:**
   - Todas las FKs (`tenants`, `establishments`, `service_offers`, `memberships`, `usuarios`) tienen `ON DELETE RESTRICT`. Se impide el borrado accidental de datos maestros si existen citas históricas.
2. **Semántica de Cancelación (Modelo Operacional Aprobado):**
   - No existe `HARD DELETE` de citas en la API operacional.
   - Las cancelaciones son **actualizaciones de estado lógicas** (`status = 'CANCELLED'`), registrando `cancellation_reason` cuando corresponda y actualizando `updated_at`.
   - Al pasar a `CANCELLED`, la cita deja de cumplir el predicado del índice GiST `WHERE status NOT IN ('CANCELLED', 'NO_SHOW')`, liberando el slot inmediatamente.
3. **Preservación Histórica:**
   - Citas en estado `COMPLETED`, `CANCELLED` y `NO_SHOW` residen permanentemente en la base de datos para fines de auditoría, métricas e historial de cliente.
4. **Distinción con Políticas Administrativas:**
   - Políticas de retención documental, archivado frío (*cold storage*) o borrado por Habeas Data / GDPR pertenecen a la gobernanza general de la plataforma y **NO forman parte de NODO-06**.
- **Clasificación:** `APPROVED DERIVATION`.

---

## 2. ESPECIFICACIÓN DDL COMPLETA DE `saas_appointments`

```sql
-- ====================================================================
-- TABLA FÍSICA: saas_appointments
-- Node Contract: NODO-06 v1.0
-- Clasificación: PHYSICAL DESIGN SPECIFICATION (READY FOR IMPLEMENTATION)
-- ====================================================================

CREATE TABLE IF NOT EXISTS saas_appointments (
    -- 1. Identificador Primario
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 2. Anclaje Dimensional Multi-Tenant y Contextual
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,

    -- 3. Identidad de Cliente (Modo Dual Estricto: Registered vs Guest)
    customer_user_id INTEGER,
    guest_name VARCHAR(150),
    guest_phone VARCHAR(30),
    guest_email VARCHAR(255),

    -- 4. Fronteras Temporales (Instantes Absolutos UTC proyectados a America/Bogota)
    scheduled_at TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    -- 5. Snapshot Operacional Histórico Inmutable
    service_name_snapshot VARCHAR(255) NOT NULL,
    duration_minutes_snapshot INTEGER NOT NULL,
    price_snapshot NUMERIC(12, 2) NOT NULL,

    -- 6. Máquina de Estados Operacionales y Motivo de Interrupción
    status VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
    cancellation_reason TEXT,

    -- 7. Auditoría y Trazabilidad
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ================================================================
    -- CONSTRAINTS DE VALIDACIÓN DE DOMINIO Y CONSISTENCIA
    -- ================================================================

    -- Validación de Snapshots
    CONSTRAINT chk_saas_appointments_duration CHECK (duration_minutes_snapshot > 0),
    CONSTRAINT chk_saas_appointments_price CHECK (price_snapshot >= 0),
    
    -- Invariante Físico Exacto de Consistencia Temporal (Garantía de Fuente Única)
    CONSTRAINT chk_saas_appointments_end_time_exact 
        CHECK (end_time = scheduled_at + (duration_minutes_snapshot * INTERVAL '1 minute')),

    -- Máquina de Estados (7 Estados Canónicos Aprobados)
    CONSTRAINT chk_saas_appointments_status CHECK (
        status IN ('SCHEDULED', 'CONFIRMED', 'CHECKED_IN', 'IN_SERVICE', 'COMPLETED', 'CANCELLED', 'NO_SHOW')
    ),

    -- Motivo de Cancelación Restringido
    CONSTRAINT chk_saas_appointments_cancellation_reason CHECK (
        (status = 'CANCELLED') OR (cancellation_reason IS NULL)
    ),

    -- Modo Dual de Cliente (XOR Estricto)
    CONSTRAINT chk_saas_appointments_client_representation CHECK (
        -- Modo 1: Cliente Registrado
        (customer_user_id IS NOT NULL 
         AND guest_name IS NULL 
         AND guest_phone IS NULL 
         AND guest_email IS NULL)
        OR
        -- Modo 2: Cliente Invitado (Walk-in / Teléfono)
        (customer_user_id IS NULL 
         AND guest_name IS NOT NULL AND length(trim(guest_name)) >= 2
         AND guest_phone IS NOT NULL AND length(trim(guest_phone)) >= 7)
    ),

    -- ================================================================
    -- INTEGRIDAD REFERENCIAL COMPUESTA (ANTI CROSS-TENANT / CROSS-ESTABLISHMENT)
    -- ================================================================

    -- Clave Foránea a Tenants (Aislamiento Raíz)
    CONSTRAINT fk_saas_appointments_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta a Establishments (Anclaje de Sede)
    CONSTRAINT fk_saas_appointments_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Service Offers (Catálogo de Sede)
    CONSTRAINT fk_saas_appointments_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Memberships (Profesional de Sede)
    CONSTRAINT fk_saas_appointments_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Doble a Usuarios (Cliente Registrado de Tenant)
    CONSTRAINT fk_saas_appointments_customer_user_tenant 
        FOREIGN KEY (customer_user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) 
        ON DELETE RESTRICT
);
```

---

## 3. RESTRICCIÓN DE EXCLUSIÓN CONCURRENTE (ÍNDICE GIST)

```sql
-- ====================================================================
-- RESTRICCIÓN DE EXCLUSIÓN DE OCUPACIÓN ACTIVA INTRA-SAAS
-- Requiere extensión: btree_gist (Verificada v1.7)
-- ====================================================================

ALTER TABLE saas_appointments 
ADD CONSTRAINT uq_saas_appointments_no_overlap 
EXCLUDE USING gist (
    establishment_id WITH =,
    membership_id WITH =,
    tstzrange(scheduled_at, end_time, '[)') WITH &&
) WHERE (status NOT IN ('CANCELLED', 'NO_SHOW'));
```

---

## 4. ÍNDICES FÍSICOS NO ESPECULATIVOS

```sql
-- Soporte a Políticas RLS y Aislamiento Tenant
CREATE INDEX IF NOT EXISTS idx_saas_appointments_tenant_id 
    ON saas_appointments(tenant_id);

-- Soporte a Proyección de Agenda de Sede por Rango de Fechas
CREATE INDEX IF NOT EXISTS idx_saas_appointments_establishment_scheduled 
    ON saas_appointments(establishment_id, scheduled_at);

-- Soporte a Agenda de Profesional Específico
CREATE INDEX IF NOT EXISTS idx_saas_appointments_membership_scheduled 
    ON saas_appointments(membership_id, scheduled_at);

-- Soporte a Búsqueda por Oferta de Servicio
CREATE INDEX IF NOT EXISTS idx_saas_appointments_service_offer_id 
    ON saas_appointments(service_offer_id);

-- Soporte a Historial de Cliente Registrado
CREATE INDEX IF NOT EXISTS idx_saas_appointments_customer_user_id 
    ON saas_appointments(customer_user_id) 
    WHERE customer_user_id IS NOT NULL;
```

---

## 5. ROW-LEVEL SECURITY (RLS) POLICY

```sql
-- Habilitación de Seguridad de Fila
ALTER TABLE saas_appointments ENABLE ROW LEVEL SECURITY;

-- Política Canónica Multi-Tenant (Estándar Foundation 065)
CREATE POLICY tenant_isolation_saas_appointments ON saas_appointments
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

---

## 6. CLASIFICACIÓN RIGUROSA DE DECISIONES FÍSICAS

| Componente Físico | Clasificación Formal | Justificación / Dependencia |
| :--- | :---: | :--- |
| Tabla `saas_appointments` | **APPROVED DERIVATION** | Derivada de `N06-DEC-01` y Node Contract v1.0. |
| Claves Foráneas Compuestas triples/dobles | **SUPPORTED BY EXISTING ARCHITECTURE** | Soportada por constraints `UNIQUE` en Foundation `065`, `067`, `068`. |
| Restricción `EXCLUDE USING gist` intra-SaaS | **PHYSICAL DESIGN DECISION** | Estándar de oro PostgreSQL para exclusión temporal $O(\log N)$. |
| Invariante Físico de `end_time` exacto | **PHYSICAL DESIGN DECISION** | `CHECK (end_time = scheduled_at + duration * interval)`. |
| Aislamiento de Cliente (`customer_user_id, tenant_id`) | **SUPPORTED BY EXISTING ARCHITECTURE** | Soportada por `uq_usuarios_id_tenant` en Foundation `065`. |
| Modo Dual XOR de Cliente | **APPROVED DERIVATION** | Derivada de `N06-DEC-03`. |
| Snapshots Inmutables de Catálogo | **APPROVED DERIVATION** | Derivada de `N06-DEC-07`. |
| RLS con `SET LOCAL app.tenant_id` | **SUPPORTED BY EXISTING ARCHITECTURE** | Estándar de Foundation `065` y NODO-05. |
| Timezone Operacional `America/Bogota` | **APPROVED DERIVATION** | Decisión global cerrada en NODO-05 / Foundation `065`. |
| Preservación Histórica y `ON DELETE RESTRICT` | **APPROVED DERIVATION** | Derivada de `N06-DEC-08`. |
| **Gobernanza de Concurrencia Cross-Table (SaaS vs B2C)** | **PROPOSAL — NOT APPROVED** | **Requiere decisión directiva sobre el límite de frontera con `public.bookings`.** |

---

## 7. DICTAMEN FINAL DE ARQUITECTURA FÍSICA

```
================================================================================
                    DICTAMEN DE ARQUITECTURA FÍSICA
================================================================================
ESTADO: ARCHITECTURAL STOP — DECISION REQUIRED 🛑
CONCURRENCIA CROSS-TABLE: DECLARADA FORMALMENTE (PROPOSAL — NOT APPROVED)
INVARIANTE FÍSICO end_time: RESUELTO CON CHECK DE EQUIVALENCIA EXACTA (DECISION)
AISLAMIENTO CLIENTE TENANT: VERIFICADO CON EVIDENCIA EN uq_usuarios_id_tenant (SUPPORTED)
TIMEZONE: TIMESTAMPTZ UTC + OPERATIONAL TIMEZONE America/Bogota (APPROVED DERIVATION)
SEMÁNTICA DELETE: PRESERVACIÓN HISTÓRICA CON ON DELETE RESTRICT (APPROVED DERIVATION)
DDL / MIGRACIONES EJECUTADAS: CERO (ESPECIFICACIÓN DOCUMENTAL EXCLUSIVA)
PRÓXIMO PASO: COMPUERTA DIRECTIVA → DECISIÓN DEL DIRECTOR SOBRE BLOQUEADOR 1
================================================================================
```
