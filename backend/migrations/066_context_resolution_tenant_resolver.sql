-- ====================================================================
-- MIGRATION 066: CONTEXT RESOLUTION TENANT RESOLVER (ARCH-CR-002)
-- Node Contract — Context Resolution v1.0
-- Secure Server-Side Tenant Resolution via SECURITY DEFINER function
-- ====================================================================

BEGIN;

-- 1. Crear o reemplazar la función controlada SECURITY DEFINER
CREATE OR REPLACE FUNCTION fn_resolve_user_tenant(p_user_id INTEGER)
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT tenant_id FROM usuarios WHERE id = p_user_id;
$$;

-- 2. Restringir privilegios de ejecución (Mínimo Privilegio)
REVOKE ALL ON FUNCTION fn_resolve_user_tenant(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_resolve_user_tenant(INTEGER) TO beauty_app_user;

COMMIT;