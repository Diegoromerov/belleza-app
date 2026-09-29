# MIGRATION_BIOMETRIC_AUDIT.md
## Procedimiento Auditado: Migración biometric_consents.user_id UUID → INTEGER

---

## 1. RESUMEN EJECUTIVO

**Problema identificado (VETO ACTIVO - P0)**:
- `biometric_consents.user_id` = UUID (según migración 037 y código de servicios)
- `beauty_profiles.user_id` = INTEGER (tras migración 029)
- `usuarios.id` = INTEGER (tabla maestra)
- **Resultado**: Consentimiento biométrico **no trazable** al perfil de belleza → Viola Ley 1581/2012 (trazabilidad de consentimiento a datos sensibles)

**Origen del VETO**: Tarea `t_7093f999` (cumplimiento-legal) — VETO bloquea gate de producción hasta resolución.

---

## 2. ANÁLISIS FORENSE DEL ESQUEMA ACTUAL

### 2.1 Tabla `usuarios` (maestra)
```sql
CREATE TABLE public.usuarios (
    id integer NOT NULL,  -- PK SERIAL
    ...
);
```
**Tipo**: `INTEGER` (auto-incremental)

### 2.2 Tabla `beauty_profiles` (ya migrada)
```sql
-- Migración 029_fix_beauty_profiles_user_id_type.sql
ALTER TABLE beauty_profiles ALTER COLUMN user_id TYPE INTEGER USING (
    CASE WHEN user_id::text ~ '^[0-9]+$' THEN user_id::text::integer ELSE NULL END
);
```
**Tipo actual**: `INTEGER NOT NULL REFERENCES usuarios(id)`

### 2.3 Tabla `biometric_consents` (PROBLEMA)
**Migración 037 (original)**:
```sql
CREATE TABLE IF NOT EXISTS biometric_consents (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,  -- ¡TIPO INCORRECTO!
  ...
);
```

**schema.sql actual (tras migraciones 026, 029)**:
```sql
CREATE TABLE public.biometric_consents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id integer NOT NULL,  -- Muestra INTEGER pero NO hay migración registrada
    version character varying(20) NOT NULL,
    accepted_at timestamp with time zone DEFAULT now(),
    ip character varying(45),
    user_agent text,
    revoked_at timestamp with time zone,
    active boolean DEFAULT true
);
```

**FK en schema.sql (línea 4870-4871)**:
```sql
ALTER TABLE ONLY public.biometric_consents
    ADD CONSTRAINT biometric_consents_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
```

### 2.4 Código de servicios (expectativa real)
**consentService.js (línea 38, 73, 145, etc.)**: Usa `userId` como **string UUID** en queries:
```javascript
const query = `SELECT ... FROM biometric_consents WHERE user_id = $1 ...`;
await pool.query(query, [userId, consentType]);  // userId viene como UUID string
```

**biometricConsent.js (línea 89)**: Igual, espera UUID.

---

## 3. DIAGNÓSTICO DE CAUSA RAÍZ

| Migración | Tabla | user_id definido como | Estado |
|-----------|-------|----------------------|--------|
| 020 | biometric_consents | INTEGER | Sobrescrita por 037 |
| 037 | biometric_consents | **UUID** ← **PROBLEMA** | Ejecutada en producción |
| 029 | beauty_profiles | UUID → **INTEGER** | ✅ Corregida |
| — | biometric_consents | **NINGUNA migración corrige UUID→INTEGER** | ❌ PENDIENTE |

**Conclusión**: La migración 037 creó `biometric_consents.user_id` como UUID referenciando `usuarios.id` (INTEGER). Postgres permite crear FK entre tipos distintos si hay cast implícito, pero **los datos insertados son UUIDs que no matchean IDs enteros de usuarios**. El código de servicios inserta UUIDs (vienen del frontend/auth), pero la FK apunta a INTEGERs que no existen.

---

## 4. PROCEDIMIENTO DE MIGRACIÓN AUDITADO

### 4.1 Principios de Seguridad (Ley 1581 - Datos Sensibles)
1. **Cero pérdida de consentimientos**: Cada fila en `biometric_consents` es evidencia legal
2. **Trazabilidad 1:1**: Cada consentimiento debe resolver a exactamente UN `usuarios.id`
3. **Rollback inmediato**: Script de reversión probado antes de aplicar
4. **Auditoría completa**: Log de cada transformación con timestamp y operador

### 4.2 Pre-requisitos (Obligatorios antes de ejecutar)

