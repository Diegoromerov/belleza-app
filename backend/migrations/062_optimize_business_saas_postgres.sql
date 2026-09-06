-- MIGRATION 062: POSTGRESQL PERFORMANCE & SECURITY OPTIMIZATION FOR GLOWAPP SAAS ENGINE
-- Complies with postgresql and postgres-best-practices rules (Rule 42, 49, 72, 91, 108).

-- 1. FOREIGN KEY INDEXES (Rule 49: PostgreSQL does not auto-index FK columns)
CREATE INDEX IF NOT EXISTS idx_business_tasks_profile_id 
ON business_tasks(business_profile_id);

CREATE INDEX IF NOT EXISTS idx_business_evidences_task_id 
ON business_evidences(task_id);

CREATE INDEX IF NOT EXISTS idx_business_findings_profile_id 
ON business_findings(business_profile_id);

CREATE INDEX IF NOT EXISTS idx_business_documents_provider_tenant 
ON business_documents(provider_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_business_documents_profile_id 
ON business_documents(business_profile_id);

CREATE INDEX IF NOT EXISTS idx_document_audit_logs_doc_id 
ON document_audit_logs(document_id);

-- 2. PARTIAL INDEX FOR HOT ADMIN QUEUE (Rule 108: Hot Query Subset Indexing)
CREATE INDEX IF NOT EXISTS idx_business_evidences_admin_queue 
ON business_evidences (created_at ASC) 
WHERE validation_state IN ('EVIDENCE_SUBMITTED', 'USER_DECLARED');

-- 3. PARTIAL INDEX FOR OPEN TASKS AND FINDINGS
CREATE INDEX IF NOT EXISTS idx_business_tasks_active 
ON business_tasks(business_profile_id, stage) 
WHERE status IN ('IN_PROGRESS', 'PENDING');

CREATE INDEX IF NOT EXISTS idx_business_findings_open 
ON business_findings(business_profile_id, risk_level) 
WHERE status = 'OPEN';

-- 4. CONVERT AUDIT METADATA TO NATIVE JSONB & ADD GIN INDEX (Rule 72)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'document_audit_logs') THEN
    ALTER TABLE document_audit_logs 
      ALTER COLUMN metadata TYPE JSONB USING metadata::jsonb;
    
    CREATE INDEX IF NOT EXISTS idx_document_audit_logs_metadata_gin 
    ON document_audit_logs USING GIN (metadata);
  END IF;
END $$;

-- 5. ENABLE ROW LEVEL SECURITY (RLS) & POLICIES FOR SAAS TABLES (Rule 91)
DO $$
DECLARE
    tbl TEXT;
    saas_tables TEXT[] := ARRAY[
        'business_profiles',
        'business_tasks',
        'business_evidences',
        'business_findings',
        'business_documents',
        'document_audit_logs'
    ];
BEGIN
    FOREACH tbl IN ARRAY saas_tables LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl) THEN
            IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = tbl) THEN
                EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', tbl);
            END IF;
            
            EXECUTE format(
                'DROP POLICY IF EXISTS tenant_isolation_%I ON %I;'
                || 'CREATE POLICY tenant_isolation_%I ON %I'
                || ' FOR ALL'
                || ' USING (tenant_id = current_setting(''app.tenant_id'', true) OR current_setting(''app.tenant_id'', true) IS NULL);',
                tbl, tbl, tbl, tbl
            );
        END IF;
    END LOOP;
END $$;
