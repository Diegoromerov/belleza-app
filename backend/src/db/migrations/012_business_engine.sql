-- GLOWAPP BUSINESS ENGINE MIGRATION (012_business_engine.sql)
-- Additive, non-destructive schema extensions for GlowApp Business Engine

CREATE TABLE IF NOT EXISTS business_verticals (
  id VARCHAR(36) PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_profiles (
  id VARCHAR(36) PRIMARY KEY,
  provider_id VARCHAR(36) NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  vertical_id VARCHAR(36) NOT NULL REFERENCES business_verticals(id),
  name VARCHAR(150) NOT NULL,
  onboarding_mode VARCHAR(30) NOT NULL DEFAULT 'NEW_BUSINESS' CHECK (onboarding_mode IN ('NEW_BUSINESS', 'EXISTING_BUSINESS')),
  lifecycle_stage VARCHAR(30) NOT NULL DEFAULT 'IDEA' CHECK (lifecycle_stage IN ('IDEA', 'CONSTITUTION', 'FORMALIZATION', 'PREPARATION', 'OPENING', 'OPERATION', 'AUDIT', 'GROWTH')),
  compliance_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  city VARCHAR(100) DEFAULT 'Bogotá',
  country VARCHAR(100) DEFAULT 'Colombia',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_requirements (
  id VARCHAR(36) PRIMARY KEY,
  vertical_id VARCHAR(36) REFERENCES business_verticals(id),
  code VARCHAR(50) NOT NULL UNIQUE,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  legal_basis TEXT,
  jurisdiction VARCHAR(50) DEFAULT 'NATIONAL',
  domain_context VARCHAR(30) NOT NULL CHECK (domain_context IN ('LEGAL', 'LABOR', 'SANITARY', 'TAX', 'SST', 'OPERATIONS')),
  evidence_required VARCHAR(50) DEFAULT 'DOCUMENT',
  frequency_months INT DEFAULT 12,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_tasks (
  id VARCHAR(36) PRIMARY KEY,
  business_profile_id VARCHAR(36) NOT NULL REFERENCES business_profiles(id) ON DELETE CASCADE,
  requirement_id VARCHAR(36) REFERENCES business_requirements(id),
  title VARCHAR(150) NOT NULL,
  description TEXT,
  stage VARCHAR(20) NOT NULL DEFAULT 'ENTENDER' CHECK (stage IN ('ENTENDER', 'EXPLICAR', 'RECOMENDAR', 'EJECUTAR', 'VERIFICAR')),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'SUBMITTED', 'VERIFIED', 'EXPIRED')),
  due_date TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_evidences (
  id VARCHAR(36) PRIMARY KEY,
  task_id VARCHAR(36) NOT NULL REFERENCES business_tasks(id) ON DELETE CASCADE,
  file_path VARCHAR(255),
  evidence_type VARCHAR(30) NOT NULL DEFAULT 'DOCUMENT' CHECK (evidence_type IN ('DOCUMENT', 'PHOTO', 'CONTRACT', 'FORM', 'DECLARATION')),
  validation_state VARCHAR(30) NOT NULL DEFAULT 'USER_DECLARED' CHECK (validation_state IN ('USER_DECLARED', 'EVIDENCE_SUBMITTED', 'EVIDENCE_VALIDATED', 'REQUIREMENT_VERIFIED')),
  reviewer_notes TEXT,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS business_findings (
  id VARCHAR(36) PRIMARY KEY,
  business_profile_id VARCHAR(36) NOT NULL REFERENCES business_profiles(id) ON DELETE CASCADE,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  risk_level VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'MITIGATED', 'CLOSED')),
  mitigation_plan TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_templates (
  id VARCHAR(36) PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  title VARCHAR(150) NOT NULL,
  category VARCHAR(50) NOT NULL,
  template_body TEXT NOT NULL,
  disclaimer TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indices for rapid querying
CREATE INDEX IF NOT EXISTS idx_business_profiles_provider ON business_profiles(provider_id);
CREATE INDEX IF NOT EXISTS idx_business_tasks_profile ON business_tasks(business_profile_id);
CREATE INDEX IF NOT EXISTS idx_business_evidences_task ON business_evidences(task_id);
CREATE INDEX IF NOT EXISTS idx_business_findings_profile ON business_findings(business_profile_id);
