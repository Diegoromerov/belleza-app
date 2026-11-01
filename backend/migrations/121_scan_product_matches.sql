-- 121: Crear scan_product_matches sin arrastrar pgvector
--
-- Contexto: la migración 029 crea esta tabla, pero su primera línea es
-- `CREATE EXTENSION IF NOT EXISTS vector;` y la imagen de base de datos
-- (postgis/postgis:16-3.4) no incluye pgvector. Resultado: 029 aborta entera y
-- deja fuera una tabla que NO usa el tipo `vector` en ninguna columna.
--
-- 071_glowshop_niveles_a0 altera `scan_product_matches`, así que sin esta tabla
-- no se puede crear `listas_precios` ni, por tanto, correr el bloque G del
-- arnés E2E (`listas_precios` con codigo='cliente').
--
-- El DDL de abajo es exactamente el de 029 (líneas 25-36), sin la extensión
-- `vector`. `pgcrypto` sí se necesita: `gen_random_uuid()`.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS scan_product_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    match_score NUMERIC(5,4) NOT NULL,
    reasoning TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scan_product_matches_profile ON scan_product_matches(profile_id);
CREATE INDEX IF NOT EXISTS idx_scan_product_matches_product ON scan_product_matches(product_id);
