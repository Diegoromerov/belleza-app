-- ====================================================================
-- MIGRATION 065: SAAS FOUNDATION CORE (HARDENED & FINALIZED)
-- Node Contract — SaaS Foundation v1.0
-- Architecture: TENANT -> ORGANIZATION -> ESTABLISHMENT -> MEMBERSHIP
-- Fully Idempotent, Transactional & Cross-Tenant Protected
-- ====================================================================

BEGIN;

-- 1. Extensiones requeridas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Tabla de control schema_migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  id SERIAL PRIMARY KEY,
  filename VARCHAR(255) UNIQUE NOT NULL,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla ORGANIZATIONS (Capa Legal / Tributaria SaaS)
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(50), -- NIT / RUT
    billing_email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_organization_id_tenant UNIQUE (id, tenant_id)
);

-- 4. Tabla ESTABLISHMENTS (Unidad Operativa y Comercial Unificada)
CREATE TABLE IF NOT EXISTS establishments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    organization_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(30),
    address TEXT,
    city VARCHAR(100) DEFAULT 'Bogotá',
    location GEOGRAPHY(Point, 4326),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_establishment_organization FOREIGN KEY (organization_id, tenant_id) 
        REFERENCES organizations(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT uq_establishment_id_tenant UNIQUE (id, tenant_id)
);

-- 5. Integridad de Afinidad de Usuario: UNIQUE (id, tenant_id) en usuarios
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_usuarios_id_tenant'
    ) THEN
        ALTER TABLE usuarios ADD CONSTRAINT uq_usuarios_id_tenant UNIQUE (id, tenant_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'usuarios_tenant_id_fkey'
    ) THEN
        ALTER TABLE usuarios ADD CONSTRAINT usuarios_tenant_id_fkey 
            FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT;
    END IF;
END $$;

-- 6. Tabla MEMBERSHIPS (Vínculo Contextual Identity <-> Establishment con Doble FK Compuesta y ON DELETE RESTRICT)
CREATE TABLE IF NOT EXISTS memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    establishment_id UUID NOT NULL,
    user_id INTEGER NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST')),
    relation_type VARCHAR(50) NOT NULL DEFAULT 'STAFF_EMPLOYEE' CHECK (relation_type IN ('OWNER_PARTNER', 'STAFF_EMPLOYEE', 'INDEPENDENT_PROVIDER')),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_membership_establishment FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_membership_user_tenant FOREIGN KEY (user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT uq_membership_establishment_user UNIQUE (establishment_id, user_id)
);

-- 7. Índices de Rendimiento y Búsqueda Espacial
CREATE INDEX IF NOT EXISTS idx_organizations_tenant_id ON organizations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_establishments_tenant_id ON establishments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_establishments_organization_id ON establishments(organization_id);
CREATE INDEX IF NOT EXISTS idx_establishments_location ON establishments USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_memberships_tenant_id ON memberships(tenant_id);
CREATE INDEX IF NOT EXISTS idx_memberships_user_id ON memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_establishment_id ON memberships(establishment_id);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON memberships(status);

-- 8. Aislamiento Row-Level Security (RLS) con soporte USING y WITH CHECK
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_organizations ON organizations;
CREATE POLICY tenant_isolation_organizations ON organizations
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);

ALTER TABLE establishments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_establishments ON establishments;
CREATE POLICY tenant_isolation_establishments ON establishments
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);

ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_memberships ON memberships;
CREATE POLICY tenant_isolation_memberships ON memberships
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);

-- 9. Población Semilla Inicial de DEMOSTRACIÓN (Clasificada: DEMO DATA para Tenant 2)
DO $$
DECLARE
    v_tenant_id INTEGER := 2;
    v_user_id INTEGER := 7;
    v_org_id UUID;
    v_est_id UUID;
BEGIN
    -- Verificar si existe Tenant 2 y Usuario 7
    IF EXISTS (SELECT 1 FROM tenants WHERE id = v_tenant_id) AND EXISTS (SELECT 1 FROM usuarios WHERE id = v_user_id) THEN
        
        -- 9.1 Organización Demo
        SELECT id INTO v_org_id FROM organizations WHERE tenant_id = v_tenant_id LIMIT 1;
        IF v_org_id IS NULL THEN
            INSERT INTO organizations (tenant_id, legal_name, tax_id, billing_email)
            VALUES (v_tenant_id, 'Luxe Beauty Group S.A.S. (Demo)', '901888777-1', 'salon@beautyapp.com')
            RETURNING id INTO v_org_id;
        END IF;

        -- 9.2 Establecimiento Demo
        SELECT id INTO v_est_id FROM establishments WHERE organization_id = v_org_id LIMIT 1;
        IF v_est_id IS NULL THEN
            INSERT INTO establishments (
                tenant_id, organization_id, name, slug, phone, address, city, location, is_active, is_public, operating_hours
            ) VALUES (
                v_tenant_id,
                v_org_id,
                'Salón Elegance Studio Chicó (Demo)',
                'elegance-studio-chico',
                '+573109998877',
                'Calle 127 # 7-18',
                'Bogotá',
                ST_SetSRID(ST_MakePoint(-74.0325, 4.7012), 4326),
                TRUE,
                TRUE,
                '{"lunes":{"activo":true,"inicio":8,"fin":20},"martes":{"activo":true,"inicio":8,"fin":20},"miercoles":{"activo":true,"inicio":8,"fin":20},"jueves":{"activo":true,"inicio":8,"fin":20},"viernes":{"activo":true,"inicio":8,"fin":20},"sabado":{"activo":true,"inicio":9,"fin":18},"domingo":{"activo":false,"inicio":0,"fin":0}}'::jsonb
            )
            RETURNING id INTO v_est_id;
        END IF;

        -- 9.3 Membresía Demo para Usuario 7 como OWNER / OWNER_PARTNER
        INSERT INTO memberships (
            tenant_id, establishment_id, user_id, role, relation_type, status
        ) VALUES (
            v_tenant_id,
            v_est_id,
            v_user_id,
            'OWNER',
            'OWNER_PARTNER',
            'ACTIVE'
        )
        ON CONFLICT (establishment_id, user_id) DO NOTHING;

    END IF;
END $$;

COMMIT;
