-- ====================================================================
-- MIGRATION 074: SAAS STAFF INVITATIONS
-- Node Contract — Staff Provisioning v1.0 (GO-08.36)
-- Physical Architecture Specification for STAFF_INVITATIONS
-- Transactional, Idempotent, RLS Enabled & Multi-Tenant Protected
-- ====================================================================

BEGIN;

-- 1. Crear Tabla staff_invitations
CREATE TABLE IF NOT EXISTS staff_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    establishment_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST')),
    relation_type VARCHAR(50) NOT NULL DEFAULT 'STAFF_EMPLOYEE' CHECK (relation_type IN ('OWNER_PARTNER', 'STAFF_EMPLOYEE', 'INDEPENDENT_PROVIDER')),
    invited_by_membership_id UUID NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')),
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    accepted_user_id INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Clave Foránea Compuesta a Establishments (Anclaje de Sede)
    CONSTRAINT fk_staff_invitations_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple al Invitador (Memberships de la misma Sede)
    CONSTRAINT fk_staff_invitations_inviter 
        FOREIGN KEY (invited_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta al Usuario que Aceptó
    CONSTRAINT fk_staff_invitations_accepted_user 
        FOREIGN KEY (accepted_user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) 
        ON DELETE RESTRICT
);

-- 2. Índices Físicos de Búsqueda y Aislamiento
CREATE INDEX IF NOT EXISTS idx_staff_invitations_tenant_id 
    ON staff_invitations(tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_invitations_establishment_tenant 
    ON staff_invitations(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_invitations_token_hash 
    ON staff_invitations(token_hash);

CREATE INDEX IF NOT EXISTS idx_staff_invitations_email 
    ON staff_invitations(email);

-- 3. Restricción de Unicidad Parcial: Solo una invitación PENDING por (establishment_id, lower(email))
CREATE UNIQUE INDEX IF NOT EXISTS uq_staff_invitations_pending 
    ON staff_invitations(establishment_id, lower(email)) 
    WHERE status = 'PENDING';

-- 4. Seguridad de Fila (Row-Level Security - RLS)
ALTER TABLE staff_invitations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'staff_invitations' 
        AND policyname = 'tenant_isolation_staff_invitations'
    ) THEN
        CREATE POLICY tenant_isolation_staff_invitations ON staff_invitations
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 5. Registro de Migración en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('074_saas_staff_invitations.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
