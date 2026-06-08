-- backend/migrations/004_align_sequences.sql
-- Sincronizar secuencia de usuarios
SELECT setval('usuarios_id_seq', (SELECT COALESCE(MAX(id), 0) FROM usuarios) + 1, false);

-- Sincronizar secuencia de bookings/citas si existe
SELECT setval('bookings_id_seq', (SELECT COALESCE(MAX(id), 0) FROM bookings) + 1, false);

-- Sincronizar secuencia de servicios si existe
SELECT setval('services_id_seq', (SELECT COALESCE(MAX(id), 0) FROM services) + 1, false);