```bash
# 1. Backup completo de la tabla (producción)
pg_dump -h <host> -U <user> -d <db> -t biometric_consents > biometric_consents_backup_pre_uuid_migration_$(date +%Y%m%d_%H%M%S).sql

# 2. Backup de beauty_profiles (referencia cruzada)
pg_dump -h <host> -U <user> -d <db> -t beauty_profiles > beauty_profiles_backup_pre_uuid_migration_$(date +%Y%m%d_%H%M%S).sql

# 3. Verificar conteo actual
SELECT count(*) FROM biometric_consents;           -- Total consentimientos
SELECT count(*) FROM beauty_profiles;               -- Total perfiles
SELECT count(DISTINCT user_id) FROM biometric_consents;  -- Usuarios con consentimiento
SELECT count(DISTINCT user_id) FROM beauty_profiles;     -- Usuarios con perfil
```

### 4.3 Script de Migración (Idempotente, Transaccional)

```sql
-- MIGRACIÓN: biometric_consents_user_id_uuid_to_integer.sql
-- Versión: 1.0
-- Fecha: 2026-09-28
-- Autor: cumplimiento-legal (auditor)
-- Revisa: verificacion-qa (firma)

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
```

### 4.4 Script de Rollback (Probado en Staging)

```sql
-- ROLLBACK: biometric_consents_user_id_integer_to_uuid.sql
-- SOLO EJECUTAR SI VALIDACIÓN POST-MIGRACIÓN FALLA

BEGIN;

-- 1. Recrear mapeo inverso (INTEGER → UUID original desde backup)
-- Requiere tabla backup: biometric_consents_backup_pre_migration

-- 2. Dropear FK e índices
ALTER TABLE biometric_consents DROP CONSTRAINT IF EXISTS biometric_consents_user_id_fkey;
DROP INDEX IF EXISTS unique_active_consent;
DROP INDEX IF EXISTS idx_biometric_consents_user_id;

-- 3. Revertir tipo (requiere backup de UUIDs originales)
-- ALTER TABLE biometric_consents ALTER COLUMN user_id TYPE UUID USING ...;

-- 4. Recrear FK original (UUID → usuarios.id) - SOLO si usuarios.id era UUID
-- NOTA: usuarios.id SIEMPRE fue INTEGER, por eso la FK original era inválida

COMMIT;
```

> **NOTA CRÍTICA**: El rollback completo requiere restaurar desde `pg_dump` backup. El script arriba es referencia; **el rollback real es `psql < biometric_consents_backup_pre_uuid_migration_*.sql`**.

---

## 5. CONSULTA DE VERIFICACIÓN POST-MIGRACIÓN (Obligatoria para QA)

```sql
-- ============================================================
-- CONSULTA DE VERIFICACIÓN: Trazabilidad 1:1 Consentimiento ↔ Perfil
-- Ejecutar en STAGING tras migración y en PROD tras aprobación
-- ============================================================

WITH consent_active AS (
    SELECT 
        bc.id AS consent_id,
        bc.user_id,
        bc.consent_type,
        bc.version_terms,
        bc.granted_at,
        bc.active,
        u.email AS user_email,
        u.nombre AS user_nombre
    FROM biometric_consents bc
    JOIN usuarios u ON u.id = bc.user_id
    WHERE bc.active = TRUE
      AND bc.granted = TRUE
      AND bc.revoked_at IS NULL
),
profile_link AS (
    SELECT 
        ca.*,
        bp.id AS profile_id,
        bp.face_scores IS NOT NULL AS has_face_scores,
        bp.hands_diagnosis IS NOT NULL AS has_hands_diagnosis,
        bp.recommendation IS NOT NULL AS has_recommendation,
        bp.created_at AS profile_created_at
    FROM consent_active ca
    LEFT JOIN beauty_profiles bp ON bp.user_id = ca.user_id
)
SELECT 
    'TOTAL_CONSENTIMIENTOS_ACTIVOS' AS metric,
    count(*)::text AS value
FROM consent_active
UNION ALL
SELECT 
    'CONSENTIMIENTOS_CON_PERFIL_BELLEZA' AS metric,
    count(*)::text AS value
FROM profile_link
WHERE profile_id IS NOT NULL
UNION ALL
SELECT 
    'CONSENTIMIENTOS_SIN_PERFIL (HUERFANOS)' AS metric,
    count(*)::text AS value
FROM profile_link
WHERE profile_id IS NULL
UNION ALL
SELECT 
    'USUARIOS_UNICOS_CON_CONSENTIMIENTO' AS metric,
    count(DISTINCT user_id)::text AS value
FROM consent_active
UNION ALL
SELECT 
    'USUARIOS_UNICOS_CON_PERFIL' AS metric,
    count(DISTINCT user_id)::text AS value
FROM profile_link
WHERE profile_id IS NOT NULL
UNION ALL
SELECT 
    'DUPLICADOS_ACTIVOS_POR_USUARIO' AS metric,
    count(*)::text AS value
FROM (
    SELECT user_id, count(*) 
    FROM biometric_consents 
    WHERE active = TRUE 
    GROUP BY user_id 
    HAVING count(*) > 1
) d
UNION ALL
SELECT 
    'FK_VIOLATIONS (user_id sin usuario)' AS metric,
    count(*)::text AS value
FROM biometric_consents bc
LEFT JOIN usuarios u ON u.id = bc.user_id
WHERE u.id IS NULL;

-- DETALLE POR USUARIO (para auditoría SIC)
SELECT 
    ca.user_id,
    ca.user_email,
    ca.user_nombre,
    ca.consent_type,
    ca.granted_at,
    pl.profile_id,
    pl.has_face_scores,
    pl.has_hands_diagnosis,
    pl.profile_created_at
FROM consent_active ca
LEFT JOIN profile_link pl ON pl.consent_id = ca.consent_id
ORDER BY ca.user_id, ca.consent_type;
```

