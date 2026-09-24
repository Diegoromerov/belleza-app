-- ====================================================================
-- MIGRATION 078: SAAS STAFF EXTERNAL CALENDAR INTEGRATIONS & OUTBOX
-- Domain Contract — GAP-04 Phase 1 Specification (RATIFIED)
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Tabla: saas_staff_calendar_integrations
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_staff_calendar_integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    
    -- Tipo de Proveedor (Fase 1: GOOGLE, ICS)
    provider VARCHAR(30) NOT NULL,
    
    -- Token Criptográfico Seguro y Revocable para Feed ICS
    ics_token VARCHAR(64) UNIQUE,
    ics_token_created_at TIMESTAMPTZ,
    
    -- Credenciales OAuth Cifradas en Reposo (Google Calendar)
    external_calendar_id VARCHAR(255),
    encrypted_refresh_token TEXT,
    encrypted_access_token TEXT,
    token_expires_at TIMESTAMPTZ,
    
    -- Estado de la Integración y Modo
    status VARCHAR(30) NOT NULL DEFAULT 'DISCONNECTED',
    sync_mode VARCHAR(30) NOT NULL DEFAULT 'EXPORT_ONLY',
    last_synced_at TIMESTAMPTZ,
    last_error TEXT,
    
    -- Trazabilidad
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Integridad Referencial
    CONSTRAINT fk_cal_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cal_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cal_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE CASCADE,
        
    -- Restricciones de Dominio
    CONSTRAINT chk_cal_provider 
        CHECK (provider IN ('GOOGLE', 'ICS')),
    CONSTRAINT chk_cal_status 
        CHECK (status IN ('DISCONNECTED', 'CONNECTED', 'SYNC_ERROR', 'REVOKED', 'PAUSED')),
    CONSTRAINT chk_cal_sync_mode 
        CHECK (sync_mode = 'EXPORT_ONLY'),
        
    -- Restricción de Unicidad: 1 integración por proveedor por membership
    CONSTRAINT uq_membership_provider 
        UNIQUE (membership_id, provider)
);

-- Índices Físicos
CREATE INDEX IF NOT EXISTS idx_cal_tenant_establishment 
    ON saas_staff_calendar_integrations(tenant_id, establishment_id);

CREATE INDEX IF NOT EXISTS idx_cal_ics_token 
    ON saas_staff_calendar_integrations(ics_token) 
    WHERE ics_token IS NOT NULL;

-- RLS para saas_staff_calendar_integrations
ALTER TABLE saas_staff_calendar_integrations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_staff_calendar_integrations' 
        AND policyname = 'tenant_isolation_saas_staff_calendar_integrations'
    ) THEN
        CREATE POLICY tenant_isolation_saas_staff_calendar_integrations 
            ON saas_staff_calendar_integrations
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Tabla: saas_calendar_sync_outbox
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_calendar_sync_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    integration_id UUID NOT NULL,
    appointment_id UUID NOT NULL,
    
    -- Operación
    operation VARCHAR(30) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Estado y Ciclo de Vida del Outbox
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    external_event_id VARCHAR(255),
    attempts INTEGER NOT NULL DEFAULT 0,
    max_attempts INTEGER NOT NULL DEFAULT 3,
    last_error TEXT,
    next_retry_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Integridad Referencial
    CONSTRAINT fk_outbox_integration 
        FOREIGN KEY (integration_id) 
        REFERENCES saas_staff_calendar_integrations(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_outbox_appointment 
        FOREIGN KEY (appointment_id) 
        REFERENCES saas_appointments(id) 
        ON DELETE CASCADE,
        
    -- Restricciones de Dominio
    CONSTRAINT chk_outbox_operation 
        CHECK (operation IN ('CREATE_EVENT', 'UPDATE_EVENT', 'CANCEL_EVENT')),
    CONSTRAINT chk_outbox_status 
        CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'RETRYABLE_FAILURE', 'FINAL_FAILURE'))
);

CREATE INDEX IF NOT EXISTS idx_outbox_pending_retry 
    ON saas_calendar_sync_outbox(status, next_retry_at) 
    WHERE status IN ('PENDING', 'RETRYABLE_FAILURE');

CREATE INDEX IF NOT EXISTS idx_outbox_app_op 
    ON saas_calendar_sync_outbox(appointment_id, integration_id, operation);

-- RLS para saas_calendar_sync_outbox
ALTER TABLE saas_calendar_sync_outbox ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_calendar_sync_outbox' 
        AND policyname = 'tenant_isolation_saas_calendar_sync_outbox'
    ) THEN
        CREATE POLICY tenant_isolation_saas_calendar_sync_outbox 
            ON saas_calendar_sync_outbox
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 3. Registro en schema_migrations
-- ------------------------------------------------------------
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('078_saas_staff_calendar_integrations.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
