# CUSTOMER / CLIENT DIRECTORY — PHYSICAL ARCHITECTURE v1.0
## GLOWAPP SaaS: ESPECIFICACIÓN FÍSICA Y ESTRUCTURA RELACIONAL DDL

**DOCUMENTO:** `CUSTOMER-DOMAIN-PHYSICAL-ARCHITECTURE-v1.0`  
**CONTRATO CANÓNICO:** [`CUSTOMER-DOMAIN-CONTRACT-v1.0.md`](file:///ncp/CUSTOMER-DOMAIN-CONTRACT-v1.0.md) (`RATIFIED 🔒`)  
**ESTADO:** `PHYSICAL ARCHITECTURE DESIGNED — DDL / MIGRATION NOT AUTHORIZED 🔒`  
**AUTORIDAD DIRECTIVA:** Director del Proyecto GlowApp SaaS  
**FECHA DE DISEÑO:** 2026-09-12  
**BASE INMUTABLE:** NODO-01 $\to$ NODO-08 (`CLOSED / IMMUTABLE 🔒`)  

---

> [!IMPORTANT]
> Este documento contiene el **DISEÑO FÍSICO ARQUITECTÓNICO FORMAL**.  
> **ESTADO:** `DESIGN ONLY`.  
> **Queda terminantemente prohibido:** Crear archivos de migración física, ejecutar sentencias SQL en base de datos, implementar endpoints backend o pantallas frontend hasta la autorización explícita del Director del Proyecto.

---

## 1. INTRODUCCIÓN Y ARQUITECTURA DE DATOS

En estricto cumplimiento con el contrato ratificado **`CUSTOMER DOMAIN CONTRACT v1.0`**, la arquitectura física del dominio de clientes se fundamenta en la **separación desacoplada entre la identidad canónica en el Tenant y la presencia operativa por Establecimiento**.

```
                       ┌─────────────────────────────────────┐
                       │           SAAS TENANTS              │
                       │           (tenants.id)              │
                       └──────────────────┬──────────────────┘
                                          │ 1:N
                                          ▼
                       ┌─────────────────────────────────────┐
                       │          SAAS_CUSTOMERS             │
                       │      (Identidad en Tenant)          │
                       │                                     │
                       │ - id (UUID PK)                      │
                       │ - tenant_id (FK tenants)            │
                       │ - user_id (NULLABLE FK usuarios)    │
                       │ - first_name, last_name             │
                       │ - phone, email, birth_date          │
                       │ - status (ACTIVE, INACTIVE, ARCHIVED│
                       │ - created_by_membership_id          │
                       └──────────────────┬──────────────────┘
                                          │ 1:N
                                          ▼
                       ┌─────────────────────────────────────┐
                       │   SAAS_CUSTOMER_ESTABLISHMENTS      │
                       │       (Relación Operacional)        │
                       │                                     │
                       │ - id (UUID PK)                      │
                       │ - tenant_id (FK tenants)            │
                       │ - customer_id (FK saas_customers)   │
                       │ - establishment_id (FK estabs)      │
                       │ - local_notes (privadas por sede)   │
                       │ - is_active (BOOLEAN)               │
                       │ - first_visited_at, last_visited_at │
                       └─────────────────────────────────────┘
```

---

## 2. ESPECIFICACIÓN FÍSICA DETALLADA DE TABLAS

### 2.1 Tabla `saas_customers` (Identidad Canónica del Cliente)

Centraliza los datos personales y de contacto del cliente a nivel de la organización/empresa (`tenant_id`).

```sql
CREATE TABLE IF NOT EXISTS saas_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    
    -- Vínculo Opcional y Reversible con Cuenta Global (DEC-CUST-002, DEC-CUST-003)
    user_id INTEGER,
    
    -- Identificación y Datos de Contacto
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL DEFAULT '',
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(255),
    birth_date DATE,
    
    -- Ciclo de Vida (DEC-CUST-008)
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    
    -- Trazabilidad y Marcas Temporales
    created_by_membership_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Integridad Referencial
    CONSTRAINT fk_customers_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_customers_user 
        FOREIGN KEY (user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) 
        ON DELETE SET NULL,
    CONSTRAINT fk_customers_creator 
        FOREIGN KEY (created_by_membership_id) 
        REFERENCES memberships(id) 
        ON DELETE RESTRICT,
        
    -- Restricción de Dominio para Ciclo de Vida
    CONSTRAINT chk_customer_status 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')),
        
    -- Garantía de Integridad Multi-Tenant Compuesta
    CONSTRAINT uq_customer_id_tenant 
        UNIQUE (id, tenant_id)
);
```

### 2.2 Tabla `saas_customer_establishments` (Relación Operacional por Sede)

Almacena la presencia, notas operativas privadas y métricas de visita del cliente en cada sede física específica.

```sql
CREATE TABLE IF NOT EXISTS saas_customer_establishments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    customer_id UUID NOT NULL,
    establishment_id UUID NOT NULL,
    
    -- Notas Operativas y de Preferencias Locales
    local_notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Métricas de Visita en Sede
    first_visited_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_visited_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Integridad Referencial Compuesta
    CONSTRAINT fk_cust_est_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cust_est_customer 
        FOREIGN KEY (customer_id, tenant_id) 
        REFERENCES saas_customers(id, tenant_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cust_est_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
        
    -- Unicidad de Relación por Sede
    CONSTRAINT uq_customer_per_establishment 
        UNIQUE (establishment_id, customer_id)
);
```

---

## 3. ÍNDICES DE RENDIMIENTO Y BÚSQUEDA PREDICTIVA

Para garantizar respuestas sub-milisegundo en las búsquedas typeahead de recepción en agenda y cobro:

```sql
-- Índices para saas_customers
CREATE INDEX IF NOT EXISTS idx_customers_tenant_phone 
    ON saas_customers(tenant_id, phone);

CREATE INDEX IF NOT EXISTS idx_customers_tenant_name 
    ON saas_customers(tenant_id, first_name, last_name);

CREATE INDEX IF NOT EXISTS idx_customers_tenant_status 
    ON saas_customers(tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_customers_user_id 
    ON saas_customers(user_id) 
    WHERE user_id IS NOT NULL;

-- Índices para saas_customer_establishments
CREATE INDEX IF NOT EXISTS idx_cust_est_lookup 
    ON saas_customer_establishments(establishment_id, customer_id);

CREATE INDEX IF NOT EXISTS idx_cust_est_tenant_establishment 
    ON saas_customer_establishments(establishment_id, tenant_id);
```

---

## 4. POLÍTICAS DE SEGURIDAD A NIVEL DE FILA (ROW LEVEL SECURITY - RLS)

Se aplica el estándar de aislamiento multi-tenant y contextual ratificado en la Foundation:

```sql
-- 1. Habilitación de RLS
ALTER TABLE saas_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas_customer_establishments ENABLE ROW LEVEL SECURITY;

-- 2. Política de Aislamiento Tenant para saas_customers
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_customers' 
        AND policyname = 'tenant_isolation_saas_customers'
    ) THEN
        CREATE POLICY tenant_isolation_saas_customers 
            ON saas_customers
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 3. Política de Aislamiento Tenant para saas_customer_establishments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_customer_establishments' 
        AND policyname = 'tenant_isolation_saas_customer_establishments'
    ) THEN
        CREATE POLICY tenant_isolation_saas_customer_establishments 
            ON saas_customer_establishments
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;
```

---

## 5. PROYECCIONES DE CONSULTA DE HISTORIAL (DERIVED READ MODEL)

Conforme a `DEC-CUST-004`, el Customer Domain no duplica datos de citas ni tickets. La consulta de historial opera como una **proyección de lectura agregada en tiempo de ejecución**:

### 5.1 Proyección de Historial de Citas (Consumo de NODO-06):
```sql
-- Consulta Canónica de Proyección (Read-Only)
SELECT 
    a.id AS appointment_id,
    a.establishment_id,
    a.scheduled_start,
    a.scheduled_end,
    a.status,
    a.cancellation_reason,
    a.service_name_snapshot,
    a.price_snapshot,
    a.professional_name_snapshot
FROM saas_appointments a
WHERE a.tenant_id = $1
  AND (
    (a.customer_user_id IS NOT NULL AND a.customer_user_id = $2)
    OR (a.guest_phone_snapshot = $3)
  )
ORDER BY a.scheduled_start DESC;
```

### 5.2 Proyección de Historial Financiero (Consumo de NODO-08):
```sql
-- Consulta Canónica de Proyección Financiera (Read-Only)
SELECT 
    t.id AS ticket_id,
    t.ticket_number,
    t.establishment_id,
    t.status AS ticket_status,
    t.total_amount,
    t.paid_amount,
    t.balance_due,
    t.created_at,
    t.closed_at
FROM saas_service_tickets t
WHERE t.tenant_id = $1
  AND (
    (t.customer_user_id IS NOT NULL AND t.customer_user_id = $2)
    OR (t.guest_phone_snapshot = $3)
  )
ORDER BY t.created_at DESC;
```

---

## 6. MATRIZ DE INTEGRIDAD Y REGLAS DE CONMUTACIÓN

1. **Invarianza de Citas y Tickets:** Cero alteraciones en las tablas `saas_appointments`, `saas_service_tickets`, `saas_ticket_items` y `saas_ticket_payments`.
2. **Invarianza de Usuarios:** Cero columnas agregadas a `public.usuarios`.
3. **Account Linking Reversible:** `user_id` con `ON DELETE SET NULL` asegura que si una cuenta de usuario es dada de baja, el cliente local del salón permanece intacto.
4. **No-Matching Silencioso:** La asignación de `user_id` en `saas_customers` se gestiona exclusivamente por endpoint administrativo autenticado.

---

## 7. DECLARACIÓN FORMAL DE ESTADO FÍSICO

```text
============================================================
       CUSTOMER DOMAIN — PHYSICAL ARCHITECTURE v1.0
                     DESIGN COMPLETE 🔒

           DDL / MIGRATION: NOT AUTHORIZED
           IMPLEMENTATION:  NOT AUTHORIZED
============================================================
```
