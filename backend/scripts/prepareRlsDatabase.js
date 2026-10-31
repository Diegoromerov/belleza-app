#!/usr/bin/env node
/**
 * backend/scripts/prepareRlsDatabase.js
 *
 * Deja una base de datos lista para PROBAR el aislamiento multi-tenant:
 * aplica el esquema, crea los roles RLS y transfiere la propiedad de las tablas
 * multi-tenant al rol no superusuario que lo demuestra.
 */

const { Client } = require('pg');

const ADMIN_URL = process.env.DATABASE_URL_ADMIN || process.env.DATABASE_URL;
const PASSWORD = process.env.RLS_ROLE_PASSWORD;
if (!PASSWORD) {
  console.error('[ERROR] RLS_ROLE_PASSWORD environment variable is required but not set');
  process.exit(2);
}

// SQL migrations embedded as constants to avoid file dependency in Docker
// Using regular strings (not template literals) to avoid backtick escaping issues
const MIGRATION_SQL = {
  'init.sql': '-- Base schema - tables already exist (80 tables found)',

  '054_create_core_tables.sql': "-- 054: Create core tables if not exist\nCREATE EXTENSION IF NOT EXISTS postgis;\nCREATE TABLE IF NOT EXISTS usuarios (\n  id SERIAL PRIMARY KEY,\n  email VARCHAR(255) UNIQUE NOT NULL,\n  password_hash VARCHAR(255) NOT NULL,\n  nombre VARCHAR(150) NOT NULL,\n  foto_url VARCHAR(500),\n  telefono VARCHAR(30),\n  tipo_usuario VARCHAR(30) NOT NULL DEFAULT 'CLIENTE' CHECK (tipo_usuario IN ('CLIENTE', 'PRESTADOR', 'ADMIN')),\n  is_active BOOLEAN NOT NULL DEFAULT true,\n  email_verificado BOOLEAN NOT NULL DEFAULT false,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS perfiles_prestador (\n  id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,\n  business_name VARCHAR(200),\n  description TEXT,\n  rating_avg NUMERIC(3,2) DEFAULT 0,\n  rating_count INTEGER DEFAULT 0,\n  estatus_verificacion VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE' CHECK (estatus_verificacion IN ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'SUSPENDIDO')),\n  ubicacion GEOGRAPHY(POINT, 4326),\n  is_active BOOLEAN NOT NULL DEFAULT true,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS services (\n  id SERIAL PRIMARY KEY,\n  provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  name VARCHAR(200) NOT NULL,\n  description TEXT,\n  price NUMERIC(10,2) NOT NULL,\n  duration_minutes INTEGER NOT NULL DEFAULT 30,\n  category VARCHAR(100),\n  is_active BOOLEAN NOT NULL DEFAULT true,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS bookings (\n  id SERIAL PRIMARY KEY,\n  client_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  service_id INTEGER NOT NULL REFERENCES services(id) ON DELETE CASCADE,\n  starts_at TIMESTAMP WITH TIME ZONE NOT NULL,\n  ends_at TIMESTAMP WITH TIME ZONE NOT NULL,\n  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'NO_SHOW')),\n  notes TEXT,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS transactions (\n  id SERIAL PRIMARY KEY,\n  booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,\n  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  amount NUMERIC(10,2) NOT NULL,\n  currency VARCHAR(3) NOT NULL DEFAULT 'COP',\n  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),\n  payment_method VARCHAR(50),\n  external_id VARCHAR(100),\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS reviews (\n  id SERIAL PRIMARY KEY,\n  booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,\n  client_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),\n  comment TEXT,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS portfolio_items (\n  id SERIAL PRIMARY KEY,\n  provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  title VARCHAR(200),\n  description TEXT,\n  image_url VARCHAR(500),\n  category VARCHAR(100),\n  is_active BOOLEAN NOT NULL DEFAULT true,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS messages (\n  id SERIAL PRIMARY KEY,\n  conversation_id VARCHAR(100) NOT NULL,\n  sender_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  content TEXT NOT NULL,\n  message_type VARCHAR(20) NOT NULL DEFAULT 'TEXT' CHECK (message_type IN ('TEXT', 'IMAGE', 'SYSTEM')),\n  read_at TIMESTAMP WITH TIME ZONE,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS nail_tryon_jobs (\n  id SERIAL PRIMARY KEY,\n  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  image_url VARCHAR(500),\n  result_url VARCHAR(500),\n  status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS sos_alerts (\n  id SERIAL PRIMARY KEY,\n  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  location GEOGRAPHY(POINT, 4326),\n  message TEXT,\n  status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED', 'CANCELLED')),\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS user_activity_logs (\n  id SERIAL PRIMARY KEY,\n  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  action VARCHAR(100) NOT NULL,\n  metadata JSONB,\n  ip_address INET,\n  user_agent TEXT,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS provider_loyalty (\n  provider_id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,\n  tier VARCHAR(30) NOT NULL DEFAULT 'Creative Edge' CHECK (tier IN ('Creative Edge', 'Visage Pro', 'Avant-Garde Elite')),\n  points INTEGER NOT NULL DEFAULT 0,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS platform_config (\n  key VARCHAR(100) PRIMARY KEY,\n  value TEXT,\n  description TEXT,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS admin_mfa (\n  user_id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,\n  secret VARCHAR(255) NOT NULL,\n  enabled BOOLEAN NOT NULL DEFAULT false,\n  backup_codes TEXT[],\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS productos (\n  id SERIAL PRIMARY KEY,\n  provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  name VARCHAR(200) NOT NULL,\n  description TEXT,\n  price NUMERIC(10,2) NOT NULL,\n  stock INTEGER NOT NULL DEFAULT 0,\n  category VARCHAR(100),\n  is_active BOOLEAN NOT NULL DEFAULT true,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);",

  '055_create_tenants_table.sql': "-- D-001 Implementation: Create tenants table with default tenant\nCREATE TABLE IF NOT EXISTS tenants (\n  id SERIAL PRIMARY KEY,\n  name VARCHAR(100) NOT NULL,\n  slug VARCHAR(100) UNIQUE NOT NULL,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nINSERT INTO tenants (id, name, slug, created_at, updated_at)\nVALUES (1, 'Default Tenant', 'default', NOW(), NOW())\nON CONFLICT (id) DO NOTHING;",

  '056_add_tenant_id_to_core_tables.sql': "-- D-001: Add tenant_id to core tables\nALTER TABLE IF EXISTS usuarios ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS services ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS bookings ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS transactions ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS reviews ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS portfolio_items ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS messages ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS nail_tryon_jobs ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS sos_alerts ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS user_activity_logs ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS perfiles_prestador ADD COLUMN IF NOT EXISTS tenant_id INTEGER;",

  '057_backfill_tenant_id.sql': "-- D-001: Backfill tenant_id for existing data\nDO $$\nDECLARE\n    demo_tenant_id INTEGER;\nBEGIN\n    PERFORM setval(pg_get_serial_sequence('tenants', 'id'), COALESCE((SELECT MAX(id) FROM tenants), 0) + 1, false);\n    INSERT INTO tenants (name, slug) VALUES ('Demo Tenant', 'demo') ON CONFLICT (slug) DO NOTHING;\n    SELECT id INTO demo_tenant_id FROM tenants WHERE slug = 'demo' LIMIT 1;\n    IF demo_tenant_id IS NULL THEN\n        SELECT id INTO demo_tenant_id FROM tenants WHERE slug = 'default' LIMIT 1;\n    END IF;\n    UPDATE usuarios SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE services SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE bookings SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE transactions SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE reviews SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE portfolio_items SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE messages SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE nail_tryon_jobs SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE sos_alerts SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE user_activity_logs SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\n    UPDATE perfiles_prestador SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;\nEND $$;",

  '058_enable_rls_policies.sql': "-- D-001: Enable RLS and create policies\nDO $$\nDECLARE\n    rls_tables TEXT[] := ARRAY['usuarios', 'perfiles_prestador', 'services', 'bookings', 'transactions', 'reviews', 'portfolio_items', 'messages', 'nail_tryon_jobs', 'sos_alerts', 'user_activity_logs', 'platform_config', 'admin_mfa', 'productos'];\n    tbl TEXT;\nBEGIN\n    FOREACH tbl IN ARRAY rls_tables LOOP\n        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN\n            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'tenant_id') THEN\n                RAISE EXCEPTION 'MIGRATION ASSERTION ERROR (058): La tabla "%" existe pero carece de tenant_id', tbl;\n            END IF;\n            IF NOT (SELECT relrowsecurity FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = tbl) THEN\n                EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl);\n            END IF;\n        END IF;\n    END LOOP;\nEND $$;\nDO $$\nDECLARE\n    policy_tables TEXT[] := ARRAY['usuarios', 'perfiles_prestador', 'services', 'bookings', 'transactions', 'reviews', 'portfolio_items', 'messages', 'nail_tryon_jobs', 'sos_alerts', 'user_activity_logs', 'platform_config', 'admin_mfa', 'productos'];\n    tbl TEXT;\nBEGIN\n    FOREACH tbl IN ARRAY policy_tables LOOP\n        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN\n            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'tenant_id') THEN\n                RAISE EXCEPTION 'MIGRATION ASSERTION ERROR (058): La tabla "%" existe pero carece de tenant_id', tbl;\n            END IF;\n            EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_%I ON public.%I; CREATE POLICY tenant_isolation_%I ON public.%I FOR ALL USING (tenant_id = current_setting(\'\'app.tenant_id\'\')::int);', tbl, tbl, tbl, tbl);\n        END IF;\n    END LOOP;\nEND $$;",

  '065_multi_tenant_hardening.sql': "-- 065: Multi-tenant hardening\nCREATE OR REPLACE FUNCTION app_current_tenant_id() RETURNS INTEGER LANGUAGE sql STABLE AS $$ SELECT NULLIF(current_setting('app.tenant_id', true), '')::INTEGER; $$;\nALTER TABLE IF EXISTS salones ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS salon_miembros ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS salon_invitaciones ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS provider_wallet ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS wallet_transactions ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS retiros ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS disputas ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS services ADD COLUMN IF NOT EXISTS tenant_id INTEGER;\nALTER TABLE IF EXISTS servicios ADD COLUMN IF NOT EXISTS tenant_id INTEGER;",

  '067_create_multi_salon_ddl.sql': "-- 067: Multi-salon DDL\nCREATE TABLE IF NOT EXISTS salones (\n  id SERIAL PRIMARY KEY,\n  nombre VARCHAR(150) NOT NULL,\n  direccion TEXT,\n  lat DOUBLE PRECISION,\n  lon DOUBLE PRECISION,\n  tenant_id INTEGER REFERENCES tenants(id),\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE TABLE IF NOT EXISTS salon_miembros (\n  id SERIAL PRIMARY KEY,\n  salon_id INTEGER NOT NULL REFERENCES salones(id) ON DELETE CASCADE,\n  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,\n  rol VARCHAR(30) NOT NULL CHECK (rol IN ('ADMIN', 'RECEPCIONISTA', 'PRESTADOR_INDEPENDIENTE', 'EMPLEADO')),\n  tenant_id INTEGER REFERENCES tenants(id),\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,\n  UNIQUE (salon_id, user_id)\n);\nCREATE TABLE IF NOT EXISTS salon_invitaciones (\n  id SERIAL PRIMARY KEY,\n  salon_id INTEGER NOT NULL REFERENCES salones(id) ON DELETE CASCADE,\n  email VARCHAR(255) NOT NULL,\n  rol VARCHAR(30) NOT NULL CHECK (rol IN ('ADMIN', 'RECEPCIONISTA', 'PRESTADOR_INDEPENDIENTE', 'EMPLEADO')),\n  token VARCHAR(64) NOT NULL UNIQUE,\n  tenant_id INTEGER REFERENCES tenants(id),\n  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,\n  accepted_at TIMESTAMP WITH TIME ZONE,\n  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP\n);\nCREATE INDEX IF NOT EXISTS idx_salones_tenant ON salones(tenant_id);\nCREATE INDEX IF NOT EXISTS idx_salon_miembros_salon ON salon_miembros(salon_id);\nCREATE INDEX IF NOT EXISTS idx_salon_miembros_user ON salon_miembros(user_id);\nCREATE INDEX IF NOT EXISTS idx_salon_invitaciones_salon ON salon_invitaciones(salon_id);",

  '068_force_rls_strict_isolation.sql': "-- 068: Force RLS strict isolation\nBEGIN;\nCREATE OR REPLACE FUNCTION app_assign_tenant_id() RETURNS trigger LANGUAGE plpgsql AS $$\nDECLARE v_tenant INTEGER;\nBEGIN\n  v_tenant := NULLIF(current_setting('app.tenant_id', true), '')::INTEGER;\n  IF v_tenant IS NULL THEN\n    RAISE EXCEPTION 'app.tenant_id no está fijado: no se puede insertar sin tenant_id';\n  END IF;\n  NEW.tenant_id := v_tenant;\n  RETURN NEW;\nEND $$;\nDO $$\nDECLARE tbl TEXT; tablas_force TEXT[] := ARRAY['usuarios', 'perfiles_prestador', 'services', 'servicios', 'bookings', 'transactions', 'reviews', 'portfolio_items', 'messages', 'nail_tryon_jobs', 'sos_alerts', 'user_activity_logs', 'salones', 'salon_miembros', 'salon_invitaciones', 'provider_wallet', 'wallet_transactions', 'retiros', 'disputas'];\nBEGIN\n  FOREACH tbl IN ARRAY tablas_force LOOP\n    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'tenant_id') THEN\n      EXECUTE 'ALTER TABLE public.' || tbl || ' ENABLE ROW LEVEL SECURITY';\n      EXECUTE 'ALTER TABLE public.' || tbl || ' FORCE ROW LEVEL SECURITY';\n      EXECUTE 'DROP POLICY IF EXISTS tenant_isolation_' || tbl || ' ON public.' || tbl;\n      EXECUTE 'CREATE POLICY tenant_isolation_' || tbl || ' ON public.' || tbl || ' FOR ALL USING (tenant_id = app_current_tenant_id()) WITH CHECK (tenant_id = app_current_tenant_id())';\n    END IF;\n  END LOOP;\nEND $$;\nCOMMIT;",

  '107_rls_politicas_sin_contexto.sql': "-- 107: Fix RLS policies for missing context\nDO $$\nDECLARE\n    policy_tables TEXT[] := ARRAY['usuarios', 'perfiles_prestador', 'services', 'servicios', 'bookings', 'transactions', 'reviews', 'portfolio_items', 'messages', 'nail_tryon_jobs', 'sos_alerts', 'user_activity_logs', 'salones', 'salon_miembros', 'salon_invitaciones', 'provider_wallet', 'wallet_transactions', 'retiros', 'disputas'];\n    tbl TEXT;\nBEGIN\n    FOREACH tbl IN ARRAY policy_tables LOOP\n        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN\n            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = tbl AND column_name = 'tenant_id') THEN\n                CONTINUE;\n            END IF;\n            EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_%I ON public.%I;', tbl, tbl);\n            EXECUTE format('CREATE POLICY tenant_isolation_%I ON public.%I FOR ALL USING (tenant_id = COALESCE(NULLIF(current_setting(\'\'app.tenant_id\'\', true), \'\')::int, 0)) WITH CHECK (tenant_id = COALESCE(NULLIF(current_setting(\'\'app.tenant_id\'\', true), \'\')::int, 0));', tbl, tbl);\n        END IF;\n    END LOOP;\nEND $$;",

  '012_business_engine.sql': "-- 012: Business engine tables\nCREATE TABLE IF NOT EXISTS business_verticals (id VARCHAR(36) PRIMARY KEY, code VARCHAR(50) NOT NULL UNIQUE, name VARCHAR(100) NOT NULL, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_profiles (id VARCHAR(36) PRIMARY KEY, provider_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE, vertical_id VARCHAR(36) NOT NULL REFERENCES business_verticals(id), name VARCHAR(150) NOT NULL, onboarding_mode VARCHAR(30) NOT NULL DEFAULT 'NEW_BUSINESS' CHECK (onboarding_mode IN ('NEW_BUSINESS', 'EXISTING_BUSINESS')), lifecycle_stage VARCHAR(30) NOT NULL DEFAULT 'IDEA' CHECK (lifecycle_stage IN ('IDEA', 'CONSTITUTION', 'FORMALIZATION', 'PREPARATION', 'OPENING', 'OPERATION', 'AUDIT', 'GROWTH')), compliance_score NUMERIC(5,2) NOT NULL DEFAULT 0.00, city VARCHAR(100) DEFAULT 'Bogotá', country VARCHAR(100) DEFAULT 'Colombia', metadata JSONB DEFAULT '{}'::jsonb, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_requirements (id VARCHAR(36) PRIMARY KEY, vertical_id VARCHAR(36) REFERENCES business_verticals(id), code VARCHAR(50) NOT NULL UNIQUE, title VARCHAR(150) NOT NULL, description TEXT, legal_basis TEXT, jurisdiction VARCHAR(50) DEFAULT 'NATIONAL', domain_context VARCHAR(30) NOT NULL CHECK (domain_context IN ('LEGAL', 'LABOR', 'SANITARY', 'TAX', 'SST', 'OPERATIONS')), evidence_required VARCHAR(50) DEFAULT 'DOCUMENT', frequency_months INT DEFAULT 12, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_tasks (id VARCHAR(36) PRIMARY KEY, business_profile_id VARCHAR(36) NOT NULL REFERENCES business_profiles(id) ON DELETE CASCADE, requirement_id VARCHAR(36) REFERENCES business_requirements(id), title VARCHAR(150) NOT NULL, description TEXT, stage VARCHAR(20) NOT NULL DEFAULT 'ENTENDER' CHECK (stage IN ('ENTENDER', 'EXPLICAR', 'RECOMENDAR', 'EJECUTAR', 'VERIFICAR')), status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'SUBMITTED', 'VERIFIED', 'EXPIRED')), due_date TIMESTAMP WITH TIME ZONE, metadata JSONB DEFAULT '{}'::jsonb, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_evidences (id VARCHAR(36) PRIMARY KEY, task_id VARCHAR(36) NOT NULL REFERENCES business_tasks(id) ON DELETE CASCADE, file_path VARCHAR(255), evidence_type VARCHAR(30) NOT NULL DEFAULT 'DOCUMENT' CHECK (evidence_type IN ('DOCUMENT', 'PHOTO', 'CONTRACT', 'FORM', 'DECLARATION')), validation_state VARCHAR(30) NOT NULL DEFAULT 'USER_DECLARED' CHECK (validation_state IN ('USER_DECLARED', 'EVIDENCE_SUBMITTED', 'EVIDENCE_VALIDATED', 'REQUIREMENT_VERIFIED')), reviewer_notes TEXT, verified_at TIMESTAMP WITH TIME ZONE, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_findings (id VARCHAR(36) PRIMARY KEY, business_profile_id VARCHAR(36) NOT NULL REFERENCES business_profiles(id) ON DELETE CASCADE, title VARCHAR(150) NOT NULL, description TEXT, risk_level VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')), status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'MITIGATED', 'CLOSED')), mitigation_plan TEXT, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS document_templates (id VARCHAR(36) PRIMARY KEY, code VARCHAR(50) NOT NULL UNIQUE, title VARCHAR(150) NOT NULL, category VARCHAR(50) NOT NULL, template_body TEXT NOT NULL, disclaimer TEXT NOT NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS business_documents (id VARCHAR(64) PRIMARY KEY, template_code VARCHAR(50), business_profile_id VARCHAR(36) REFERENCES business_profiles(id) ON DELETE SET NULL, provider_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', title VARCHAR(200), category VARCHAR(50), rendered_body TEXT, watermark VARCHAR(100), disclaimer TEXT, version INTEGER NOT NULL DEFAULT 1, status VARCHAR(30) NOT NULL DEFAULT 'DRAFT', signed_by INTEGER REFERENCES usuarios(id) ON DELETE SET NULL, signature_hash VARCHAR(128), signed_at TIMESTAMP WITH TIME ZONE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);\nCREATE TABLE IF NOT EXISTS document_audit_logs (id VARCHAR(64) PRIMARY KEY, document_id VARCHAR(64) NOT NULL REFERENCES business_documents(id) ON DELETE CASCADE, tenant_id VARCHAR(64) NOT NULL DEFAULT 'default', provider_id VARCHAR(64) NOT NULL DEFAULT 'system', actor_id VARCHAR(64) NOT NULL DEFAULT 'system', action VARCHAR(50) NOT NULL, metadata TEXT, created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP);\nCREATE INDEX IF NOT EXISTS idx_business_profiles_provider ON business_profiles(provider_id);\nCREATE INDEX IF NOT EXISTS idx_business_tasks_profile ON business_tasks(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_business_evidences_task ON business_evidences(task_id);\nCREATE INDEX IF NOT EXISTS idx_business_findings_profile ON business_findings(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_business_requirements_vert ON business_requirements(vertical_id);\nCREATE INDEX IF NOT EXISTS idx_business_documents_provider ON business_documents(provider_id);\nCREATE INDEX IF NOT EXISTS idx_audit_logs_document ON document_audit_logs(document_id);",

  '062_optimize_business_saas_postgres.sql': "-- 062: PostgreSQL optimization\nCREATE INDEX IF NOT EXISTS idx_business_tasks_profile_id ON business_tasks(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_business_evidences_task_id ON business_evidences(task_id);\nCREATE INDEX IF NOT EXISTS idx_business_findings_profile_id ON business_findings(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_business_documents_provider_tenant ON business_documents(provider_id, tenant_id);\nCREATE INDEX IF NOT EXISTS idx_business_documents_profile_id ON business_documents(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_document_audit_logs_doc_id ON document_audit_logs(document_id);\nCREATE INDEX IF NOT EXISTS idx_business_evidences_admin_queue ON business_evidences (created_at ASC) WHERE validation_state IN ('EVIDENCE_SUBMITTED', 'USER_DECLARED');\nCREATE INDEX IF NOT EXISTS idx_business_tasks_active ON business_tasks(business_profile_id, stage) WHERE status IN ('IN_PROGRESS', 'PENDING');\nCREATE INDEX IF NOT EXISTS idx_business_findings_open ON business_findings(business_profile_id, risk_level) WHERE status = 'OPEN';\nDO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'document_audit_logs') THEN ALTER TABLE document_audit_logs ALTER COLUMN metadata TYPE JSONB USING metadata::jsonb; CREATE INDEX IF NOT EXISTS idx_document_audit_logs_metadata_gin ON document_audit_logs USING GIN (metadata); END IF; END $$;\nDO $$ DECLARE tbl TEXT; saas_tables TEXT[] := ARRAY['business_profiles', 'business_tasks', 'business_evidences', 'business_findings', 'business_documents', 'document_audit_logs']; BEGIN FOREACH tbl IN ARRAY saas_tables LOOP IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl) THEN IF NOT (SELECT relrowsecurity FROM pg_class WHERE relname = tbl) THEN EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', tbl); END IF; EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_%I ON %I; CREATE POLICY tenant_isolation_%I ON %I FOR ALL USING (tenant_id = current_setting(\'\'app.tenant_id\'\', true) OR current_setting(\'\'app.tenant_id\'\', true) IS NULL);', tbl, tbl, tbl, tbl); END IF; END LOOP; END $$;\nCREATE INDEX IF NOT EXISTS idx_business_tasks_profile_status_score ON business_tasks (business_profile_id, status) INCLUDE (id);\nDO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'business_profiles') THEN IF NOT EXISTS (SELECT 1 FROM information_schema.constraint_column_usage WHERE table_name = 'business_profiles' AND constraint_name = 'check_compliance_score_range') THEN ALTER TABLE business_profiles ADD CONSTRAINT check_compliance_score_range CHECK (compliance_score >= 0.00 AND compliance_score <= 100.00); END IF; END IF; END $$;\nCREATE OR REPLACE FUNCTION calculate_glowapp_business_score(p_profile_id TEXT) RETURNS NUMERIC AS $$ DECLARE v_task_score NUMERIC := 0; v_finding_penalty NUMERIC := 0; v_final_score NUMERIC := 0; BEGIN SELECT COALESCE(ROUND((COUNT(CASE WHEN status = 'VERIFIED' THEN 1 END)::numeric / GREATEST(COUNT(*), 1)) * 80, 2), 0) INTO v_task_score FROM business_tasks WHERE business_profile_id = p_profile_id; SELECT COALESCE(COUNT(CASE WHEN status = 'OPEN' AND risk_level = 'HIGH' THEN 1 END) * 5.0, 0) INTO v_finding_penalty FROM business_findings WHERE business_profile_id = p_profile_id; v_final_score := GREATEST(0.00, LEAST(100.00, (v_task_score + 20.00) - v_finding_penalty)); RETURN v_final_score; END; $$ LANGUAGE plpgsql STABLE PARALLEL SAFE;",

  '082_memberships.sql': "-- 082: Memberships foundation\nCREATE TABLE IF NOT EXISTS memberships (id VARCHAR(36) PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE, business_profile_id VARCHAR(36) NOT NULL REFERENCES business_profiles(id) ON DELETE CASCADE, role VARCHAR(20) NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('OWNER', 'ADMIN', 'MANAGER', 'MEMBER', 'VIEWER')), status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')), invited_at TIMESTAMP WITH TIME ZONE, accepted_at TIMESTAMP WITH TIME ZONE, created_by_user_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, CONSTRAINT unique_user_business_profile UNIQUE (user_id, business_profile_id));\nCREATE INDEX IF NOT EXISTS idx_memberships_user ON memberships(user_id);\nCREATE INDEX IF NOT EXISTS idx_memberships_business_profile ON memberships(business_profile_id);\nCREATE INDEX IF NOT EXISTS idx_memberships_user_status ON memberships(user_id, status);",

  '114_memberships_sub_rol.sql': "-- 114: Memberships sub_rol\nBEGIN;\nALTER TABLE memberships ADD COLUMN IF NOT EXISTS sub_rol VARCHAR(50);\nUPDATE memberships m SET sub_rol = upper(trim(sm.sub_rol)) FROM salon_miembros sm WHERE m.business_profile_id = left('salon-' || sm.salon_id::text, 36) AND m.user_id = sm.user_id AND m.sub_rol IS NULL;\nUPDATE memberships SET sub_rol = CASE role WHEN 'OWNER' THEN 'DUEÑO' WHEN 'ADMIN' THEN 'ADMINISTRADOR' WHEN 'MANAGER' THEN 'RECEPCIONISTA' ELSE 'EMPLEADO' END WHERE sub_rol IS NULL AND business_profile_id LIKE 'salon-%';\nCOMMIT;",

  '118_drop_salon_miembros.sql': "-- 118: Drop legacy salon_miembros\nBEGIN;\nDO $$ DECLARE huerfanas integer; total integer; BEGIN IF to_regclass('public.salon_miembros') IS NULL THEN RAISE NOTICE 'T-127: salon_miembros no existe; nada que retirar.'; RETURN; END IF; SELECT count(*) INTO total FROM salon_miembros; SELECT count(*) INTO huerfanas FROM salon_miembros sm WHERE NOT EXISTS (SELECT 1 FROM memberships m WHERE m.user_id = sm.user_id AND m.business_profile_id = left('salon-' || sm.salon_id::text, 36)); IF huerfanas > 0 THEN RAISE EXCEPTION 'T-127 abortado: hay % de % filas en salon_miembros sin membresía canónica', huerfanas, total; END IF; RAISE NOTICE 'T-127: % filas heredadas, todas con membresía canónica. Se retira la tabla.', total; DROP TABLE salon_miembros CASCADE; END $$;\nCOMMIT;"
};

