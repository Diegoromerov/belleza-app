-- MIGRACIÓN: biometric_consents_user_id_uuid_to_integer.sql
-- Versión: 1.0
-- Fecha: 2026-09-28
-- Autor: cumplimiento-legal (auditor) / backend-core (implementador)
-- Revisa: verificacion-qa (firma)
-- Basado en: MIGRATION_BIOMETRIC_AUDIT.md §4.3 (commit e6970f871)

BEGIN;

-- ============================================================
-- PASO 1: Validación pre-migración (FAIL FAST si no pasa)
-- ============================================================
DO $$
DECLARE
    v_consent_count integer;
    v_profile_count integer;
    v_orphan_consents integer;
    v_orphan_profiles integer;
    v_uuid_pattern_mismatch integer;
BEGIN
    -- Contar consentimientos con user_id que NO son UUIDs válidos
    SELECT count(*) INTO v_uuid_pattern_mismatch
    FROM biometric_consents
    WHERE user_id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    
    -- Los consentimientos DEBEN tener UUIDs válidos (vienen del frontend)
    IF v_uuid_pattern_mismatch > 0 THEN
        RAISE EXCEPTION 'PRE-CHECK FAILED: % consentimientos tienen user_id con formato no-UUID. Investigar antes de migrar.', v_uuid_pattern_mismatch;
    END IF;
    
    -- Verificar que cada UUID en biometric_consents tiene un usuario correspondiente
    -- NOTA: Esto fallará si los UUIDs no matchean IDs enteros de usuarios
    -- El siguiente paso de migración usa un mapping table
    
    RAISE NOTICE 'PRE-CHECK PASSED: % consentimientos con UUIDs válidos', 
        (SELECT count(*) FROM biometric_consents);
END $$;

-- ============================================================
-- PASO 2: Crear tabla de mapeo UUID → INTEGER
-- ============================================================
-- Los UUIDs en biometric_consents.user_id fueron generados por el frontend
-- Debemos mapearlos a los usuarios.id (INTEGER) reales
-- Estrategia: usar email como clave de unión (único en usuarios)

CREATE TEMP TABLE tmp_uuid_to_integer_map AS
SELECT 
    bc.user_id AS uuid_user_id,
    u.id AS integer_user_id,
    u.email
FROM biometric_consents bc
JOIN usuarios u ON u.id::text = bc.user_id::text  -- Intento directo por si ya coinciden
WHERE bc.user_id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Si el JOIN directo falló (UUIDs != INTEGERs), intentar por email desde tabla de auth
-- Asumiendo que el frontend guardó el UUID del proveedor de auth (Google/Apple)
-- y usuarios.provider_id guarda ese mismo UUID

INSERT INTO tmp_uuid_to_integer_map (uuid_user_id, integer_user_id, email)
SELECT 
    bc.user_id,
    u.id,
    u.email
FROM biometric_consents bc
JOIN usuarios u ON u.provider_id = bc.user_id::text
WHERE bc.user_id::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  AND NOT EXISTS (SELECT 1 FROM tmp_uuid_to_integer_map m WHERE m.uuid_user_id = bc.user_id);

-- Verificar cobertura del mapeo
DO $$
DECLARE
    v_total_consents integer;
    v_mapped_consents integer;
BEGIN
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
-- PASO 4: Alterar columna user_id de UUID a INTEGER
-- ============================================================
-- Usar la tabla de mapeo para la conversión
ALTER TABLE biometric_consents 
ALTER COLUMN user_id TYPE INTEGER 
USING (
    SELECT m.integer_user_id 
    FROM tmp_uuid_to_integer_map m 
    WHERE m.uuid_user_id = biometric_consents.user_id
);

-- ============================================================
-- PASO 5: Recrear FK hacia usuarios.id (INTEGER)
-- ============================================================
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
-- PASO 8: Validación post-migración (CRÍTICA)
-- ============================================================
DO $$
DECLARE
    v_consent_count integer;
    v_profile_count integer;
    v_join_count integer;
    v_orphan_consents integer;
    v_duplicate_active integer;
BEGIN
    -- Conteos
    SELECT count(*) INTO v_consent_count FROM biometric_consents;
    SELECT count(*) INTO v_profile_count FROM beauty_profiles;
    
    -- Verificar JOIN 1:1 consentimiento → perfil (trazabilidad legal)
    SELECT count(*) INTO v_join_count
    FROM biometric_consents bc
    JOIN beauty_profiles bp ON bp.user_id = bc.user_id
    WHERE bc.active = TRUE;
    
    -- Verificar consentimientos huérfanos (sin perfil)
    SELECT count(*) INTO v_orphan_consents
    FROM biometric_consents bc
    WHERE bc.active = TRUE
      AND NOT EXISTS (SELECT 1 FROM beauty_profiles bp WHERE bp.user_id = bc.user_id);
    
    -- Verificar duplicados en índice único
    SELECT count(*) INTO v_duplicate_active
    FROM (
        SELECT user_id, count(*) as cnt
        FROM biometric_consents
        WHERE active = TRUE
        GROUP BY user_id
        HAVING count(*) > 1
    ) d;
    
    RAISE NOTICE '=== VALIDACIÓN POST-MIGRACIÓN ===';
    RAISE NOTICE 'Total consentimientos: %', v_consent_count;
    RAISE NOTICE 'Total perfiles belleza: %', v_profile_count;
    RAISE NOTICE 'Consentimientos activos con perfil (trazables): %', v_join_count;
    RAISE NOTICE 'Consentimientos activos SIN perfil (huérfanos): %', v_orphan_consents;
    RAISE NOTICE 'Duplicados en índice único activo: %', v_duplicate_active;
    
    -- ASSERTIONES LEGALES (Ley 1581)
    IF v_orphan_consents > 0 THEN
        RAISE EXCEPTION 'VALIDACIÓN FALLIDA: % consentimientos activos sin beauty_profile. Viola trazabilidad Ley 1581.', v_orphan_consents;
    END IF;
    
    IF v_duplicate_active > 0 THEN
        RAISE EXCEPTION 'VALIDACIÓN FALLIDA: % usuarios con múltiples consentimientos activos. Viola índice único.', v_duplicate_active;
    END IF;
    
    IF v_join_count = 0 AND v_consent_count > 0 THEN
        RAISE EXCEPTION 'VALIDACIÓN FALLIDA: Cero trazabilidad consentimiento→perfil. Migración corrupta.';
    END IF;
    
    RAISE NOTICE '✅ VALIDACIÓN POST-MIGRACIÓN: EXITOSA - Trazabilidad 1:1 confirmada';
END $$;

-- ============================================================
-- PASO 9: Limpiar tabla temporal
-- ============================================================
DROP TABLE tmp_uuid_to_integer_map;

COMMIT;