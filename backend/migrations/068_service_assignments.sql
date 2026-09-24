-- ====================================================================
-- MIGRATION 068: SAAS SERVICE ASSIGNMENTS
-- Node Contract — ARCH-BUNDLE-AS-IMPLEMENTATION-01 (DEC-FC-001 OPTION A)
-- Physical Architecture Specification for SERVICE_ASSIGNMENT
-- Transactional, Idempotent, RLS Enabled & Dual Triple Composite Protected
-- ====================================================================

BEGIN;

-- 1. Prerrequisito de Compatibilidad Foundation (DEC-FC-001 - Opción A)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_membership_id_establishment_tenant'
    ) THEN
        ALTER TABLE memberships 
            ADD CONSTRAINT uq_membership_id_establishment_tenant 
            UNIQUE (id, establishment_id, tenant_id);
    END IF;
END $$;

-- 2. Crear Tabla service_assignments
CREATE TABLE IF NOT EXISTS service_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Clave Foránea a Tenants (Aislamiento de Raíz)
    CONSTRAINT fk_service_assignments_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta a Establishments (Anclaje de Sede)
    CONSTRAINT fk_service_assignments_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Service Offers (DEC-AS-007)
    CONSTRAINT fk_service_assignments_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Memberships (DEC-AS-006, DEC-AS-007, DEC-FC-001)
    CONSTRAINT fk_service_assignments_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Unicidad Relacional por Pareja de Negocio (DEC-AS-011)
    CONSTRAINT uq_service_assignments_offer_membership 
        UNIQUE (service_offer_id, membership_id)
);

-- 3. Índices Físicos No Especulativos
CREATE INDEX IF NOT EXISTS idx_service_assignments_tenant_id 
    ON service_assignments(tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_establishment_tenant 
    ON service_assignments(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_membership_id 
    ON service_assignments(membership_id);

-- 4. Seguridad de Fila (Row-Level Security - RLS)
ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_assignments' 
        AND policyname = 'tenant_isolation_service_assignments'
    ) THEN
        CREATE POLICY tenant_isolation_service_assignments ON service_assignments
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 5. Registro de Migración en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('068_service_assignments.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
