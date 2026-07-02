-- backend/migrations/013_premium_evolution_validation.sql
-- Migración para el Área Premium: Validación Médica de Diagnósticos IA

CREATE TABLE IF NOT EXISTS validaciones_medicas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  ai_diagnostic_id INTEGER REFERENCES ai_diagnostics(id) ON DELETE SET NULL,
  profesional_id UUID REFERENCES profesionales_medicos(id) ON DELETE CASCADE,
  estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'revisado')),
  nota_profesional TEXT,
  payment_reference VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  fecha_respuesta TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_validaciones_medicas_user ON validaciones_medicas(user_id);
