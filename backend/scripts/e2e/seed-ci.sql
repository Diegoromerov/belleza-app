-- Semilla mínima para el arnés E2E en CI.
--
-- El arnés verifica reglas del dinero (split, propina, cancelación, envío, IVA).
-- Sin catálogo, esos bloques salen como OMITIDOS y un omitido no es una regla
-- verificada. Esta semilla no pretende parecerse al catálogo real: pone lo
-- mínimo para que cada umbral se pueda cruzar con stock de verdad.
--
--   90.000 x 4 = 360.000  cruza el umbral de Bogotá (300.000)
--   90.000 x 6 = 540.000  cruza el umbral nacional (480.000)
--   45.000                canasta por debajo del piso de envío gratis
--
-- Idempotente: borra los productos de prueba y los vuelve a crear.

INSERT INTO listas_precios (codigo, nombre, rol_destino, incluye_iva, estado)
VALUES ('cliente', 'Lista cliente', 'client', true, 'ACTIVA')
ON CONFLICT (codigo) DO UPDATE
   SET incluye_iva = true,
       estado      = 'ACTIVA';

DELETE FROM productos WHERE nombre LIKE 'E2E %';

INSERT INTO productos (nombre, descripcion, precio, stock, tipo_visibilidad, precio_al_publico, sku)
VALUES ('E2E Producto A', 'semilla del arnés', 90000, 40, 'PUBLICO', 90000, 'E2E-A'),
       ('E2E Producto B', 'semilla del arnés', 45000, 40, 'PUBLICO', 45000, 'E2E-B'),
       ('E2E Producto C', 'semilla del arnés', 120000, 20, 'PUBLICO', 120000, 'E2E-C');

INSERT INTO precios_producto (lista_id, producto_id, precio, vigente_desde)
SELECT l.id, p.id, p.precio_al_publico, NOW() - INTERVAL '1 day'
  FROM productos p
  CROSS JOIN listas_precios l
 WHERE p.nombre LIKE 'E2E %'
   AND l.codigo = 'cliente';

-- Comprobación: si la semilla no quedó, que falle aquí y no tres pasos después.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM precios_producto pr
    JOIN productos p ON p.id = pr.producto_id
   WHERE p.nombre LIKE 'E2E %';
  IF n < 3 THEN
    RAISE EXCEPTION 'semilla E2E incompleta: % precios', n;
  END IF;
END $$;
