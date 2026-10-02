-- Migration 078: Fix biometric_consents schema (corrected)
-- Description: Handles case where both old (026 renamed) and new (037 added) columns exist
-- Problem: Migration 026 renamed columns, migration 037 added them back with IF NOT EXISTS
--          Migration 077 only renamed if target didn't exist, leaving both columns
-- Solution: Copy data from renamed columns to expected columns, then drop renamed ones

BEGIN;

-- 1. Handle consent_type / version conflict
DO $$
BEGIN
    -- If both exist, copy data from version to consent_type, then drop version
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'consent_type') THEN
        -- Copy data where consent_type is null but version has value
        UPDATE biometric_consents 
        SET consent_type = version 
        WHERE consent_type IS NULL AND version IS NOT NULL;
        
        -- Drop the renamed column
        ALTER TABLE biometric_consents DROP COLUMN version;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'consent_type') THEN
        -- Only version exists, rename it
        ALTER TABLE biometric_consents RENAME COLUMN version TO consent_type;
    END IF;
END $$;

-- 2. Handle ip_address / ip conflict
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip_address') THEN
        UPDATE biometric_consents 
        SET ip_address = ip 
        WHERE ip_address IS NULL AND ip IS NOT NULL;
        ALTER TABLE biometric_consents DROP COLUMN ip;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip_address') THEN
        ALTER TABLE biometric_consents RENAME COLUMN ip TO ip_address;
    END IF;
END $$;

-- 3. Handle user_agent / device_info conflict
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'device_info')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'user_agent') THEN
        UPDATE biometric_consents 
        SET user_agent = device_info 
        WHERE user_agent IS NULL AND device_info IS NOT NULL;
        ALTER TABLE biometric_consents DROP COLUMN device_info;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'device_info')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'user_agent') THEN
        ALTER TABLE biometric_consents RENAME COLUMN device_info TO user_agent;
    END IF;
END $$;

-- 4. Handle created_at / accepted_at conflict
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'accepted_at')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'created_at') THEN
        UPDATE biometric_consents 
        SET created_at = accepted_at 
        WHERE created_at IS NULL AND accepted_at IS NOT NULL;
        ALTER TABLE biometric_consents DROP COLUMN accepted_at;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'accepted_at')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'created_at') THEN
        ALTER TABLE biometric_consents RENAME COLUMN accepted_at TO created_at;
    END IF;
END $$;

-- 5. Ensure all required columns exist (from 037 + code expectations)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted') THEN
        ALTER TABLE biometric_consents ADD COLUMN granted BOOLEAN DEFAULT FALSE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN granted_at TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'revoked_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN revoked_at TIMESTAMP;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'purpose') THEN
        ALTER TABLE biometric_consents ADD COLUMN purpose TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version_terms') THEN
        ALTER TABLE biometric_consents ADD COLUMN version_terms VARCHAR(20) DEFAULT '1.0';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'updated_at') THEN
        ALTER TABLE biometric_consents ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- 6. Ensure the UNIQUE constraint for ON CONFLICT
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

-- 7. Drop legacy partial index from 026
DROP INDEX IF EXISTS unique_active_consent;

-- 8. Create indexes
CREATE INDEX IF NOT EXISTS idx_consents_user 
ON biometric_consents (user_id, consent_type, granted);

CREATE INDEX IF NOT EXISTS idx_consents_audit 
ON biometric_consents (granted_at, revoked_at);

-- 9. Ensure biometric_access_log table exists
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

-- 10. Trigger for updated_at
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

-- 11. Verification
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
    
    -- Check no legacy columns remain
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version') THEN
        RAISE EXCEPTION 'Columna legacy "version" aún existe';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip') THEN
        RAISE EXCEPTION 'Columna legacy "ip" aún existe';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'device_info') THEN
        RAISE EXCEPTION 'Columna legacy "device_info" aún existe';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'accepted_at') THEN
        RAISE EXCEPTION 'Columna legacy "accepted_at" aún existe';
    END IF;
    
    RAISE NOTICE '=== MIGRACIÓN 078 COMPLETADA - Schema alineado con código ===';
END $$;

COMMIT;