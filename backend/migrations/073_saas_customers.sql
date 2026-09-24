-- ====================================================================
-- MIGRATION 073: SAAS CUSTOMER / CLIENT DIRECTORY
-- Domain Contract — CUSTOMER DOMAIN CONTRACT v1.0 (RATIFIED)
-- Physical Architecture Specification for SAAS_CUSTOMERS and
-- SAAS_CUSTOMER_ESTABLISHMENTS
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Tabla: saas_customers (§2.1)
-- ------------------------------------------------------------
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

-- Índices Físicos para saas_customers (§10)
CREATE INDEX IF NOT EXISTS idx_customers_tenant_phone 
    ON saas_customers(tenant_id, phone);

CREATE INDEX IF NOT EXISTS idx_customers_tenant_name 
    ON saas_customers(tenant_id, first_name, last_name);

CREATE INDEX IF NOT EXISTS idx_customers_user_id 
    ON saas_customers(user_id) 
    WHERE user_id IS NOT NULL;

-- RLS para saas_customers
ALTER TABLE saas_customers ENABLE ROW LEVEL SECURITY;

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

-- ------------------------------------------------------------
-- 2. Tabla: saas_customer_establishments (§2.2)
-- ------------------------------------------------------------
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

-- Índices Físicos para saas_customer_establishments (§10)
CREATE INDEX IF NOT EXISTS idx_cust_est_lookup 
    ON saas_customer_establishments(establishment_id, customer_id);

-- RLS para saas_customer_establishments
ALTER TABLE saas_customer_establishments ENABLE ROW LEVEL SECURITY;

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

-- ------------------------------------------------------------
-- 3. Registro en schema_migrations
-- ------------------------------------------------------------
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('073_saas_customers.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
