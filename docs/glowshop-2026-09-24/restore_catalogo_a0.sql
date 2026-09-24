-- Restauración del catálogo a la línea base acordada (entrega A0, 296 filas)
-- Fuente: docs/glowshop-2026-09-24/precios_antes.csv (export tomado ANTES de cualquier cambio)
--       + backend/migrations/011_seed_mens_products.sql (atributos de la línea masculina)
-- Idempotente: se puede ejecutar N veces. No borra ni sobrescribe nada que no esté en el CSV.
BEGIN;

INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (1, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 45, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (2, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 39, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (3, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (4, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (5, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (6, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (7, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (8, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (9, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (10, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (23, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (24, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (25, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (26, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (27, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (28, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (29, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (30, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (31, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (32, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (45, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (46, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (47, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (48, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (49, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (50, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (51, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (52, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (53, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (54, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (67, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (68, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (69, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (70, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (71, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (72, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (73, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (74, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (75, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (76, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (89, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (90, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (91, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (92, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (93, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (94, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (95, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (96, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (97, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (98, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (111, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (112, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (113, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (114, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (115, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (116, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (117, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (118, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (119, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (120, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (144, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (145, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (146, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (147, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (148, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (149, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (150, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (151, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (152, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (153, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (168, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (169, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (170, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (171, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (172, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (173, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (174, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (175, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (176, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (177, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (190, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (191, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (192, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (193, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (194, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (195, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (196, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (197, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (198, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (199, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (212, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (213, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (214, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (215, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (216, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (217, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (218, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (219, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (220, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (221, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (234, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (235, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (236, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (237, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (238, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (239, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (240, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (241, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (242, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (243, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (256, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (257, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (258, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (259, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (260, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (261, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (262, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (263, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (264, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (265, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (278, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (279, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (280, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (281, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (282, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (283, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (284, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (285, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (286, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (287, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (300, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (301, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (302, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (303, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (304, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (305, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (306, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (307, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (308, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (309, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (322, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (323, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (324, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (325, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (326, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (327, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (328, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (329, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (330, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (331, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (344, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (345, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (346, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (347, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (348, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (349, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (350, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (351, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (352, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (353, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (366, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (367, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (368, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (369, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (370, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (371, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (372, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (373, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (374, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (375, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (388, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (389, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (390, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (391, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (392, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (393, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (394, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (395, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (396, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (397, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (410, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (411, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (412, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (413, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (414, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (415, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (416, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (417, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (418, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (419, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (432, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (433, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (434, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (435, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (436, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (437, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (438, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (439, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (440, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (441, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (454, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (455, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (456, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (457, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (458, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (459, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (460, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (461, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (462, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (463, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (476, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (477, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (478, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (479, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (480, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (481, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (482, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (483, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (484, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (485, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (498, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (499, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (500, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (501, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (502, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (503, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (504, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (505, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (506, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (507, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (520, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (521, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (522, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (523, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (524, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (525, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (526, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (527, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (528, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (529, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (542, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (543, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (544, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (545, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (546, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (547, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (548, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (549, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (550, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (551, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (564, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (565, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (566, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (567, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (568, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (569, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (570, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (571, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (572, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (573, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (586, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (587, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (588, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (589, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (590, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (591, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (592, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (593, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (594, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (595, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (608, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (609, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (610, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (611, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (612, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (613, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (614, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (615, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (616, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (617, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (630, 'Shampoo de Argán Orgánico', 'Shampoo restaurador con aceite de argán puro de Marruecos. Limpia, hidrata y aporta brillo natural al cabello seco o dañado.', 45000.00, 45000.00, 38250.00, 29250.00, 4500.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (631, 'Acondicionador de Coco Nutritivo', 'Acondicionador ultra-hidratante formulado con leche de coco orgánica. Desenreda, nutre y previene el frizz.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 40, 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (632, 'Mascarilla Reparadora de Queratina', 'Tratamiento intensivo de queratina para reestructurar la fibra capilar, reducir la horquilla y devolver la sedosidad.', 55000.00, 55000.00, 46750.00, 35750.00, 5500.00, 30, 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?q=80&w=300&auto=format&fit=crop', 'Cabello', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (633, 'Esmalte Semipermanente Glow Red', 'Esmalte de uñas en gel semipermanente de larga duración (hasta 21 días) en un tono rojo vibrante y de secado rápido bajo lámpara UV.', 18000.00, 18000.00, 15300.00, 11700.00, 1800.00, 100, 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (634, 'Aceite Hidratante para Cutículas', 'Aceite nutritivo a base de almendras dulces y vitamina E para fortalecer las uñas y suavizar las cutículas secas.', 12000.00, 12000.00, 10200.00, 7800.00, 1200.00, 60, 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=300&auto=format&fit=crop', 'Uñas', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (635, 'Paleta de Sombras Nude', 'Paleta profesional de 12 sombras altamente pigmentadas en tonos nude, tierra y metálicos para looks de día y de noche.', 75000.00, 75000.00, 63750.00, 48750.00, 7500.00, 25, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (636, 'Base de Maquillaje Matificante', 'Base de cobertura media-alta de larga duración con acabado mate aterciopelado. Controla el brillo e incluye FPS 15.', 62000.00, 62000.00, 52700.00, 40300.00, 6200.00, 35, 'https://images.unsplash.com/photo-1631730359575-38e4755d772b?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (637, 'Labial Líquido Mate Larga Duración', 'Labial líquido intransferible con acabado mate ultra cómodo. Mantiene los labios hidratados con color intenso por 16 horas.', 28000.00, 28000.00, 23800.00, 18200.00, 2800.00, 80, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (638, 'Cera Elástica de Miel (1kg)', 'Cera elástica profesional con extracto de miel orgánica. Ideal para depilación de zonas sensibles, alta elasticidad y bajo punto de fusión.', 45000.00, 0.00, 0.00, 45000.00, 0.00, 50, 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=300&auto=format&fit=crop', 'Estética', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (639, 'Kit Pestañas Premium (Melted)', 'Kit completo de pestañas pelo a pelo con adhesivo quirúrgico de secado rápido, removedor en gel y pinzas de precisión.', 90000.00, 0.00, 0.00, 90000.00, 0.00, 30, 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=300&auto=format&fit=crop', 'Maquillaje', 'INSUMO_PRESTADOR', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (646, 'Bálsamo Hidratante de Barba (Cedro & Sándalo)', 'Bálsamo acondicionador premium formulado con aceite de jojoba y manteca de karité. Nutre la barba, alivia la picazón de crecimiento y moldea con fijación natural.', 42000.00, 42000.00, 35700.00, 27300.00, 4200.00, 45, 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?q=80&w=400&auto=format&fit=crop', 'Barba & Bigote', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (647, 'Cera de Peinado Matte Pomade (Fijación Fuerte)', 'Cera a base de agua con acabado mate natural. Aporta volumen y textura a cortes tipo Crop, Pompadour o Fade sin dejar residuos grasos.', 39000.00, 39000.00, 33150.00, 25350.00, 3900.00, 60, 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=400&auto=format&fit=crop', 'Corte & Capilar', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (648, 'Aceite de Crecimiento & Brillo para Barba (50ml)', 'Serum concentrado de aceites botánicos orgánicos (Argán, Ricino y Almendras). Estimula el folículo piloso y ablanda el vello facial rígido.', 48000.00, 48000.00, 40800.00, 31200.00, 4800.00, 35, 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?q=80&w=400&auto=format&fit=crop', 'Barba & Bigote', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (649, 'Shampoo Anticaída & Estimulante Capilar Hombres', 'Fórmula vigorizante con cafeína, mentol y biotina. Fortalece el cuero cabelludo masculino, limpia en profundidad y previene la caída del cabello.', 52000.00, 52000.00, 44200.00, 33800.00, 5200.00, 50, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?q=80&w=400&auto=format&fit=crop', 'Corte & Capilar', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (650, 'Gel Limpiador Facial Detox Masculino (Carbón Activado)', 'Limpiador diario para hombres que elimina el exceso de grasa e impurezas de los poros sin resecar la piel. Ideal para el cuidado post-afeitado.', 46000.00, 46000.00, 39100.00, 29900.00, 4600.00, 40, 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=400&auto=format&fit=crop', 'Skincare Masculino', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;
INSERT INTO productos (id, nombre, descripcion, precio, precio_al_publico, precio_con_reserva, precio_prestador, comision_prestador, stock, imagen_url, tag_especialidad, tipo_visibilidad, tenant_id)
  VALUES (651, 'Loción Aftershave Hidratante Anti-Irritación', 'Bálsamo refrescante libre de alcohol con extracto de Aloe Vera y Caléndula. Calma instantáneamente la piel irritada por la navaja o cuchilla.', 38000.00, 38000.00, 32300.00, 24700.00, 3800.00, 55, 'https://images.unsplash.com/photo-1593702295094-aec22597af65?q=80&w=400&auto=format&fit=crop', 'Grooming', 'PUBLICO', 9)
  ON CONFLICT (id) DO NOTHING;

-- precios del nivel cliente: crear los que falten y corregir los que fueron alterados
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 1, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 2, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 3, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 4, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 5, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 6, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 7, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 8, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 9, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 10, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 23, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 24, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 25, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 26, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 27, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 28, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 29, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 30, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 31, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 32, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 45, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 46, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 47, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 48, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 49, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 50, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 51, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 52, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 53, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 54, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 67, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 68, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 69, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 70, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 71, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 72, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 73, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 74, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 75, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 76, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 89, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 90, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 91, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 92, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 93, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 94, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 95, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 96, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 97, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 98, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 111, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 112, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 113, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 114, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 115, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 116, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 117, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 118, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 119, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 120, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 144, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 145, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 146, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 147, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 148, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 149, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 150, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 151, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 152, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 153, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 168, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 169, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 170, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 171, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 172, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 173, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 174, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 175, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 176, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 177, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 190, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 191, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 192, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 193, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 194, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 195, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 196, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 197, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 198, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 199, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 212, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 213, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 214, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 215, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 216, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 217, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 218, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 219, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 220, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 221, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 234, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 235, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 236, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 237, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 238, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 239, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 240, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 241, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 242, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 243, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 256, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 257, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 258, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 259, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 260, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 261, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 262, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 263, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 264, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 265, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 278, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 279, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 280, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 281, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 282, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 283, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 284, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 285, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 286, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 287, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 300, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 301, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 302, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 303, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 304, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 305, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 306, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 307, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 308, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 309, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 322, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 323, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 324, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 325, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 326, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 327, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 328, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 329, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 330, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 331, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 344, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 345, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 346, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 347, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 348, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 349, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 350, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 351, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 352, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 353, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 366, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 367, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 368, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 369, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 370, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 371, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 372, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 373, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 374, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 375, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 388, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 389, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 390, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 391, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 392, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 393, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 394, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 395, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 396, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 397, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 410, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 411, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 412, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 413, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 414, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 415, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 416, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 417, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 418, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 419, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 432, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 433, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 434, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 435, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 436, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 437, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 438, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 439, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 440, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 441, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 454, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 455, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 456, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 457, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 458, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 459, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 460, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 461, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 462, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 463, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 476, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 477, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 478, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 479, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 480, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 481, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 482, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 483, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 484, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 485, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 498, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 499, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 500, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 501, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 502, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 503, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 504, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 505, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 506, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 507, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 520, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 521, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 522, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 523, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 524, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 525, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 526, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 527, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 528, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 529, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 542, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 543, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 544, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 545, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 546, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 547, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 548, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 549, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 550, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 551, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 564, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 565, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 566, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 567, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 568, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 569, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 570, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 571, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 572, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 573, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 586, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 587, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 588, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 589, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 590, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 591, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 592, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 593, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 594, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 595, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 608, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 609, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 610, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 611, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 612, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 613, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 614, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 615, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 616, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 617, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 630, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 631, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 632, 55000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 633, 18000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 634, 12000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 635, 75000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 636, 62000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 637, 28000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 638, 45000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 639, 90000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 646, 42000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 647, 39000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 648, 48000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 649, 52000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 650, 46000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
INSERT INTO precios_producto (lista_id, producto_id, precio, unidad_minima, tenant_id) VALUES (1, 651, 38000.00, 1, 9) ON CONFLICT (lista_id, producto_id) DO NOTHING;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 1 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 2 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 3 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 4 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 5 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 6 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 7 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 8 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 9 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 10 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 23 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 24 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 25 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 26 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 27 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 28 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 29 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 30 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 31 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 32 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 45 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 46 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 47 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 48 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 49 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 50 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 51 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 52 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 53 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 54 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 67 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 68 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 69 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 70 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 71 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 72 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 73 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 74 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 75 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 76 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 89 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 90 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 91 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 92 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 93 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 94 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 95 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 96 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 97 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 98 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 111 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 112 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 113 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 114 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 115 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 116 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 117 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 118 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 119 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 120 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 144 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 145 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 146 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 147 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 148 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 149 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 150 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 151 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 152 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 153 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 168 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 169 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 170 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 171 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 172 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 173 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 174 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 175 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 176 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 177 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 190 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 191 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 192 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 193 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 194 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 195 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 196 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 197 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 198 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 199 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 212 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 213 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 214 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 215 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 216 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 217 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 218 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 219 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 220 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 221 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 234 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 235 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 236 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 237 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 238 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 239 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 240 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 241 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 242 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 243 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 256 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 257 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 258 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 259 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 260 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 261 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 262 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 263 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 264 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 265 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 278 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 279 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 280 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 281 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 282 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 283 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 284 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 285 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 286 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 287 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 300 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 301 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 302 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 303 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 304 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 305 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 306 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 307 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 308 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 309 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 322 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 323 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 324 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 325 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 326 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 327 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 328 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 329 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 330 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 331 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 344 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 345 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 346 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 347 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 348 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 349 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 350 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 351 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 352 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 353 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 366 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 367 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 368 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 369 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 370 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 371 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 372 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 373 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 374 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 375 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 388 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 389 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 390 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 391 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 392 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 393 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 394 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 395 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 396 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 397 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 410 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 411 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 412 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 413 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 414 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 415 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 416 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 417 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 418 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 419 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 432 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 433 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 434 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 435 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 436 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 437 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 438 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 439 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 440 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 441 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 454 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 455 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 456 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 457 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 458 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 459 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 460 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 461 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 462 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 463 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 476 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 477 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 478 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 479 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 480 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 481 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 482 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 483 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 484 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 485 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 498 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 499 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 500 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 501 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 502 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 503 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 504 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 505 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 506 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 507 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 520 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 521 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 522 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 523 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 524 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 525 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 526 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 527 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 528 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 529 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 542 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 543 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 544 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 545 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 546 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 547 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 548 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 549 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 550 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 551 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 564 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 565 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 566 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 567 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 568 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 569 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 570 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 571 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 572 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 573 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 586 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 587 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 588 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 589 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 590 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 591 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 592 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 593 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 594 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 595 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 608 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 609 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 610 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 611 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 612 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 613 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 614 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 615 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 616 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 617 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 630 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 631 AND precio <> 38000.00;
UPDATE precios_producto SET precio = 55000.00 WHERE lista_id = 1 AND producto_id = 632 AND precio <> 55000.00;
UPDATE precios_producto SET precio = 18000.00 WHERE lista_id = 1 AND producto_id = 633 AND precio <> 18000.00;
UPDATE precios_producto SET precio = 12000.00 WHERE lista_id = 1 AND producto_id = 634 AND precio <> 12000.00;
UPDATE precios_producto SET precio = 75000.00 WHERE lista_id = 1 AND producto_id = 635 AND precio <> 75000.00;
UPDATE precios_producto SET precio = 62000.00 WHERE lista_id = 1 AND producto_id = 636 AND precio <> 62000.00;
UPDATE precios_producto SET precio = 28000.00 WHERE lista_id = 1 AND producto_id = 637 AND precio <> 28000.00;
UPDATE precios_producto SET precio = 45000.00 WHERE lista_id = 1 AND producto_id = 638 AND precio <> 45000.00;
UPDATE precios_producto SET precio = 90000.00 WHERE lista_id = 1 AND producto_id = 639 AND precio <> 90000.00;
UPDATE precios_producto SET precio = 42000.00 WHERE lista_id = 1 AND producto_id = 646 AND precio <> 42000.00;
UPDATE precios_producto SET precio = 39000.00 WHERE lista_id = 1 AND producto_id = 647 AND precio <> 39000.00;
UPDATE precios_producto SET precio = 48000.00 WHERE lista_id = 1 AND producto_id = 648 AND precio <> 48000.00;
UPDATE precios_producto SET precio = 52000.00 WHERE lista_id = 1 AND producto_id = 649 AND precio <> 52000.00;
UPDATE precios_producto SET precio = 46000.00 WHERE lista_id = 1 AND producto_id = 650 AND precio <> 46000.00;
UPDATE precios_producto SET precio = 38000.00 WHERE lista_id = 1 AND producto_id = 651 AND precio <> 38000.00;

SELECT setval('productos_id_seq', (SELECT max(id) FROM productos));

-- verificación dentro de la transacción
DO $$
DECLARE n_prod int; n_prec int; n_nombres int;
BEGIN
  SELECT count(*) INTO n_prod FROM productos;
  SELECT count(*) INTO n_prec FROM precios_producto WHERE lista_id = 1;
  SELECT count(DISTINCT nombre) INTO n_nombres FROM productos;
  RAISE NOTICE 'productos=% precios_cliente=% nombres_distintos=%', n_prod, n_prec, n_nombres;
  IF n_prod <> 296 THEN RAISE EXCEPTION 'se esperaban 296 productos, hay %', n_prod; END IF;
  IF n_prec <> 296 THEN RAISE EXCEPTION 'se esperaban 296 precios cliente, hay %', n_prec; END IF;
  IF n_nombres <> 16 THEN RAISE EXCEPTION 'se esperaban 16 nombres distintos, hay %', n_nombres; END IF;
END $$;
COMMIT;
