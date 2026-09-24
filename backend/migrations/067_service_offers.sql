-- ====================================================================
-- MIGRATION 067: SAAS CATALOG SERVICE OFFERS
-- Node Contract — ARCH-BUNDLE-SO-PHYSICAL-01-R1
-- Physical Architecture Specification for SERVICE_OFFER
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- 1. Crear Tabla service_offers
CREATE TABLE IF NOT EXISTS service_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    base_duration INTEGER NOT NULL,
    base_price NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints de Validación de Dominio
    CONSTRAINT chk_service_offers_duration CHECK (base_duration > 0),
    CONSTRAINT chk_service_offers_price CHECK (base_price >= 0),
    
    -- Integridad Referencial Compuesta con Foundation (ON DELETE RESTRICT)
    CONSTRAINT fk_service_offers_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT fk_service_offers_establishment FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT,
        
    -- Claves Únicas Compuestas para Integridad Multi-Tenant y Soporte a Futuro ASSIGNMENT
    CONSTRAINT uq_service_offers_id_tenant UNIQUE (id, tenant_id),
    CONSTRAINT uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)
);

-- 2. Índices Físicos No Especulativos
CREATE INDEX IF NOT EXISTS idx_service_offers_tenant_id 
    ON service_offers(tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_offers_establishment_tenant 
    ON service_offers(establishment_id, tenant_id);

-- 3. Aislamiento Row-Level Security (RLS)
ALTER TABLE service_offers ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_offers' 
        AND policyname = 'tenant_isolation_service_offers'
    ) THEN
        CREATE POLICY tenant_isolation_service_offers ON service_offers
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- 4. Registro en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('067_service_offers.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
