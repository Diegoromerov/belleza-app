-- backend/migrations/075_saas_cash_drawer.sql
-- GO-08.47 / GO-08.49: Dominio Cash Drawer / Caja SaaS v1.0

BEGIN;

-- ------------------------------------------------------------
-- 1. Tabla: saas_cash_sessions (Turnos e intervalos de caja)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_cash_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    
    -- Apertura
    opened_by_membership_id UUID NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    opening_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    
    -- Estado de la Sesión
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    
    -- Cierre y Arqueo
    closed_by_membership_id UUID,
    closed_at TIMESTAMPTZ,
    expected_cash NUMERIC(12, 2),
    counted_cash NUMERIC(12, 2),
    difference NUMERIC(12, 2),
    closing_notes TEXT,
    
    -- Timestamps de Auditoría
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad Compuesta
    CONSTRAINT fk_cash_sessions_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cash_sessions_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_cash_sessions_opener 
        FOREIGN KEY (opened_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_cash_sessions_closer 
        FOREIGN KEY (closed_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_cash_session_status CHECK (status IN ('OPEN', 'CLOSED')),
    CONSTRAINT chk_cash_session_opening_balance CHECK (opening_balance >= 0.00),
    CONSTRAINT chk_cash_session_closing_integrity CHECK (
        (status = 'OPEN' AND closed_at IS NULL AND counted_cash IS NULL) OR
        (status = 'CLOSED' AND closed_at IS NOT NULL AND closed_by_membership_id IS NOT NULL AND counted_cash IS NOT NULL)
    )
);

-- Índice Único Parcial: Máximo 1 sesión OPEN simultánea por establecimiento
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_open_cash_session_per_est 
    ON saas_cash_sessions(establishment_id, tenant_id) 
    WHERE status = 'OPEN';

CREATE INDEX IF NOT EXISTS idx_cash_sessions_establishment 
    ON saas_cash_sessions(establishment_id, tenant_id, opened_at DESC);

-- RLS para saas_cash_sessions
ALTER TABLE saas_cash_sessions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_cash_sessions' 
        AND policyname = 'tenant_isolation_saas_cash_sessions'
    ) THEN
        CREATE POLICY tenant_isolation_saas_cash_sessions 
            ON saas_cash_sessions
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Tabla: saas_cash_movements (Movimientos atómicos de efectivo)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_cash_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    
    -- Tipología y Categoría
    movement_type VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    reason TEXT NOT NULL,
    
    -- Trazabilidad y Origen
    performed_by_membership_id UUID NOT NULL,
    ticket_payment_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT fk_cash_movements_session 
        FOREIGN KEY (session_id) 
        REFERENCES saas_cash_sessions(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_cash_movements_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_cash_movements_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_cash_movements_performer 
        FOREIGN KEY (performed_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_cash_movements_ticket_payment 
        FOREIGN KEY (ticket_payment_id) 
        REFERENCES saas_ticket_payments(id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_cash_movement_type CHECK (movement_type IN ('CASH_SALE', 'CASH_IN', 'CASH_OUT')),
    CONSTRAINT chk_cash_movement_amount CHECK (amount > 0.00)
);

CREATE INDEX IF NOT EXISTS idx_cash_movements_session 
    ON saas_cash_movements(session_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_cash_movements_ticket_payment 
    ON saas_cash_movements(ticket_payment_id);

-- Idempotencia: Un pago de ticket solo puede originar máximo 1 movimiento de venta en efectivo
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_cash_movement_ticket_payment 
    ON saas_cash_movements(ticket_payment_id) 
    WHERE ticket_payment_id IS NOT NULL;

-- RLS para saas_cash_movements
ALTER TABLE saas_cash_movements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_cash_movements' 
        AND policyname = 'tenant_isolation_saas_cash_movements'
    ) THEN
        CREATE POLICY tenant_isolation_saas_cash_movements 
            ON saas_cash_movements
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 3. Registro en schema_migrations
-- ------------------------------------------------------------
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('075_saas_cash_drawer.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;
