-- Migration 077: Fix biometric_consents schema to match code expectations
-- Description: Aligns production schema (after 026 rename) with code expectations (020/021/037)
-- Problem: Migration 026 renamed columns that code uses. Migration 037 added columns with IF NOT EXISTS
--          but on top of renamed columns, creating duplicates/conflicts.
-- Solution: Rename columns back to what the code expects, ensure constraints exist.

BEGIN;

-- 1. Rename columns back to what the code expects (from 026's renames)
DO $$
BEGIN
    -- 026 renamed consent_type -> version, code expects consent_type
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'consent_type') THEN
        ALTER TABLE biometric_consents RENAME COLUMN version TO consent_type;
    END IF;
    
    -- 026 renamed ip_address -> ip, code expects ip_address
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip_address') THEN
        ALTER TABLE biometric_consents RENAME COLUMN ip TO ip_address;
    END IF;
    
    -- 026 renamed device_info -> user_agent, code expects user_agent
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'device_info')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'user_agent') THEN
        ALTER TABLE biometric_consents RENAME COLUMN device_info TO user_agent;
    END IF;
    
    -- 026 renamed created_at -> accepted_at, code expects created_at (and granted_at)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'accepted_at')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'created_at') THEN
        ALTER TABLE biometric_consents RENAME COLUMN accepted_at TO created_at;
    END IF;
    
    -- Ensure granted_at exists (037 added it, but if 026 ran first it might be missing)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN granted_at TIMESTAMP;
    END IF;
    
    -- Ensure granted exists with default FALSE
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted') THEN
        ALTER TABLE biometric_consents ADD COLUMN granted BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Ensure revoked_at exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'revoked_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN revoked_at TIMESTAMP;
    END IF;
    
    -- Ensure purpose exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'purpose') THEN
        ALTER TABLE biometric_consents ADD COLUMN purpose TEXT;
    END IF;
    
    -- Ensure version_terms exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version_terms') THEN
        ALTER TABLE biometric_consents ADD COLUMN version_terms VARCHAR(20) DEFAULT '1.0';
    END IF;
    
    -- Ensure updated_at exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'updated_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- 2. Ensure the UNIQUE constraint that code expects for ON CONFLICT
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'biometric_consents_user_consent_version_key'
    ) THEN
        ALTER TABLE biometric_consents
            ADD CONSTRAINT biometric_consents_user_consent_version_key
            UNIQUE (user_id, consent_type, version_terms);
    END IF;
END $$;

-- 3. Drop the legacy partial index from 026 if it exists (uses 'active' column)
DROP INDEX IF EXISTS unique_active_consent;

-- 4. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_consents_user 
ON biometric_consents (user_id, consent_type, granted);

CREATE INDEX IF NOT EXISTS idx_consents_audit 
ON biometric_consents (granted_at, revoked_at);

-- 5. Ensure biometric_access_log table exists (from 037)
CREATE TABLE IF NOT EXISTS biometric_access_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  accessed_by VARCHAR(50) NOT NULL,
  access_type VARCHAR(50) NOT NULL,
  consent_id INTEGER REFERENCES biometric_consents(id),
  ip_address INET,
  accessed_at TIMESTAMP DEFAULT NOW(),
  details JSONB
);

CREATE INDEX IF NOT EXISTS idx_access_log_user 
ON biometric_access_log (user_id, accessed_at);

-- 6. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_consent_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_consent_timestamp ON biometric_consents;
CREATE TRIGGER trigger_update_consent_timestamp
  BEFORE UPDATE ON biometric_consents
  FOR EACH ROW
  EXECUTE FUNCTION update_consent_timestamp();

-- 7. Verification
DO $$
DECLARE
    cols text[];
    expected_cols text[] := ARRAY['id','user_id','consent_type','granted','granted_at','revoked_at','purpose','ip_address','user_agent','version_terms','created_at','updated_at'];
    missing text[];
    c text;
BEGIN
    SELECT array_agg(column_name) INTO cols
    FROM information_schema.columns
    WHERE table_name = 'biometric_consents';
    
    FOREACH c IN ARRAY expected_cols LOOP
        IF c NOT IN (SELECT unnest(cols)) THEN
            missing := array_append(missing, c);
        END IF;
    END LOOP;
    
    IF array_length(missing, 1) > 0 THEN
        RAISE EXCEPTION 'Faltan columnas en biometric_consents: %', missing;
    ELSE
        RAISE NOTICE '✅ Todas las columnas esperadas existen en biometric_consents';
    END IF;
    
    -- Check constraint
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'biometric_consents_user_consent_version_key'
    ) THEN
        RAISE NOTICE '✅ Constraint UNIQUE (user_id, consent_type, version_terms) existe';
    ELSE
        RAISE EXCEPTION 'Falta constraint UNIQUE';
    END IF;
    
    -- Check access log table
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'biometric_access_log'
    ) THEN
        RAISE NOTICE '✅ Tabla biometric_access_log existe';
    ELSE
        RAISE EXCEPTION 'Falta tabla biometric_access_log';
    END IF;
    
    RAISE NOTICE '=== MIGRACIÓN 077 COMPLETADA - Schema alineado con código ===';
END $$;

COMMIT;