-- backend/migrations/004_align_sequences.sql
-- Sincronizar secuencia de usuarios (usuarios usa id SERIAL/integer)
SELECT setval('usuarios_id_seq', (SELECT COALESCE(MAX(id), 0) FROM usuarios) + 1, false);

-- Sincronizar secuencia de bookings/citas si existe (bookings usa id UUID)
-- Para evitar errores de función MAX en UUID, hacemos cast a text.
SELECT setval('bookings_id_seq', (SELECT COALESCE(MAX(id::text), '0')::integer FROM bookings WHERE id::text ~ '^[0-9]+$') + 1, false) WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'bookings_id_seq');

-- Sincronizar secuencia de servicios si existe (services usa id UUID o integer)
SELECT setval('services_id_seq', (SELECT COALESCE(MAX(id::text), '0')::integer FROM services WHERE id::text ~ '^[0-9]+$') + 1, false) WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'services_id_seq');
