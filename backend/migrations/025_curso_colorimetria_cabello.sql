-- migrations/025_curso_colorimetria_cabello.sql
-- Crear curso de Colorimetría y Tendencias de Color de Cabello en la Academia Glow

INSERT INTO academy_courses (id, title, description, category, badge_name) VALUES
('c0000000-0000-0000-0000-000000000003', 'Especialista en Colorimetría Avanzada y Tendencias de Color', 'Domina la teoría del color, decoloraciones seguras, formulación de tinturas y las últimas tendencias (Balayage, Babylights) para potenciar tu portafolio de estilista.', 'color', 'Experta Colorista Glow')
ON CONFLICT (id) DO NOTHING;

-- Módulos
INSERT INTO academy_modules (id, course_id, title, sort_order) VALUES
('b0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003', 'Módulo 1: Fundamentos de Colorimetría Capilar', 1),
('b0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'Módulo 2: Técnicas de Decoloración y Balayage', 2)
ON CONFLICT (id) DO NOTHING;

-- Lecciones Módulo 1
INSERT INTO academy_lessons (id, module_id, title, video_url, content_text, sort_order) VALUES
('a0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000004', '1. La Estrella de Oswald y Neutralización', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Comprender el círculo cromático es el pilar de toda colorista. Para neutralizar un reflejo amarillo no deseado, se debe aplicar un matizante con pigmento violeta. Los reflejos naranjas se neutralizan con azul, y los rojos con verde.', 1),
('a0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000004', '2. Alturas de Tono y Fondos de Aclaración', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Las alturas de tono van del 1 (negro) al 10 (rubio extra claro). Cada altura de tono revela un fondo de aclaración específico al decolorar (ej. fondo 7 es naranja, fondo 9 es amarillo muy claro). Debes formular la tintura basándote en el fondo expuesto.', 2)
ON CONFLICT (id) DO NOTHING;

-- Lecciones Módulo 2
INSERT INTO academy_lessons (id, module_id, title, video_url, content_text, sort_order) VALUES
('a0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000005', '3. Técnicas de Empapelado y Cardado para Balayage', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Para lograr una transición suave sin marcas bruscas en un Balayage, es vital realizar la técnica de cardado (backcombing) antes de aplicar el decolorante. Mantén una saturación uniforme y evita el exceso de calor en el papel aluminio.', 1)
ON CONFLICT (id) DO NOTHING;

-- Examen / Quizzes
INSERT INTO academy_quizzes (id, course_id, question, options, correct_index) VALUES
('e0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003', '¿Qué pigmento se debe utilizar para neutralizar un reflejo naranja no deseado en el cabello?', '["Pigmento rojo", "Pigmento azul", "Pigmento amarillo", "Pigmento violeta"]'::jsonb, 1),
('e0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'Si decoloramos el cabello y obtenemos un fondo de aclaración altura 9 (amarillo claro), ¿cuál es el matizador ideal para un rubio platinado cenizo?', '["Un matizador cobre", "Un matizador violeta/iridiscente", "Un matizador rojo", "No se necesita matizar"]'::jsonb, 1)
ON CONFLICT (id) DO NOTHING;
