-- ====================================================================
-- MIGRATION 069: SAAS STAFF SCHEDULES
-- Node Contract — NODO-03A-v1.0 & ARCH-BUNDLE-N03A-PHYSICAL-01 (R2)
-- Physical Architecture Specification for STAFF_SCHEDULE
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- 1. Crear Tabla staff_schedules
CREATE TABLE IF NOT EXISTS staff_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    day_of_week SMALLINT NOT NULL,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
    end_time TIME WITHOUT TIME ZONE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de Validación de Dominio Temporal
    CONSTRAINT chk_staff_schedules_day_range 
        CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_staff_schedules_time_order 
        CHECK (start_time < end_time),

    -- Clave Foránea a Tenants (Aislamiento de Raíz)
    CONSTRAINT fk_staff_schedules_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta a Establishments (Anclaje de Sede)
    CONSTRAINT fk_staff_schedules_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Memberships (DEC-FC-001, Integridad Física Referencial)
    CONSTRAINT fk_staff_schedules_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Unicidad de Inicio de Intervalo Exacto
    CONSTRAINT uq_staff_schedules_exact_interval 
        UNIQUE (establishment_id, membership_id, day_of_week, start_time)
);

-- 2. Índices Físicos No Especulativos
CREATE INDEX IF NOT EXISTS idx_staff_schedules_tenant_id 
    ON staff_schedules(tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_schedules_establishment_tenant 
    ON staff_schedules(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_schedules_membership_establishment 
    ON staff_schedules(membership_id, establishment_id);

-- 3. Aislamiento Row-Level Security (RLS)
ALTER TABLE staff_schedules ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'staff_schedules' 
        AND policyname = 'tenant_isolation_staff_schedules'
    ) THEN
        CREATE POLICY tenant_isolation_staff_schedules ON staff_schedules
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 4. Registro de Migración en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('069_staff_schedules.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
