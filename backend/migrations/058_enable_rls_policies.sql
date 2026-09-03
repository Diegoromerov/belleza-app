-- D-001 Implementation: Enable RLS and create policies - REPAIRED
-- This migration enables Row Level Security on tables that need tenant isolation
-- and creates policies to enforce tenant_id based access control.
-- It is idempotent: checks if RLS is already enabled before enabling,
-- and checks table existence before operating.

DO $$
DECLARE
    rls_tables TEXT[] := ARRAY[
        'usuarios',
        'perfiles_prestador',
        'services',
        'bookings',
        'transactions',
        'reviews',
        'portfolio_items',
        'messages',
        'nail_tryon_jobs',
        'sos_alerts',
        'user_activity_logs',
        'platform_config',
        'admin_mfa',
        'productos'
    ];
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY rls_tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl) THEN
            IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = tbl) THEN
                EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', tbl);
            END IF;
        END IF;
    END LOOP;
END $$;

-- Create/replace policies for each table (idempotent via DROP IF EXISTS)
DO $$
DECLARE
    policy_tables TEXT[] := ARRAY[
        'usuarios',
        'perfiles_prestador',
        'services',
        'bookings',
        'transactions',
        'reviews',
        'portfolio_items',
        'messages',
        'nail_tryon_jobs',
        'sos_alerts',
        'user_activity_logs',
        'platform_config',
        'admin_mfa',
        'productos'
    ];
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY policy_tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl) THEN
            EXECUTE format(
                'DROP POLICY IF EXISTS tenant_isolation_%I ON %I;'
                || 'CREATE POLICY tenant_isolation_%I ON %I'
                || ' FOR ALL'
                || ' USING (tenant_id = current_setting(''app.tenant_id'')::int);',
                tbl, tbl, tbl, tbl
            );
        END IF;
    END LOOP;
END $$;