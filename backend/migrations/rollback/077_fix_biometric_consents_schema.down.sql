-- Rollback for 077_fix_biometric_consents_schema.sql
-- This rollback restores the schema to the state after migration 026/037 (pre-077)

BEGIN;

-- 1. Drop the trigger and function
DROP TRIGGER IF EXISTS trigger_update_consent_timestamp ON biometric_consents;
DROP FUNCTION IF EXISTS update_consent_timestamp();

-- 2. Drop indexes created by 077
DROP INDEX IF EXISTS idx_consents_user;
DROP INDEX IF EXISTS idx_consents_audit;
DROP INDEX IF EXISTS idx_access_log_user;

-- 3. Drop the UNIQUE constraint added by 077
ALTER TABLE biometric_consents DROP CONSTRAINT IF EXISTS biometric_consents_user_consent_version_key;

-- 4. Drop biometric_access_log table (created by 037/077)
DROP TABLE IF EXISTS biometric_access_log;

-- 5. Rename columns back to 026 state (undo 077 renames)
DO $$
BEGIN
    -- consent_type -> version (026 state)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'consent_type')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version') THEN
        ALTER TABLE biometric_consents RENAME COLUMN consent_type TO version;
    END IF;
    
    -- ip_address -> ip (026 state)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip_address')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'ip') THEN
        ALTER TABLE biometric_consents RENAME COLUMN ip_address TO ip;
    END IF;
    
    -- user_agent -> device_info (026 state)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'user_agent')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'device_info') THEN
        ALTER TABLE biometric_consents RENAME COLUMN user_agent TO device_info;
    END IF;
    
    -- created_at -> accepted_at (026 state)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'created_at')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'accepted_at') THEN
        ALTER TABLE biometric_consents RENAME COLUMN created_at TO accepted_at;
    END IF;
END $$;

-- 6. Recreate the legacy partial index from 026
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_consent ON biometric_consents (user_id) WHERE active = TRUE;

-- 7. Remove columns added by 037/077 that didn't exist in 026
-- Note: We only remove columns that were ADDED by 037/077 and don't exist in 026
-- 026 schema had: id, user_id, version, accepted_at, ip, user_agent, revoked_at, active
-- So we keep: id, user_id, version, accepted_at, ip, user_agent, revoked_at, active
-- We remove: granted, granted_at, purpose, version_terms, updated_at, consent_type (renamed), ip_address (renamed), etc.
DO $$
BEGIN
    -- Remove columns that code added but 026 didn't have
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted') THEN
        ALTER TABLE biometric_consents DROP COLUMN granted;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'granted_at') THEN
        ALTER TABLE biometric_consents DROP COLUMN granted_at;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'purpose') THEN
        ALTER TABLE biometric_consents DROP COLUMN purpose;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'version_terms') THEN
        ALTER TABLE biometric_consents DROP COLUMN version_terms;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'biometric_consents' AND column_name = 'updated_at') THEN
        ALTER TABLE biometric_consents DROP COLUMN updated_at;
    END IF;
END $$;

COMMIT;