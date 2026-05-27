-- 1. Usuarios base (contraseña para todos es: password123)
-- Hash bcrypt de "password123": $2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O
INSERT INTO usuarios (id, email, password_hash, nombre, phone, auth_provider, provider_id, rol, onboarding_completo) VALUES
(1, 'admin@beautyapp.com', '$2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O', 'Admin System', '+573000000000', 'LOCAL', 'admin-local', 'PRESTADOR', true),
(2, 'maria@correo.com', '$2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O', 'María López', '+573001112222', 'LOCAL', 'maria-local', 'PRESTADOR', true),
(3, 'carlos@correo.com', '$2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O', 'Carlos Ruiz', '+573003334444', 'LOCAL', 'carlos-local', 'PRESTADOR', true),
(4, 'ana@cliente.com', '$2a$10$XG3dsKkJJFx9cldnFJHGt.FJqYVTNiSsoJAaSVwUQkYis22mXk/7O', 'Ana Gómez', '+573005556666', 'LOCAL', 'ana-local', 'CLIENTE', true);

-- Ajustar la secuencia del serial tras las inserciones manuales de ID
SELECT setval('usuarios_id_seq', 4);

-- 2. Perfiles de prestadores (con coordenadas geoespaciales en Fontibón, Bogotá y estado APROBADO)
INSERT INTO perfiles_prestador (id, business_name, description, is_online, estatus_verificacion, ubicacion, metodo_retiro, numero_cuenta_nequi, documento_titular) VALUES
(2, 'Studio María Hair', 'Especialista en balayage y cortes modernos', true, 'APROBADO', ST_SetSRID(ST_MakePoint(-74.0817, 4.6097), 4326), 'NEQUI', '+573001112222', '1018222333'),
(3, 'Carlos Nails & Spa', 'Manicura semipermanente y nail art', false, 'APROBADO', ST_SetSRID(ST_MakePoint(-74.1422, 4.6735), 4326), 'NEQUI', '+573003334444', '1019444555');

-- 3. Servicios
INSERT INTO services (provider_id, name, description, price, duration_minutes, category) VALUES
(2, 'Corte + Lavado', 'Incluye diagnóstico capilar', 35.00, 45, 'hair'),
(2, 'Balayage Completo', 'Técnica de iluminación personalizada', 120.00, 150, 'hair'),
(3, 'Manicura Semipermanente', 'Limpieza, limado y esmaltado duradero', 25.00, 60, 'nails');

-- 4. Cita de prueba (confirmada para iniciar servicio)
INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, valor_bruto, estado, pin_verificacion) VALUES
(4, 2, (SELECT id FROM services WHERE name='Corte + Lavado' LIMIT 1), '2026-05-25 15:00:00+00', 35.00, 'CONFIRMADA', '4821');