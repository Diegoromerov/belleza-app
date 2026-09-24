-- ====================================================================
-- MIGRATION 077: B2C BOOKING TRACKING LOGS & AUDIT RETENTION
-- Node Contract — N02 Implementation
-- Canonical Design N02-T16-R2
-- Transactional, Idempotent, Spatial GiST & Non-Breaking for SaaS
-- ====================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS public.booking_tracking_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL,
    provider_id INTEGER NOT NULL,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    accuracy_meters NUMERIC(6, 2),
    captured_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tracking_logs_booking 
        FOREIGN KEY (booking_id) 
        REFERENCES public.bookings(id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_tracking_logs_provider 
        FOREIGN KEY (provider_id) 
        REFERENCES public.perfiles_prestador(id) 
        ON DELETE RESTRICT,

    CONSTRAINT chk_tracking_accuracy 
        CHECK (accuracy_meters IS NULL OR accuracy_meters >= 0.00)
);

-- Índices para búsqueda cronológica y espacial
CREATE INDEX IF NOT EXISTS idx_tracking_logs_booking_captured 
    ON public.booking_tracking_logs(booking_id, captured_at DESC);

CREATE INDEX IF NOT EXISTS idx_tracking_logs_created_at 
    ON public.booking_tracking_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_tracking_logs_spatial 
    ON public.booking_tracking_logs USING GIST(location);

COMMIT;
