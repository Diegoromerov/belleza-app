-- ====================================================================
-- MIGRATION 072: SAAS SERVICE TICKETS & CHECKOUT ENGINE
-- Node Contract — NODO-08 v1.0 (RATIFIED)
-- Physical Architecture Specification for SERVICE_TICKET, TICKET_ITEMS,
-- TICKET_PAYMENTS and ESTABLISHMENT_TICKET_SEQUENCES
-- Transactional, Idempotent, RLS Enabled & Composite Protected
-- ====================================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Tabla: saas_establishment_ticket_sequences (§7.4)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_establishment_ticket_sequences (
    establishment_id UUID PRIMARY KEY,
    last_sequence_number BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_seq_establishment
        FOREIGN KEY (establishment_id)
        REFERENCES establishments(id)
        ON DELETE CASCADE
);

-- RLS para saas_establishment_ticket_sequences
ALTER TABLE saas_establishment_ticket_sequences ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_establishment_ticket_sequences' 
        AND policyname = 'tenant_isolation_saas_establishment_ticket_sequences'
    ) THEN
        CREATE POLICY tenant_isolation_saas_establishment_ticket_sequences 
            ON saas_establishment_ticket_sequences
            FOR ALL
            USING (establishment_id IN (
                SELECT id FROM establishments 
                WHERE tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer
            ))
            WITH CHECK (establishment_id IN (
                SELECT id FROM establishments 
                WHERE tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer
            ));
    END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Tabla: saas_service_tickets (§7.1)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_service_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    ticket_number VARCHAR(30) NOT NULL,
    
    -- Origen Opcional de Cita Operacional (NODO-06)
    appointment_id UUID,
    
    -- Representación Dual de Cliente (XOR)
    client_mode VARCHAR(20) NOT NULL DEFAULT 'GUEST',
    customer_user_id INTEGER,
    guest_name_snapshot VARCHAR(150),
    guest_phone_snapshot VARCHAR(30),
    guest_email_snapshot VARCHAR(255),
    
    -- Máquina de Estados Financiera
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    
    -- Componentes Financieros Transaccionales (Server-Calculated)
    subtotal_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount_reason VARCHAR(255),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    tip_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    balance_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    
    -- Notas y Observaciones
    notes TEXT,
    
    -- Trazabilidad de Actores (Memberships)
    created_by_membership_id UUID NOT NULL,
    closed_by_membership_id UUID,
    voided_by_membership_id UUID,
    void_reason TEXT,
    
    -- Tiempos Transaccionales
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    voided_at TIMESTAMPTZ,
    
    -- Restricciones de Integridad
    CONSTRAINT fk_tickets_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_tickets_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_appointment 
        FOREIGN KEY (appointment_id) 
        REFERENCES saas_appointments(id) 
        ON DELETE SET NULL,
    CONSTRAINT fk_tickets_customer 
        FOREIGN KEY (customer_user_id, tenant_id) 
        REFERENCES usuarios(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_creator 
        FOREIGN KEY (created_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_closer 
        FOREIGN KEY (closed_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_tickets_voider 
        FOREIGN KEY (voided_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    -- Restricción de Unicidad de Folio por Establecimiento
    CONSTRAINT uq_ticket_number_per_establishment 
        UNIQUE (establishment_id, ticket_number),
    
    -- Restricción XOR de Cliente
    CONSTRAINT chk_ticket_client_mode CHECK (
        (client_mode = 'GUEST' AND customer_user_id IS NULL AND guest_name_snapshot IS NOT NULL) OR
        (client_mode = 'REGISTERED' AND customer_user_id IS NOT NULL AND guest_name_snapshot IS NULL AND guest_phone_snapshot IS NULL AND guest_email_snapshot IS NULL)
    ),
    
    -- Restricción de Estado
    CONSTRAINT chk_ticket_status CHECK (
        status IN ('DRAFT', 'OPEN', 'PAID', 'CLOSED', 'VOID')
    ),
    
    -- Restricciones Numéricas No Negativas
    CONSTRAINT chk_ticket_amounts_non_negative CHECK (
        subtotal_amount >= 0.00 AND
        discount_amount >= 0.00 AND
        tax_amount >= 0.00 AND
        tip_amount >= 0.00 AND
        total_amount >= 0.00 AND
        paid_amount >= 0.00 AND
        balance_due >= 0.00
    )
);

-- Índices Físicos
CREATE INDEX IF NOT EXISTS idx_tickets_tenant_id 
    ON saas_service_tickets(tenant_id);

CREATE INDEX IF NOT EXISTS idx_tickets_establishment_status 
    ON saas_service_tickets(establishment_id, status);

CREATE INDEX IF NOT EXISTS idx_tickets_created_at 
    ON saas_service_tickets(establishment_id, created_at DESC);

-- Índice Único Parcial: Máximo 1 Ticket Activo por Cita Operacional (FINDING-AUD-002)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tickets_active_appointment 
    ON saas_service_tickets(appointment_id) 
    WHERE appointment_id IS NOT NULL AND status != 'VOID';

-- RLS para saas_service_tickets
ALTER TABLE saas_service_tickets ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_service_tickets' 
        AND policyname = 'tenant_isolation_saas_service_tickets'
    ) THEN
        CREATE POLICY tenant_isolation_saas_service_tickets 
            ON saas_service_tickets
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 3. Tabla: saas_ticket_items (§7.2)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_ticket_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL,
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    
    -- Tipo de Ítem (DEC-08-01)
    item_type VARCHAR(20) NOT NULL DEFAULT 'SERVICE',
    service_offer_id UUID,
    
    -- Trazabilidad de Profesional Ejecutor Obligatoria
    performed_by_membership_id UUID NOT NULL,
    
    -- Snapshots y Tarifación Congelada
    title_snapshot VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price_snapshot NUMERIC(12, 2) NOT NULL,
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12, 2) NOT NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT fk_items_ticket 
        FOREIGN KEY (ticket_id) 
        REFERENCES saas_service_tickets(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_items_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_items_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_items_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_items_performer 
        FOREIGN KEY (performed_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_item_type CHECK (
        (item_type = 'SERVICE' AND service_offer_id IS NOT NULL) OR
        (item_type = 'CUSTOM' AND service_offer_id IS NULL)
    ),
    CONSTRAINT chk_item_quantity CHECK (quantity >= 1),
    CONSTRAINT chk_item_amounts CHECK (
        unit_price_snapshot >= 0.00 AND
        discount_amount >= 0.00 AND
        total_amount >= 0.00
    )
);

-- Índices Físicos
CREATE INDEX IF NOT EXISTS idx_items_ticket_id 
    ON saas_ticket_items(ticket_id);

CREATE INDEX IF NOT EXISTS idx_items_performer 
    ON saas_ticket_items(performed_by_membership_id);

CREATE INDEX IF NOT EXISTS idx_items_service_offer 
    ON saas_ticket_items(service_offer_id);

CREATE INDEX IF NOT EXISTS idx_items_tenant_establishment 
    ON saas_ticket_items(establishment_id, tenant_id);

-- RLS para saas_ticket_items
ALTER TABLE saas_ticket_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_ticket_items' 
        AND policyname = 'tenant_isolation_saas_ticket_items'
    ) THEN
        CREATE POLICY tenant_isolation_saas_ticket_items 
            ON saas_ticket_items
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 4. Tabla: saas_ticket_payments (§7.3)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saas_ticket_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL,
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    
    -- Método de Pago y Monto (DEC-08-02)
    payment_method VARCHAR(20) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    reference_code VARCHAR(100),
    
    -- Trazabilidad de Recepción
    received_by_membership_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Restricciones de Integridad
    CONSTRAINT fk_payments_ticket 
        FOREIGN KEY (ticket_id) 
        REFERENCES saas_service_tickets(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_payments_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_payments_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_payments_receiver 
        FOREIGN KEY (received_by_membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    CONSTRAINT chk_payment_method CHECK (
        payment_method IN ('CASH', 'CARD', 'TRANSFER', 'OTHER')
    ),
    CONSTRAINT chk_payment_amount CHECK (amount > 0.00)
);

-- Índices Físicos
CREATE INDEX IF NOT EXISTS idx_payments_ticket_id 
    ON saas_ticket_payments(ticket_id);

CREATE INDEX IF NOT EXISTS idx_payments_method 
    ON saas_ticket_payments(payment_method);

CREATE INDEX IF NOT EXISTS idx_payments_tenant_establishment 
    ON saas_ticket_payments(establishment_id, tenant_id);

-- RLS para saas_ticket_payments
ALTER TABLE saas_ticket_payments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'saas_ticket_payments' 
        AND policyname = 'tenant_isolation_saas_ticket_payments'
    ) THEN
        CREATE POLICY tenant_isolation_saas_ticket_payments 
            ON saas_ticket_payments
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- ------------------------------------------------------------
-- 5. Registro en schema_migrations
-- ------------------------------------------------------------
INSERT INTO schema_migrations (filename, applied_at)
VALUES ('072_saas_service_tickets.sql', CURRENT_TIMESTAMP)
ON CONFLICT (filename) DO NOTHING;

COMMIT;

