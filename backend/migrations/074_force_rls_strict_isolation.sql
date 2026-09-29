-- ============================================================================
-- Migración 068: Aislamiento multi-tenant ESTRICTO
--               (políticas correctas + FORCE ROW LEVEL SECURITY + relleno de tenant_id)
-- ============================================================================
-- QUÉ ARREGLA
-- -----------
-- La capa de RLS existente no aislaba nada, por cuatro defectos que se
-- tapaban entre sí:
--
--   1. NUNCA se usaba FORCE. El rol que usa la aplicación es el PROPIETARIO de
--      las tablas, y PostgreSQL exceptúa al propietario de las políticas
--      (salvo con FORCE). Medido: `force=false` en las 10 tablas.
--   2. `056`/`065` crean políticas permisivas ADICIONALES por tabla
--      (`tenant_isolation_<t>`, `_insert`, `_update`, `_delete`). Las políticas
--      permisivas se **OR-ean**: una política laxa anula a una estricta. Además
--      la de tipo ALL usa `current_setting('app.tenant_id')` SIN `missing_ok`,
--      que **lanza error** —no devuelve 0 filas— cuando no hay contexto fijado,
--      y su `::integer` explota con `''` (invalid input syntax for type integer).
--   3. `058` referencia tablas que no existen (`sos_alerts`,
--      `user_activity_logs`, `admin_mfa`, `platform_config`) y usaba `servicios`
--      en vez de `services`. Sus bloques IF EXISTS **saltan en silencio**, que
--      es de dónde salen las "12 tablas con RLS y cero políticas".
--   4. De los 89 INSERT del backend solo 2 escriben `tenant_id`. Sin relleno,
--      activar FORCE haría fallar el WITH CHECK en casi toda escritura.
--
-- QUÉ HACE
-- --------
--   1. `app_current_tenant_id()`: `NULLIF(current_setting(..., true), '')::integer`.
--      El `true` es `missing_ok`: sin contexto devuelve NULL (0 filas), no error.
--   2. BORRA TODAS las políticas de cada tabla objetivo, sea cual sea su
--      nombre, y crea UNA sola `FOR ALL` con USING **y** WITH CHECK. Borrar es
--      imprescindible: dejar una permisiva suelta reabre el agujero por OR.
--   3. Trigger BEFORE INSERT que rellena `tenant_id` desde el contexto.
--   4. FORCE ROW LEVEL SECURITY: ahora las políticas también obligan al
--      propietario.
--
-- EXCLUSIÓN DELIBERADA (no es una omisión)
-- ----------------------------------------
--   `usuarios` queda con RLS DESACTIVADO, y se documenta por qué:
--     * es la tabla de identidad CROSS-TENANT: un cliente no pertenece a ningún
--       salón y su `tenant_id` es NULL;
--     * `auth.js:34` la consulta para DESCUBRIR el inquilino
--       (`SELECT rol, tenant_id FROM usuarios WHERE id = $1`) cuando todavía no
--       hay contexto: cualquier política que exija contexto la deja en cero
--       filas y deja al sistema entero en 401;
--     * una política que admita tenant_id NULL expondría a TODOS los clientes a
--       cualquier inquilino, que es peor que no tener política.
--   RIESGO RESIDUAL ASUMIDO: el aislamiento de `usuarios` depende de la capa de
--   consulta. Las lecturas de usuarios que no filtren por id/tenant son una
--   fuga — ver backend/scripts/verifyTenantIsolation.js, que falla si alguna
--   consulta de la aplicación lee usuarios sin acotar.
--
-- REQUISITO DE OPERACIÓN
-- ----------------------
-- Con FORCE activo, una consulta SIN contexto devuelve 0 filas en estas tablas.
-- Los caminos que no nacen de una petición autenticada (webhook de Wompi, jobs
-- de cron) DEBEN fijar el contexto por su cuenta antes de leer o escribir.
--
-- IDEMPOTENTE: se puede ejecutar varias veces.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Contexto
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_current_tenant_id() RETURNS integer
LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true), '')::integer
$$;

CREATE OR REPLACE FUNCTION app_assign_tenant_id() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1. Tablas con datos propiedad de un inquilino.
--    Si la tabla no existe en este esquema se informa en voz alta y se sigue;
--    lo que NO se permite es dejarla con RLS activo y sin política.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  t            text;
  politicas    int;
  cubiertas    text[] := ARRAY[]::text[];
  ausentes     text[] := ARRAY[]::text[];
  sin_aislar   text[] := ARRAY[]::text[];
  -- Tablas cuyo DDL NO está en el repositorio (viven solo en Railway). Si
  -- existen en este esquema pero NO tienen tenant_id, aquí no se puede derivar
  -- la columna: se informa en voz alta y se SIGUE. Abortar la migración entera
  -- por una tabla que el repositorio no gobierna deja sin FORCE a todas las
  -- demás — que es exactamente lo que pasaba en el esquema real.
  externas text[] := ARRAY[
    'provider_wallet',
    'wallet_transactions',
    'retiros',
    'disputas'
  ];
  tablas text[] := ARRAY[
    -- presentes en cualquier esquema (creadas por init.sql)
    'services',
    'bookings',
    'transactions',
    'messages',
    'reviews',
    'portfolio_items',
    'nail_tryon_jobs',
    'perfiles_prestador',
    'productos',
    -- creadas por 067_create_multi_salon_ddl.sql
    'salones',
    'salon_miembros',
    'salon_invitaciones'
  ];
