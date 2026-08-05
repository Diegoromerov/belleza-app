-- Migration 033: Añade columna id a academy_certificates y establece la PK
-- La tabla original (008) tiene PK compuesta (provider_id, course_id)
-- Esta migración añade un surrogate key 'id' y convierte la PK compuesta en UNIQUE

DO $$
BEGIN
    -- Añadir columna id si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='academy_certificates' AND column_name='id') THEN
        ALTER TABLE academy_certificates ADD COLUMN id SERIAL;
    END IF;
    
    -- Hacer id la primary key (primero quitar la PK compuesta)
    -- NOTA: Esto requiere que no haya FKs referenciando la PK compuesta
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name='academy_certificates' AND constraint_type='PRIMARY KEY' AND constraint_name LIKE '%provider_id%'
    ) THEN
        ALTER TABLE academy_certificates DROP CONSTRAINT academy_certificates_pkey;
        ALTER TABLE academy_certificates ADD PRIMARY KEY (id);
        ALTER TABLE academy_certificates ADD CONSTRAINT unique_provider_course UNIQUE (provider_id, course_id);
    END IF;
END $$;
