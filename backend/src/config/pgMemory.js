/**
 * backend/src/config/pgMemory.js
 *
 * HARNESS DE BASE DE DATOS EN MEMORIA (solo NODE_ENV=test o USE_PG_MEM=true)
 *
 * Por qué existe este archivo:
 *   Antes había DOS bases de datos distintas en modo test.
 *   - Sequelize (src/config/database.js) creaba un pg-mem SIN esquema -> toda query de modelo moría
 *     con 'relation "memberships" does not exist' (las suites business* daban 500).
 *   - El pool crudo (src/config/db.js) no usaba pg-mem en absoluto: caía en handleMemoryQuery,
 *     que devuelve filas fabricadas -> los repositorios SQL nunca se ejercitaban de verdad.
 *   Ahora hay UNA sola instancia de pg-mem, con esquema y datos de referencia, compartida por
 *   Sequelize y por el pool crudo. Así las suites de integración hablan con un Postgres real (en
 *   memoria) en vez de con mocks.
 *
 * Seguridad en producción: pg-mem es devDependency (no existe en la imagen: `npm ci --only=production`),
 * por eso el require va en try/catch: si no está instalado, el módulo queda desactivado y el backend
 * sigue usando la configuración real de PostgreSQL en lugar de tumbar el arranque.
 */

const isMemoryMode = process.env.NODE_ENV === 'test' || process.env.USE_PG_MEM === 'true';

// Esquema del harness. Es permisivo a propósito (sin FK ni CHECK): el objetivo es que las suites de
// integración ejerciten el SQL y las queries reales, no re-validar las restricciones de las
// migraciones de producción (ver backend/src/db/migrations/012_business_engine.sql y 013_memberships.sql).
const SCHEMA_SQL = `
  CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    phone VARCHAR(20),
    foto_url TEXT,
    auth_provider VARCHAR(50) DEFAULT 'LOCAL',
    provider_id VARCHAR(255),
    rol VARCHAR(20),
    worker_type VARCHAR(50),
    onboarding_completo BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    habeas_data_accepted_at TIMESTAMP,
    habeas_data_ip VARCHAR(45)
  );

  CREATE TABLE IF NOT EXISTS business_verticals (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_profiles (
    id VARCHAR(36) PRIMARY KEY,
    provider_id VARCHAR(36),
    tenant_id VARCHAR(36),
    vertical_id VARCHAR(36),
    user_id INTEGER,
    name VARCHAR(150) NOT NULL,
    onboarding_mode VARCHAR(30) DEFAULT 'NEW_BUSINESS',
    lifecycle_stage VARCHAR(30) DEFAULT 'IDEA',
    compliance_score NUMERIC(5,2) DEFAULT 0.00,
    city VARCHAR(100) DEFAULT 'Bogotá',
    country VARCHAR(100) DEFAULT 'Colombia',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_requirements (
    id VARCHAR(36) PRIMARY KEY,
    vertical_id VARCHAR(36),
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    legal_basis TEXT,
    jurisdiction VARCHAR(50) DEFAULT 'NATIONAL',
    domain_context VARCHAR(30),
    evidence_required VARCHAR(50) DEFAULT 'DOCUMENT',
    frequency_months INTEGER DEFAULT 12,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_tasks (
    id VARCHAR(36) PRIMARY KEY,
    business_profile_id VARCHAR(36),
    requirement_id VARCHAR(36),
    tenant_id VARCHAR(36),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    stage VARCHAR(20) DEFAULT 'ENTENDER',
    status VARCHAR(20) DEFAULT 'PENDING',
    due_date TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_evidences (
    id VARCHAR(36) PRIMARY KEY,
    task_id VARCHAR(36),
    file_path VARCHAR(255),
    evidence_type VARCHAR(30) DEFAULT 'DOCUMENT',
    validation_state VARCHAR(30) DEFAULT 'USER_DECLARED',
    reviewer_notes TEXT,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_findings (
    id VARCHAR(36) PRIMARY KEY,
    business_profile_id VARCHAR(36),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    risk_level VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(20) DEFAULT 'OPEN',
    mitigation_plan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS document_templates (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    template_body TEXT NOT NULL,
    disclaimer TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS business_documents (
    id VARCHAR(36) PRIMARY KEY,
    template_code VARCHAR(50),
    business_profile_id VARCHAR(36),
    provider_id VARCHAR(36),
    tenant_id VARCHAR(36),
    title VARCHAR(150),
    category VARCHAR(50),
    rendered_body TEXT,
    watermark VARCHAR(100),
    disclaimer TEXT,
    version INTEGER DEFAULT 1,
    status VARCHAR(30) DEFAULT 'DRAFT',
    signed_by VARCHAR(36),
    signature_hash VARCHAR(128),
    signed_at TIMESTAMP,
    supersedes_id VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS document_audit_logs (
    id VARCHAR(36) PRIMARY KEY,
    document_id VARCHAR(36),
    tenant_id VARCHAR(36),
    provider_id VARCHAR(36),
    actor_id VARCHAR(36),
    action VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS memberships (
    id VARCHAR(36) PRIMARY KEY,
    user_id INTEGER NOT NULL,
    business_profile_id VARCHAR(36) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    invited_at TIMESTAMP,
    accepted_at TIMESTAMP,
    created_by_user_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS services (
    id VARCHAR(36) PRIMARY KEY,
    provider_id INTEGER,
    business_profile_id VARCHAR(36),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT true
  );

  CREATE TABLE IF NOT EXISTS bookings (
    id VARCHAR(36) PRIMARY KEY,
    client_id INTEGER,
    provider_id INTEGER,
    service_id VARCHAR(36),
    business_profile_id VARCHAR(36),
    scheduled_at TIMESTAMP,
    fecha_hora TIMESTAMP,
    duracion_minutos INTEGER,
    valor_bruto NUMERIC(10,2),
    comision_plataforma NUMERIC(10,2),
    impuestos_estado NUMERIC(10,2),
    pago_neto_prestador NUMERIC(10,2),
    tarifa_reserva NUMERIC(10,2),
    service_address TEXT,
    notes TEXT,
    estado VARCHAR(50),
    payment_status VARCHAR(20),
    pin_verificacion VARCHAR(10),
    productos_adicionales JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS tenants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    slug VARCHAR(100),
    es_plataforma BOOLEAN DEFAULT false
  );

  CREATE TABLE IF NOT EXISTS productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255),
    sku VARCHAR(40),
    costo NUMERIC(10,2),
    stock INTEGER DEFAULT 0,
    tenant_id INTEGER
  );

  CREATE TABLE IF NOT EXISTS listas_precios (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(40) UNIQUE,
    nombre VARCHAR(120),
    rol_destino VARCHAR(20),
    incluye_iva BOOLEAN DEFAULT true,
    vigente_desde DATE DEFAULT CURRENT_DATE,
    vigente_hasta DATE,
    estado VARCHAR(20) DEFAULT 'ACTIVA',
    tenant_id INTEGER
  );

  CREATE TABLE IF NOT EXISTS precios_producto (
    lista_id INTEGER,
    producto_id INTEGER,
    precio NUMERIC(10,2),
    unidad_minima INTEGER DEFAULT 1,
    vigente_desde DATE DEFAULT CURRENT_DATE,
    vigente_hasta DATE,
    tenant_id INTEGER,
    PRIMARY KEY (lista_id, producto_id)
  );

  CREATE TABLE IF NOT EXISTS precios_historial (
    id SERIAL PRIMARY KEY,
    lista_id INTEGER,
    producto_id INTEGER,
    precio_anterior NUMERIC(10,2),
    precio_nuevo NUMERIC(10,2),
    actor_id INTEGER,
    origen VARCHAR(30),
    motivo TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tenant_id INTEGER
  );
`;

