-- ====================================================================
-- MIGRATION 070: SAAS TO B2C SERVICE MATERIALIZATION MAPPING TABLE
-- Node Contract — NODO-04-v1.0 & Implementation Contract v1.0
-- Technical Downstream Mapping between SaaS Service Assignment and B2C public.services
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- 1. Crear Tabla saas_service_materializations
CREATE TABLE IF NOT EXISTS public.saas_service_materializations (
    -- =========================================================================
    -- A. CORE MAPPING (Identidad y Dimensiones de Aislamiento Requeridas)
    -- =========================================================================
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    service_id UUID NOT NULL,

    -- =========================================================================
    -- C. CLAVES FORÁNEAS DE CONTEXTO E INTEGRIDAD SAAS
    -- =========================================================================
    CONSTRAINT fk_mat_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES public.tenants(id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_service_assignments_offer_membership
    CONSTRAINT fk_mat_assignment 
        FOREIGN KEY (service_offer_id, membership_id) 
        REFERENCES public.service_assignments(service_offer_id, membership_id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_service_offers_id_establishment_tenant
    CONSTRAINT fk_mat_offer_context 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES public.service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_membership_id_establishment_tenant
    CONSTRAINT fk_mat_membership_context 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES public.memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- =========================================================================
    -- D. INTEGRIDAD DOWNSTREAM HACIA B2C
    -- =========================================================================
    CONSTRAINT fk_mat_service 
        FOREIGN KEY (service_id) 
        REFERENCES public.services(id) 
        ON DELETE CASCADE,

    -- =========================================================================
    -- E. RESTRICCIONES DE UNICIDAD E IDEMPOTENCIA
    -- =========================================================================
    CONSTRAINT uq_mat_assignment_establishment 
        UNIQUE (establishment_id, service_offer_id, membership_id),

    CONSTRAINT uq_mat_service_id 
        UNIQUE (service_id)
);

-- 2. Índices Físicos de Rendimiento
CREATE INDEX IF NOT EXISTS idx_mat_tenant_est 
    ON public.saas_service_materializations(tenant_id, establishment_id);

CREATE INDEX IF NOT EXISTS idx_mat_service 
    ON public.saas_service_materializations(service_id);

CREATE INDEX IF NOT EXISTS idx_mat_membership 
    ON public.saas_service_materializations(membership_id);

-- 3. Aislamiento Row-Level Security (RLS)
ALTER TABLE public.saas_service_materializations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_service_materializations' 
        AND policyname = 'tenant_isolation_saas_service_materializations'
    ) THEN
        CREATE POLICY tenant_isolation_saas_service_materializations ON public.saas_service_materializations
            FOR ALL
            USING (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer)
            WITH CHECK (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer);
    END IF;
END $$;

-- 4. Registro de Migración en schema_migrations
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('070_saas_service_materializations.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
