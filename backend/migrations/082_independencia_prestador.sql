-- ============================================================
-- MIGRACIÓN 082: Independencia del prestador y contrato de comisión
-- Fase F8 del plan de implementación
--
-- La plataforma retenía el 20% a 11 prestadores sin contrato aceptado y sin
-- aceptación de independencia laboral. Sin esos dos registros no hay forma de
-- probar que el vínculo es comercial y no laboral.
--
-- Además: `regimen_iva` (los 11 prestadores estaban en ORDINARIO por defecto sin
-- validación) y `cancelaciones_tardias` para la regla de 3 en 90 días.
-- ============================================================

BEGIN;

ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS contrato_version      VARCHAR(20);
ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS contrato_aceptado_at  TIMESTAMPTZ;
ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS contrato_aceptado_ip  TEXT;
ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS independencia_aceptada_at TIMESTAMPTZ;
ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS regimen_iva           VARCHAR(30)
  DEFAULT 'NO_RESPONSABLE';
ALTER TABLE perfiles_prestador ADD COLUMN IF NOT EXISTS cancelaciones_tardias INTEGER NOT NULL DEFAULT 0;

-- Marca de tiempo de la cancelación: la regla de 3 en 90 días necesita una fecha,
-- no solo un contador acumulado.
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS cancelado_at TIMESTAMPTZ;

COMMENT ON COLUMN perfiles_prestador.contrato_version IS
  'Versión del contrato de comisión aceptada. NULL = nunca aceptó.';
COMMENT ON COLUMN perfiles_prestador.independencia_aceptada_at IS
  'Fecha de aceptación de la cláusula de independencia laboral (prestador, no empleado).';
COMMENT ON COLUMN perfiles_prestador.regimen_iva IS
  'NO_RESPONSABLE (persona natural SIMPLE <3.500 UVT) | RESPONSABLE | SIMPLE';

COMMIT;