const lit = (value) => (value === null || value === undefined ? 'NULL' : `'${String(value).replace(/'/g, "''")}'`);

/**
 * Datos de referencia (verticales, requisitos y plantillas) tomados del mismo seed que usa el
 * Business Engine, para que las suites de integración no dependan de filas pre-cargadas a mano.
 */
function seedReferenceData(pgMem) {
  try {
    const { verticals, requirements, documentTemplates } = require('../db/seed_business_data');

    const verticalRows = verticals
      .map((v) => `(${lit(v.id)}, ${lit(v.code)}, ${lit(v.name)}, ${lit(v.description)})`)
      .join(',\n');
    if (verticalRows) {
      pgMem.public.none(
        `INSERT INTO business_verticals (id, code, name, description) VALUES ${verticalRows}
         ON CONFLICT (id) DO NOTHING`
      );
    }

    const requirementRows = requirements
      .map((r) => `(${lit(r.id)}, ${lit(r.vertical_id)}, ${lit(r.code)}, ${lit(r.title)}, ${lit(r.description)}, ` +
        `${lit(r.legal_basis)}, ${lit(r.jurisdiction)}, ${lit(r.domain_context)}, ${lit(r.evidence_required)}, ` +
        `${r.frequency_months === undefined ? 'NULL' : Number(r.frequency_months)})`)
      .join(',\n');
    if (requirementRows) {
      pgMem.public.none(
        `INSERT INTO business_requirements
           (id, vertical_id, code, title, description, legal_basis, jurisdiction, domain_context, evidence_required, frequency_months)
         VALUES ${requirementRows}
         ON CONFLICT (id) DO NOTHING`
      );
    }

    const templateRows = documentTemplates
      .map((t) => `(${lit(t.id)}, ${lit(t.code)}, ${lit(t.title)}, ${lit(t.category)}, ${lit(t.template_body)}, ${lit(t.disclaimer)})`)
      .join(',\n');
    if (templateRows) {
      pgMem.public.none(
        `INSERT INTO document_templates (id, code, title, category, template_body, disclaimer)
         VALUES ${templateRows}
         ON CONFLICT (id) DO NOTHING`
      );
    }
  } catch (err) {
    console.error(`⚠️ [pgMemory] No se pudieron cargar los datos de referencia: ${err.message}`);
  }
}

let adapter = null;
let enabled = false;

if (isMemoryMode) {
  try {
    // eslint-disable-next-line global-require
    const { newDb } = require('pg-mem');
    const pgMem = newDb();
    pgMem.public.none(SCHEMA_SQL);
    seedReferenceData(pgMem);
    adapter = pgMem.adapters.createPg();
    enabled = true;
  } catch (err) {
    console.error(
      `⚠️ [pgMemory] pg-mem no disponible (${err.message}). ` +
      'Se usará la configuración real de PostgreSQL en lugar del harness en memoria.'
    );
  }
}

module.exports = { isMemoryMode, enabled, adapter };
