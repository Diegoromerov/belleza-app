-- ============================================================================
-- 069_force_rls_strict_isolation.sql
-- A360-2026-09-22/C-09 — RLS inerte.
--
-- POR QUÉ ESTÁ EN migrations/manual/ Y NO EN migrations/:
--   El runner de arranque aplica TODO lo que hay en `backend/migrations/`.
--   Activar FORCE ROW LEVEL SECURITY sin que TODAS las rutas de datos fijen el
--   contexto de tenant hace que `tenant_id = current_setting('app.tenant_id', true)`
--   evalúe a NULL y **cada consulta devuelva 0 filas** en las tablas afectadas.
--   Esta app tiene DOS caminos de datos (el pool crudo de db.js y Sequelize), y el
--   segundo NO pasa por `authMiddleware`, así que se aplica en una ventana
--   planificada, con mediciones antes/después. Ver README.md de esta carpeta.
--
-- QUÉ ARREGLA:
--   1. `ENABLE ROW LEVEL SECURITY` sin `FORCE`: el dueño de las tablas (que es la
--      propia app, porque las crea al arrancar) BYPASSEA las políticas. Medido en la
--      auditoría: `force=false` en las tablas con tenant.
--   2. La política única usaba `current_setting('app.tenant_id')` SIN `missing_ok`,
--      lo que lanza `unrecognized configuration parameter` cuando no hay contexto.
--   3. No existía `WITH CHECK`, así que las escrituras no se validaban.
--
-- IDEMPOTENTE: se puede re-ejecutar sin daño.
-- ============================================================================

-- 1) Función de contexto segura: NULL si no hay contexto (en vez de lanzar error).
CREATE OR REPLACE FUNCTION app_current_tenant_id() RETURNS integer AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::integer
$$ LANGUAGE sql STABLE;

-- 2) Tablas con columna tenant_id que deben quedar aisladas.
--    (Ajustar si el esquema real difiere; la consulta de verificación del README lista
--     las que realmente tienen la columna.)
DO $$
DECLARE
  t text;
  tablas text[] := ARRAY[
    'usuarios', 'servicios', 'bookings', 'transactions', 'reviews',
    'portfolio_items', 'messages', 'memberships', 'business_profiles',
    'rag_chunks', 'aura_knowledge_chunks'
  ];
BEGIN
  FOREACH t IN ARRAY tablas LOOP
    -- Solo si la tabla existe y tiene tenant_id
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = t AND column_name = 'tenant_id'
    ) THEN
      -- 2a. Quitar políticas viejas (varias, contradictorias) y dejar UNA.
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_policy ON public.%I', t);
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON public.%I', t);

      -- 2b. Política única con USING **y** WITH CHECK (cubre lectura y escritura).
      EXECUTE format(
        'CREATE POLICY tenant_isolation_policy ON public.%I '
        'USING (tenant_id IS NOT NULL AND tenant_id = app_current_tenant_id()) '
        'WITH CHECK (tenant_id IS NOT NULL AND tenant_id = app_current_tenant_id())',
        t
      );

      -- 2c. RLS activo Y forzado (aplica también al dueño).
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t);

      RAISE NOTICE 'Aislada con FORCE: %', t;
    ELSE
      RAISE NOTICE 'Omitida (sin tenant_id o inexistente): %', t;
    END IF;
  END LOOP;
END $$;

-- 3) Verificación inmediata: `relforcerowsecurity` debe ser true en todas.
SELECT c.relname AS tabla, c.relrowsecurity AS rls_activo, c.relforcerowsecurity AS rls_forzado
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
  AND EXISTS (
    SELECT 1 FROM information_schema.columns col
    WHERE col.table_schema = 'public' AND col.table_name = c.relname AND col.column_name = 'tenant_id'
  )
ORDER BY c.relname;
