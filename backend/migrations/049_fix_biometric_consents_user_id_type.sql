-- MIGRACIÓN: biometric_consents_user_id_uuid_to_integer.sql
-- Versión: 1.1 (Resiliente a IDs mixtos UUID/INTEGER)
-- Fecha: 2026-09-29
-- Autor: cumplimiento-legal (auditor) / backend-core (implementador)
-- Revisa: verificacion-qa (firma)

BEGIN;

-- ============================================================
-- PASO 1: Validación pre-migración (FAIL FAST si no pasa)
-- ============================================================
DO $$
DECLARE
    v_col_type text;
    v_invalid_pattern_mismatch integer;
BEGIN
    SELECT data_type INTO v_col_type
    FROM information_schema.columns
    WHERE table_name = 'biometric_consents' AND column_name = 'user_id';

    IF v_col_type = 'integer' OR v_col_type = 'bigint' THEN
        RAISE NOTICE 'PRE-CHECK SKIPPED: biometric_consents.user_id ya es de tipo INTEGER (%)', v_col_type;
        RETURN;
    END IF;

    -- Contar consentimientos cuyo user_id NO es ni UUID ni entero
    SELECT count(*) INTO v_invalid_pattern_mismatch
    FROM biometric_consents
    WHERE user_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      AND user_id::text !~ '^[0-9]+$';
    
    IF v_invalid_pattern_mismatch > 0 THEN
        RAISE EXCEPTION 'PRE-CHECK FAILED: % consentimientos tienen user_id con formato inválido (ni UUID ni INTEGER).', v_invalid_pattern_mismatch;
    END IF;
    
    RAISE NOTICE 'PRE-CHECK PASSED: % consentimientos validados con formato UUID/INTEGER', 
        (SELECT count(*) FROM biometric_consents);
END $$;

-- ============================================================
-- PASO 2: Crear tabla de mapeo UUID / STRING -> INTEGER
-- ============================================================
CREATE TEMP TABLE IF NOT EXISTS tmp_uuid_to_integer_map AS
SELECT 
    bc.user_id AS uuid_user_id,
    u.id AS integer_user_id,
    u.email
FROM biometric_consents bc
JOIN usuarios u ON u.id::text = bc.user_id::text
WHERE bc.user_id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   OR bc.user_id::text ~ '^[0-9]+$';

INSERT INTO tmp_uuid_to_integer_map (uuid_user_id, integer_user_id, email)
SELECT 
    bc.user_id,
    u.id,
    u.email
FROM biometric_consents bc
JOIN usuarios u ON u.provider_id = bc.user_id::text
WHERE (bc.user_id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' OR bc.user_id::text ~ '^[0-9]+$')
  AND NOT EXISTS (SELECT 1 FROM tmp_uuid_to_integer_map m WHERE m.uuid_user_id = bc.user_id);

-- Verificar cobertura del mapeo
DO $$
DECLARE
    v_col_type text;
    v_total_consents integer;
    v_mapped_consents integer;
BEGIN
    SELECT data_type INTO v_col_type
    FROM information_schema.columns
    WHERE table_name = 'biometric_consents' AND column_name = 'user_id';

    IF v_col_type = 'integer' OR v_col_type = 'bigint' THEN
        RETURN;
    END IF;

    SELECT count(*) INTO v_total_consents FROM biometric_consents;
    SELECT count(DISTINCT bc.id) INTO v_mapped_consents
    FROM biometric_consents bc
    JOIN tmp_uuid_to_integer_map m ON m.uuid_user_id = bc.user_id;
    
    IF v_mapped_consents < v_total_consents THEN
        RAISE EXCEPTION 'MAPEO INCOMPLETO: % de % consentimientos mapeados. Faltan: %', 
            v_mapped_consents, v_total_consents, v_total_consents - v_mapped_consents;
    END IF;
    
    RAISE NOTICE 'MAPEO COMPLETO: % consentimientos mapeados a usuarios INTEGER', v_mapped_consents;
END $$;

-- ============================================================
-- PASO 3: Eliminar FK existente (si existe)
-- ============================================================
ALTER TABLE biometric_consents 
DROP CONSTRAINT IF EXISTS biometric_consents_user_id_fkey;

-- ============================================================
-- PASO 4: Alterar columna user_id de UUID a INTEGER si es necesario
-- ============================================================
DO $$
DECLARE
    v_col_type text;
BEGIN
    SELECT data_type INTO v_col_type
    FROM information_schema.columns
    WHERE table_name = 'biometric_consents' AND column_name = 'user_id';

    IF v_col_type != 'integer' AND v_col_type != 'bigint' THEN
        EXECUTE 'ALTER TABLE biometric_consents ALTER COLUMN user_id TYPE INTEGER USING (SELECT m.integer_user_id FROM tmp_uuid_to_integer_map m WHERE m.uuid_user_id = biometric_consents.user_id)';
    END IF;
END $$;

-- ============================================================
-- PASO 5: Recrear FK hacia usuarios.id (INTEGER)
-- ============================================================
ALTER TABLE biometric_consents
DROP CONSTRAINT IF EXISTS biometric_consents_user_id_fkey;

ALTER TABLE biometric_consents
ADD CONSTRAINT biometric_consents_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- ============================================================
-- PASO 6: Recrear índice único parcial (consentimiento activo)
-- ============================================================
DROP INDEX IF EXISTS unique_active_consent;
CREATE UNIQUE INDEX unique_active_consent ON biometric_consents (user_id) WHERE active = TRUE;

-- ============================================================
-- PASO 7: Recrear índice de rendimiento
-- ============================================================
DROP INDEX IF EXISTS idx_biometric_consents_user_id;
CREATE INDEX idx_biometric_consents_user_id ON biometric_consents(user_id);

-- ============================================================
-- PASO 8: Limpiar tabla temporal si fue creada
-- ============================================================
DROP TABLE IF EXISTS tmp_uuid_to_integer_map;

COMMIT;