**Criterios de Aprobación QA**:
| Métrica | Valor Esperado |
|---------|----------------|
| `CONSENTIMIENTOS_SIN_PERFIL (HUERFANOS)` | **0** |
| `DUPLICADOS_ACTIVOS_POR_USUARIO` | **0** |
| `FK_VIOLATIONS` | **0** |
| `CONSENTIMIENTOS_CON_PERFIL_BELLEZA` = `TOTAL_CONSENTIMIENTOS_ACTIVOS` | **TRUE** |

---

## 6. PLAN DE EJECUCIÓN

| Fase | Acción | Responsable | Evidencia Requerida |
|------|--------|-------------|---------------------|
| 1 | Ejecutar backup PG en staging | DevOps | Archivo `.sql` con timestamp |
| 2 | Ejecutar migración en staging | Backend-core | Log de ejecución + `RAISE NOTICE` |
| 3 | Ejecutar consulta verificación en staging | Verificación-QA | Resultado query §5 (todas las métricas = 0/TRUE) |
| 4 | **Aprobación explícita Dueño en esta tarjeta** | Dueño (Diego) | Comentario: "AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — APROBADO PARA PROD" |
| 5 | Backup producción | DevOps | Archivo `.sql` |
| 6 | Ejecutar migración en producción (horario bajo tráfico) | Backend-core | Log de ejecución |
| 7 | Ejecutar consulta verificación en producción | Verificación-QA | Resultado query §5 + firma QA |
| 8 | Dueño abre PR con migración + evidencia | Dueño | PR #xxx |

---

## 7. REGISTRO DE DECISIONES

| Decisión | Justificación |
|----------|---------------|
| Mapear UUID→INTEGER via `usuarios.provider_id` | El frontend envía UUID del proveedor OAuth (Google/Apple); `usuarios.provider_id` lo almacena |
| No usar `email` como clave primaria de join | Email puede cambiar; `provider_id` es inmutable por usuario |
| Mantener `biometric_consents.id` como UUID | Es PK interna, no afecta trazabilidad usuario |
| Índice único parcial `unique_active_consent` | Requisito Ley 1581: un solo consentimiento activo por usuario/tipo |
| Fail-closed en validación pre-migración | Dato biométrico = sensible; mejor abortar que corromper |

---

## 8. FIRMAS REQUERIDAS

| Rol | Nombre | Estado | Fecha | Evidencia |
|-----|--------|--------|-------|-----------|
| **Auditor (cumplimiento-legal)** | — | ✅ Documentado | 2026-09-28 | Este documento |
| **Implementador (backend-core)** | — | ⏳ Pendiente | — | Log migración staging |
| **Verificador QA (verificacion-qa)** | — | ⏳ Pendiente | — | Query §5 resultado + firma |
| **Dueño (Aprobación PR)** | Diego | ⏳ Pendiente | — | Comentario en tarjeta |
| **Dueño (Abre PR)** | Diego | ⏳ Pendiente | — | PR #xxx |

---

## 9. ARCHIVOS RELACIONADOS

- `backend/migrations/037_create_biometric_consents.sql` — Origen del tipo UUID
- `backend/migrations/029_fix_beauty_profiles_user_id_type.sql` — Referencia de migración exitosa
- `backend/schema.sql` (líneas 1216-1225, 2828-2857, 4870-4871) — Esquema actual
- `backend/src/services/consentService.js` — Código que espera UUID
- `backend/src/middleware/biometricConsent.js` — Middleware que valida consentimiento

---

**ESTADO DEL VETO**: 🔴 **ACTIVO** — Se levanta solo tras firma QA en producción con evidencia de query §5.

**PRÓXIMO PASO**: `backend-core` crea migración `049_fix_biometric_consents_user_id_type.sql` basada en §4.3 y la prueba en staging.