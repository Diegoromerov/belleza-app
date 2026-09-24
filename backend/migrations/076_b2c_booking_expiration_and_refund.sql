-- ====================================================================
-- MIGRATION 076: B2C BOOKING EXPIRATION & REFUND OUTBOX
-- Node Contract — N01 Implementation
-- Canonical Design T16-R
-- Idempotent, Transactional & Non-Breaking for SaaS
-- ====================================================================

BEGIN;

-- 1. Asegurar columna paid_at y motivo_cancelacion en public.bookings
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'bookings' 
          AND column_name = 'paid_at'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN paid_at TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'bookings' 
          AND column_name = 'motivo_cancelacion'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN motivo_cancelacion VARCHAR(100);
    END IF;
END $$;

-- 2. Índice para acelerar la búsqueda de reservas expirables por el worker
CREATE INDEX IF NOT EXISTS idx_bookings_expiration_eval 
    ON public.bookings(estado, paid_at) 
    WHERE estado = 'CONFIRMADA' AND paid_at IS NOT NULL;

-- 3. Crear Tabla refund_outbox
CREATE TABLE IF NOT EXISTS public.refund_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL,
    transaction_id VARCHAR(100),
    amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ,

    CONSTRAINT fk_refund_outbox_booking 
        FOREIGN KEY (booking_id) 
        REFERENCES public.bookings(id) 
        ON DELETE RESTRICT,

    CONSTRAINT uq_refund_outbox_booking 
        UNIQUE (booking_id),

    CONSTRAINT chk_refund_outbox_status 
        CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'RETRYABLE_FAILURE', 'FINAL_FAILURE')),

    CONSTRAINT chk_refund_outbox_amount 
        CHECK (amount >= 0.00)
);

-- 4. Índices para el worker de procesamiento de reembolsos
CREATE INDEX IF NOT EXISTS idx_refund_outbox_worker 
    ON public.refund_outbox(status, attempts, created_at ASC) 
    WHERE status IN ('PENDING', 'RETRYABLE_FAILURE');

COMMIT;
