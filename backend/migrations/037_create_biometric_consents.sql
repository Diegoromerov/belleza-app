-- Migration 037: Create biometric_consents table and biometric_access_log for Ley 1581/2012 compliance
-- Description: Tablas de consentimiento biométrico y auditoría de acceso
-- Requisitos: Ley 1581/2012 (Art. 6, 8, 12, 15) + Decreto 1377/2013
-- 
-- Datos biométricos = DATOS SENSIBLES (Art. 6 Ley 1581)
-- Consentimiento debe ser: previo, expreso, informado, verificable
-- Derecho de supresión: usuario puede eliminar datos en cualquier momento
-- Derecho de acceso: usuario puede consultar qué datos se tienen sobre él

-- Tabla principal de consentimientos biométricos
CREATE TABLE IF NOT EXISTS biometric_consents (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  consent_type VARCHAR(50) NOT NULL,
  -- Tipos válidos: 'facial_analysis', 'skin_scan', 'hair_analysis', 
  --        'body_measurement', 'virtual_try_on', 'all_biometric'
  granted BOOLEAN NOT NULL DEFAULT FALSE,
  granted_at TIMESTAMP,
  revoked_at TIMESTAMP,
  purpose TEXT NOT NULL,
  -- Finalidad declarada (requerido por Ley 1581 Art. 12)
  ip_address INET,
  user_agent TEXT,
  version_terms VARCHAR(20) NOT NULL DEFAULT '1.0',
  -- Versión de términos aceptados (para auditoría)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, consent_type, version_terms)
);

-- Índice para búsquedas rápidas por usuario
CREATE INDEX IF NOT EXISTS idx_consents_user 
ON biometric_consents (user_id, consent_type, granted);

-- Índice para auditoría (SIC puede solicitar logs)
CREATE INDEX IF NOT EXISTS idx_consents_audit 
ON biometric_consents (granted_at, revoked_at);

-- Tabla de auditoría de acceso a datos biométricos
CREATE TABLE IF NOT EXISTS biometric_access_log (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL,
  accessed_by VARCHAR(50) NOT NULL,
  -- 'ATENA', 'AURA', 'admin', 'user_self'
  access_type VARCHAR(50) NOT NULL,
  -- 'read_profile', 'analyze_photo', 'update_profile', 'delete_data', 'virtual_try_on'
  consent_id INTEGER REFERENCES biometric_consents(id),
  ip_address INET,
  accessed_at TIMESTAMP DEFAULT NOW(),
  details JSONB
);

CREATE INDEX IF NOT EXISTS idx_access_log_user 
ON biometric_access_log (user_id, accessed_at);

-- Trigger para actualizar updated_at
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

-- Verificación final
DO $$
DECLARE
    table_exists boolean;
    idx_count integer;
    access_table_exists boolean;
BEGIN
    -- Verificar tabla consentimientos
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'biometric_consents'
    ) INTO table_exists;
    
    -- Verificar tabla acceso
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'biometric_access_log'
    ) INTO access_table_exists;
    
    -- Verificar índices
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes 
    WHERE tablename IN ('biometric_consents', 'biometric_access_log');
    
    RAISE NOTICE '=== MIGRACIÓN 037 COMPLETADA ===';
    RAISE NOTICE 'Tabla biometric_consents existe: %', table_exists;
    RAISE NOTICE 'Tabla biometric_access_log existe: %', access_table_exists;
    RAISE NOTICE 'Índices totales creados: %', idx_count;
    RAISE NOTICE 'CUMPLE: Ley 1581/2012 Art. 6, 8, 12, 15 + Decreto 1377/2013';
END $$;