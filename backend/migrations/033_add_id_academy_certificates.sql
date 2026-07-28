-- Migration 033_add_id_academy_certificates.sql
-- Añade columna id a academy_certificates y establece la PK

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='academy_certificates' AND column_name='id') THEN
        ALTER TABLE academy_certificates ADD COLUMN id SERIAL PRIMARY KEY;
    END IF;
END $$;

-- Si ya existe una PK compuesta, mantenemos UNIQUE sobre (provider_id, course_id)
ALTER TABLE academy_certificates ADD CONSTRAINT unique_provider_course UNIQUE (provider_id, course_id);