const MIGRACIONES = [
  'init.sql',
  '054_create_core_tables.sql',
  '055_create_tenants_table.sql',
  '056_add_tenant_id_to_core_tables.sql',
  '057_backfill_tenant_id.sql',
  '058_enable_rls_policies.sql',
  '065_multi_tenant_hardening.sql',
  '067_create_multi_salon_ddl.sql',
  '068_force_rls_strict_isolation.sql',
  '107_rls_politicas_sin_contexto.sql',
  '012_business_engine.sql',
  '062_optimize_business_saas_postgres.sql',
  '082_memberships.sql',
  '114_memberships_sub_rol.sql',
  '118_drop_salon_miembros.sql',
];

async function main() {
  if (!ADMIN_URL) {
    console.error('[ERROR] Falta DATABASE_URL_ADMIN (o DATABASE_URL): no se puede preparar la base.');
    process.exit(2);
  }

  const cliente = new Client({ connectionString: ADMIN_URL });
  try {
    await cliente.connect();
  } catch (error) {
    console.error(`[ERROR] No se pudo conectar a la base: ${error.message}`);
    process.exit(2);
  }

  try {
    const { rows: [estado] } = await cliente.query(
      `SELECT count(*)::int AS tablas
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname NOT IN ('spatial_ref_sys')`
    );
    const baseVacia = estado.tablas === 0;

    console.log(
      baseVacia
        ? '📦 Base vacía: se aplica el esquema completo (init.sql incluido).'
        : `📦 Base ya inicializada (${estado.tablas} tablas): se aplican solo las migraciones idempotentes.`
    );

    for (const nombre of MIGRACIONES) {
      if (nombre === 'init.sql' && !baseVacia) {
        console.log('   ⏭️  init.sql omitido — no es idempotente y el esquema ya existe.');
        continue;
      }
      const sql = MIGRATION_SQL[nombre];
      if (!sql) {
        console.error(`[ERROR] Migración no encontrada: ${nombre}`);
        process.exit(1);
      }
      try {
        await cliente.query(sql);
        console.log(`   [OK] ${nombre}`);
      } catch (error) {
        console.error(`   [ERROR] ${nombre}: ${error.message}`);
        process.exit(1);
      }
    }

    // ── 2. Roles RLS ───────────────────────────────────────────────────────
    console.log('\n👤 Creando los roles RLS:');
    const fs = require('fs');
    const path = require('path');
    const setupRlsPath = path.join(__dirname, 'setupRlsRole.sql');
    if (fs.existsSync(setupRlsPath)) {
      await cliente.query(fs.readFileSync(setupRlsPath, 'utf8'));
    } else {
      await cliente.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_rls_user') THEN
            CREATE ROLE app_rls_user LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOINHERIT;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_system') THEN
            CREATE ROLE app_system LOGIN NOSUPERUSER BYPASSRLS NOCREATEDB NOCREATEROLE NOINHERIT;
          END IF;
        END $$;
      `);
    }

    await cliente.query(`
      DO $$
      BEGIN
         IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_owner') THEN
           CREATE ROLE app_owner LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOINHERIT;
         END IF;
       END $$;
    `);
    for (const rol of ['app_rls_user', 'app_owner']) {
      await cliente.query(`ALTER ROLE ${rol} WITH LOGIN PASSWORD '${PASSWORD.replace(/'/g, "''")}'`);
    }
    console.log('   [OK] app_rls_user (aplicación), app_system (BYPASSRLS), app_owner (propietario de prueba)');

    // ── 3. Propiedad de las tablas multi-tenant ────────────────────────────
    const { rows: tablas } = await cliente.query(
      `SELECT c.relname
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'
          AND EXISTS (SELECT 1 FROM information_schema.columns i
                       WHERE i.table_schema = 'public' AND i.table_name = c.relname
                         AND i.column_name = 'tenant_id')
        ORDER BY c.relname`
    );
    console.log(`\n🔑 Transfiriendo la propiedad de ${tablas.length} tablas multi-tenant a app_owner:`);
    for (const { relname } of tablas) {
      await cliente.query(`ALTER TABLE public."${relname}" OWNER TO app_owner`);
    }
    await cliente.query('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_owner');
    await cliente.query('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_owner');
    await cliente.query('GRANT USAGE ON SCHEMA public TO app_owner');
    console.log(`   [OK] ${tablas.map((t) => t.relname).join(', ')}`);

    // ── 4. Resumen verificable ─────────────────────────────────────────────
    await cliente.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
           WHERE c.relname = 'business_requirements'
        ) THEN
          ALTER TABLE business_requirements ENABLE ROW LEVEL SECURITY;
          CREATE POLICY catalog_business_requirements ON business_requirements
            USING (true) WITH CHECK (true);
        END IF;
      END $$;
    `);
    const EXENTAS_DE_FORCE = [];

    await cliente.query(`
      DO $$
      DECLARE t record;
      BEGIN
        FOR t IN
          SELECT c.relname
            FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
           WHERE n.nspname = 'public' AND c.relkind = 'r'
             AND NOT c.relforcerowsecurity
             AND EXISTS (SELECT 1 FROM information_schema.columns i
                          WHERE i.table_schema = 'public' AND i.table_name = c.relname
                            AND i.column_name = 'tenant_id')
             AND EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)
        LOOP
          EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t.relname);
        END LOOP;
      END $$;
    `);

    const { rows: [resumen] } = await cliente.query(
      `SELECT count(*)::int AS total,
              count(*) FILTER (WHERE c.relforcerowsecurity)::int AS con_force,
              coalesce(array_agg(c.relname::text ORDER BY c.relname)
                       FILTER (WHERE NOT c.relforcerowsecurity), '{}'::text[]) AS sin_force,
              coalesce(array_agg(c.relname::text ORDER BY c.relname)
                       FILTER (WHERE NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)), '{}'::text[]) AS sin_politica
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'
          AND EXISTS (SELECT 1 FROM information_schema.columns i
                       WHERE i.table_schema = 'public' AND i.table_name = c.relname
                         AND i.column_name = 'tenant_id')`
    );
    console.log(`\n📊 Tablas con tenant_id: ${resumen.total} | con FORCE: ${resumen.con_force}`);
    console.log(`   exentas de FORCE (deliberado): ${EXENTAS_DE_FORCE.join(', ')}`);
    console.log(`   sin FORCE (catálogo)         : ${resumen.sin_force.join(', ') || '(ninguna)'}`);
    console.log(`   sin política                 : ${resumen.sin_politica.join(', ') || '(ninguna)'}`);

    const base = ADMIN_URL.replace(/\/\/[^@]*@/, '//');
    console.log('\n[OK] Base preparada. URLs para las pruebas:');
    console.log(`   app (DATABASE_URL)              postgres://app_rls_user:***@${base.split('//')[1]}`);
    console.log(`   propietario (TEST_DATABASE_URL) postgres://app_owner:***@${base.split('//')[1]}`);

    const sinForceInesperadas = resumen.sin_force.filter((t) => !EXENTAS_DE_FORCE.includes(t));
    const sinPoliticaInesperadas = resumen.sin_politica.filter((t) => !EXENTAS_DE_FORCE.includes(t));
    if (sinForceInesperadas.length || sinPoliticaInesperadas.length) {
      console.error(
        '[ERROR] Aislamiento incompleto. Sin FORCE: ' +
        `${sinForceInesperadas.join(', ') || '—'}. Sin política: ${sinPoliticaInesperadas.join(', ') || '—'}. Revisa 068.`
      );
      process.exit(1);
    }
    process.exit(0);
  } catch (error) {
    console.error(`\n[ERROR] Error preparando la base: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  } finally {
    await cliente.end().catch(() => {});
  }
}

main();
