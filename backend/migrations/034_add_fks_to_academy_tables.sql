-- Migration 034: Añade FKs a academy_certificates(id) después de que migración 033 cree la columna
-- Estas FKs referencian la nueva PK surrogate 'id' de academy_certificates

DO $$
BEGIN
    -- FK en learning_paths.badge_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name='learning_paths' AND constraint_name='fk_learning_paths_badge_id'
    ) THEN
        ALTER TABLE learning_paths 
        ADD CONSTRAINT fk_learning_paths_badge_id 
        FOREIGN KEY (badge_id) REFERENCES academy_certificates(id);
    END IF;

    -- FK en user_levels.badge_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name='user_levels' AND constraint_name='fk_user_levels_badge_id'
    ) THEN
        ALTER TABLE user_levels 
        ADD CONSTRAINT fk_user_levels_badge_id 
        FOREIGN KEY (badge_id) REFERENCES academy_certificates(id);
    END IF;

    -- FK en qr_certificates.certificate_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name='qr_certificates' AND constraint_name='fk_qr_certificates_certificate_id'
    ) THEN
        ALTER TABLE qr_certificates 
        ADD CONSTRAINT fk_qr_certificates_certificate_id 
        FOREIGN KEY (certificate_id) REFERENCES academy_certificates(id);
    END IF;
END $$;