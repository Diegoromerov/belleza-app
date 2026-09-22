-- ============================================================================
-- Migración 067: DDL Declarativo Completo de Esquema Multi-Sede (SaaS)
-- ============================================================================
-- Garantiza que una instalación desde cero o un entorno de pruebas contenga
-- las tablas esenciales del módulo multi-sede: salones, salon_miembros y salon_invitaciones.
-- Idempotente: usa CREATE TABLE IF NOT EXISTS e índices idempotentes.
-- ============================================================================

BEGIN;

-- 1. Tabla: salones
CREATE TABLE IF NOT EXISTS salones (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    id_dueno INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(150) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(50),
    ciudad VARCHAR(100) DEFAULT 'Fontibón',
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    ubicacion geography(Point, 4326),
    location_enabled BOOLEAN DEFAULT FALSE,
    location_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabla: salon_miembros
CREATE TABLE IF NOT EXISTS salon_miembros (
    id SERIAL PRIMARY KEY,
    salon_id INTEGER NOT NULL REFERENCES salones(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tenant_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    sub_rol VARCHAR(50) NOT NULL DEFAULT 'ESTILISTA',
    estatus VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_salon_miembro UNIQUE (salon_id, user_id)
);

-- 3. Tabla: salon_invitaciones
CREATE TABLE IF NOT EXISTS salon_invitaciones (
    id SERIAL PRIMARY KEY,
    salon_id INTEGER NOT NULL REFERENCES salones(id) ON DELETE CASCADE,
    tenant_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    email_invitado VARCHAR(150) NOT NULL,
    sub_rol VARCHAR(50) NOT NULL DEFAULT 'ESTILISTA',
    token VARCHAR(255) NOT NULL UNIQUE,
    token_hash VARCHAR(255),
    estatus VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Índices para acelerar búsquedas e insumos de aislamiento
CREATE INDEX IF NOT EXISTS idx_salones_dueno ON salones(id_dueno);
CREATE INDEX IF NOT EXISTS idx_salones_tenant ON salones(tenant_id);
CREATE INDEX IF NOT EXISTS idx_salon_miembros_user ON salon_miembros(user_id);
CREATE INDEX IF NOT EXISTS idx_salon_miembros_salon ON salon_miembros(salon_id);
CREATE INDEX IF NOT EXISTS idx_salon_miembros_tenant ON salon_miembros(tenant_id);
CREATE INDEX IF NOT EXISTS idx_salon_invitaciones_token ON salon_invitaciones(token);
CREATE INDEX IF NOT EXISTS idx_salon_invitaciones_email ON salon_invitaciones(email_invitado);

COMMIT;
