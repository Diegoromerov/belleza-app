-- ====================================================================
-- MIGRATION 071: SAAS INTERNAL APPOINTMENTS
-- Node Contract — NODO-06 v1.0 & ARCH-BUNDLE-N06-PHYSICAL-01
-- Physical Architecture Specification for SAAS_APPOINTMENTS
-- Transactional, Idempotent, RLS Enabled, GiST Exclusion & Composite Protected
-- ====================================================================

BEGIN;

-- 1. Asegurar extensión btree_gist para soporte a exclusión multi-columna con rangos temporales
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 2. Crear Tabla saas_appointments
CREATE TABLE IF NOT EXISTS saas_appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,

    -- Representación de Cliente (Modo Dual: Registered vs Guest)
    customer_user_id INTEGER,
    guest_name VARCHAR(150),
    guest_phone VARCHAR(30),
    guest_email VARCHAR(255),

    -- Fronteras Temporales (Instantes Absolutos UTC)
    scheduled_at TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    -- Snapshots Operacionales Inmutables de Catálogo
    service_name_snapshot VARCHAR(255) NOT NULL,
    duration_minutes_snapshot INTEGER NOT NULL,
    price_snapshot NUMERIC(12, 2) NOT NULL,

    -- Máquina de Estados Operacionales
    status VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
    cancellation_reason TEXT,

    -- Auditoría y Trazabilidad
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints de Dominio y Consistencia
    CONSTRAINT chk_saas_appointments_duration CHECK (duration_minutes_snapshot > 0),
    CONSTRAINT chk_saas_appointments_price CHECK (price_snapshot >= 0),
    CONSTRAINT chk_saas_appointments_temporal_order CHECK (scheduled_at < end_time),
    CONSTRAINT chk_saas_appointments_end_time_exact 
        CHECK (end_time = scheduled_at + (duration_minutes_snapshot * INTERVAL '1 minute')),
    CONSTRAINT chk_saas_appointments_status CHECK (
        status IN ('SCHEDULED', 'CONFIRMED', 'CHECKED_IN', 'IN_SERVICE', 'COMPLETED', 'CANCELLED', 'NO_SHOW')
    ),
    CONSTRAINT chk_saas_appointments_cancellation_reason CHECK (
        (status = 'CANCELLED') OR (cancellation_reason IS NULL)
    ),
    CONSTRAINT chk_saas_appointments_client_representation CHECK (
        (customer_user_id IS NOT NULL AND guest_name IS NULL AND guest_phone IS NULL AND guest_email IS NULL)
        OR
        (customer_user_id IS NULL AND guest_name IS NOT NULL AND length(trim(guest_name)) >= 2 AND guest_phone IS NOT NULL AND length(trim(guest_phone)) >= 7)
    ),

    -- Claves Foráneas Compuestas Anti-Cross-Tenant
    CONSTRAINT fk_saas_appointments_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_saas_appointments_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_saas_appointments_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_saas_appointments_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_saas_appointments_customer_user_tenant 
        FOREIGN KEY (customer_user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) 
        ON DELETE RESTRICT
);

-- 3. Restricción de Exclusión Concurrente (Índice GiST Intra-SaaS)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_saas_appointments_no_overlap'
    ) THEN
        ALTER TABLE saas_appointments 
            ADD CONSTRAINT uq_saas_appointments_no_overlap 
            EXCLUDE USING gist (
                establishment_id WITH =,
                membership_id WITH =,
                tstzrange(scheduled_at, end_time, '[)') WITH &&
            ) WHERE (status NOT IN ('CANCELLED', 'NO_SHOW'));
    END IF;
END $$;

-- 4. Índices Físicos No Especulativos
CREATE INDEX IF NOT EXISTS idx_saas_appointments_tenant_id 
    ON saas_appointments(tenant_id);

CREATE INDEX IF NOT EXISTS idx_saas_appointments_establishment_scheduled 
    ON saas_appointments(establishment_id, scheduled_at);

CREATE INDEX IF NOT EXISTS idx_saas_appointments_membership_scheduled 
    ON saas_appointments(membership_id, scheduled_at);

CREATE INDEX IF NOT EXISTS idx_saas_appointments_service_offer_id 
    ON saas_appointments(service_offer_id);

CREATE INDEX IF NOT EXISTS idx_saas_appointments_customer_user_id 
    ON saas_appointments(customer_user_id) 
    WHERE customer_user_id IS NOT NULL;

-- 5. Row-Level Security (RLS)
ALTER TABLE saas_appointments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_appointments' 
        AND policyname = 'tenant_isolation_saas_appointments'
    ) THEN
        CREATE POLICY tenant_isolation_saas_appointments ON saas_appointments
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 6. Permisos para usuario de aplicación
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'beauty_app_user') THEN
        GRANT ALL PRIVILEGES ON TABLE saas_appointments TO beauty_app_user;
    END IF;
END $$;

-- 7. Registro de Migración en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('071_saas_appointments.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