BEGIN
  FOREACH t IN ARRAY (tablas || externas) LOOP

    IF NOT EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'public' AND c.relname = t AND c.relkind = 'r'
    ) THEN
      RAISE NOTICE '068: "%" no existe en este esquema — se omite (revisar en producción)', t;
      ausentes := ausentes || t;
      CONTINUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = t AND column_name = 'tenant_id'
    ) THEN
      -- Tabla que el repositorio no gobierna: se informa y se sigue. El silencio
      -- no es aceptable (queda SIN aislar), pero tampoco lo es tumbar todo lo
      -- demás por su culpa.
      IF t = ANY(externas) THEN
        RAISE NOTICE
          '068: "%" EXISTE pero SIN tenant_id y su DDL no está en el repositorio, '
          'así que la columna no se puede derivar aquí. QUEDA SIN AISLAR: añádela '
          'y vuelve a aplicar 068.', t;
        sin_aislar := sin_aislar || t;
        CONTINUE;
      END IF;

      -- Tabla del repositorio: 056/065 deberían haberle puesto la columna. Si no
      -- la tiene, es un error de esas migraciones y aquí sí se rompe.
      RAISE EXCEPTION
        '068: "%" existe pero no tiene tenant_id. Sin esa columna no hay nada que aislar: '
        'aplica 056/065 para esa tabla antes que 068.', t;
    END IF;

    -- 1a. Borrar TODAS las políticas de la tabla. Dejar una permisiva suelta
    --     anularía la estricta por OR.
    SELECT count(*) INTO politicas FROM pg_policies WHERE schemaname = 'public' AND tablename = t;
    EXECUTE format(
      'DO $inner$ DECLARE p record; BEGIN '
      'FOR p IN SELECT policyname FROM pg_policies '
      '          WHERE schemaname = ''public'' AND tablename = %L LOOP '
      '  EXECUTE format(''DROP POLICY %%I ON public.%%I'', p.policyname, %L); '
      'END LOOP; END $inner$;', t, t
    );

    -- 1b. Una única política, con WITH CHECK para cubrir también la escritura.
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON public.%I FOR ALL '
      'USING  (tenant_id IS NOT NULL AND tenant_id = app_current_tenant_id()) '
      'WITH CHECK (tenant_id IS NOT NULL AND tenant_id = app_current_tenant_id())',
      t
    );

    -- 1c. Relleno de tenant_id en INSERT.
    EXECUTE format('DROP TRIGGER IF EXISTS trg_assign_tenant_id ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER trg_assign_tenant_id BEFORE INSERT ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION app_assign_tenant_id()', t
    );

    -- 1d. Habilitar y FORZAR.
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE public.%I FORCE  ROW LEVEL SECURITY', t);

    cubiertas := cubiertas || t;
    RAISE NOTICE '068: % asegurada (borradas % políticas previas -> 1 política + trigger + FORCE)',
      t, politicas;
  END LOOP;

  RAISE NOTICE '068: % tablas aseguradas, % ausentes en este esquema, % externas SIN AISLAR (sin tenant_id)',
    array_length(cubiertas, 1),
    COALESCE(array_length(ausentes, 1), 0),
    COALESCE(array_length(sin_aislar, 1), 0);
END $$;

-- ---------------------------------------------------------------------------
-- 2. usuarios: excepción documentada (ver cabecera).
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  p record;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE n.nspname = 'public' AND c.relname = 'usuarios' AND c.relkind = 'r') THEN
    -- Se borran también sus políticas: dejar 4 políticas laxas en una tabla con
    -- RLS desactivado es una trampa, porque el día que alguien vuelva a
    -- activarlo recuperaría precisamente las que se OR-ean y no comprueban.
    FOR p IN SELECT policyname FROM pg_policies
              WHERE schemaname = 'public' AND tablename = 'usuarios' LOOP
      EXECUTE format('DROP POLICY %I ON public.usuarios', p.policyname);
    END LOOP;

    EXECUTE 'ALTER TABLE public.usuarios NO FORCE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.usuarios DISABLE ROW LEVEL SECURITY';
    RAISE NOTICE '068: usuarios con RLS DESACTIVADO y sin políticas a propósito (identidad cross-tenant; auth.js:34 la lee antes de fijar contexto)';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Verificación interna: ninguna tabla puede quedar con RLS activo y sin
--    política, porque eso es denegación total silenciosa.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  sin_politica text;
BEGIN
  SELECT string_agg(c.relname, ', ')
    INTO sin_politica
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity
     AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid);

  IF sin_politica IS NOT NULL THEN
    RAISE EXCEPTION
      '068: tablas con RLS activo y SIN políticas (deniegan todo): %. Corrígelo antes de continuar.',
      sin_politica;
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- DESPLIEGUE: rol no propietario (segunda línea de defensa)
-- ============================================================================
-- Con FORCE el propietario ya queda sujeto a las políticas, así que el
-- aislamiento no depende del rol. Aun así, la aplicación debe conectarse con un
-- rol que NO sea propietario ni superusuario: ver
-- backend/scripts/setupRlsRole.sql y backend/scripts/verifyTenantIsolation.js,
-- que prueban ambos caminos (propietario con FORCE y rol no propietario).
-- ============================================================================
