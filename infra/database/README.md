# Base de datos con PostGIS + pgvector — procedimiento de cambio

Imagen objetivo: `postgres:16-bookworm` + `postgresql-16-postgis-3` + `postgresql-16-pgvector`
(ver `Dockerfile`). **Construida y verificada localmente el 2026-11-01**: PostGIS **3.7.0** +
pgvector **0.8.7**, con una fila `geography(POINT,4326)` + `vector(2048)` insertada en la misma tabla.

> Nota sobre la base: se intentó primero `postgis/postgis:16-3.4`, pero está construida sobre
> Debian **bullseye** y PGDG ya no publica ese repo
> (`bullseye-pgdg Release does not have a Release file`). Por eso se parte de
> `postgres:16-bookworm`, que ya trae el repo PGDG vigente. Efecto colateral: PostGIS sube de
> **3.4.3** (lo que usan hoy staging y producción) a **3.7.0**. Es compatible al restaurar
> (`pg_dump` no serializa el interior de PostGIS; el `CREATE EXTENSION` crea la versión nueva),
> pero conviene saberlo antes de cambiar.

## Por qué no basta cambiar la imagen

El 2026-11-01 staging se cayó por hacer exactamente eso. Secuencia real del incidente:

1. Se cambió la imagen a `pgvector/pgvector:pg16` → el servicio arrancó **sin el volumen**, con base vacía (0 tablas).
2. Al volver a `postgis/postgis:16-3.4`, el contenedor abortaba:
   `initdb: error: directory "/var/lib/postgresql/data" exists but is not empty`.
3. El volumen que parecía rescatable era un clúster de **PostgreSQL 18** (parámetro
   `autovacuum_worker_slots`), incompatible con PG16.
4. La raíz del montaje tiene `lost+found`, así que `initdb` no puede usarla directamente.

Lección: **cambiar la imagen de un servicio con volumen nunca es "solo cambiar la imagen"**.

## Procedimiento seguro

### 1. Construir y publicar la imagen
```bash
docker build -t <registry>/glowapp-db:pg16-postgis-pgvector infra/database/
docker push <registry>/glowapp-db:pg16-postgis-pgvector
```
El Dockerfile tiene compuertas: si falta `postgis.control` o `vector.control`, el build falla.

### 2. Probar en un servicio desechable (nunca en el real primero)
- Nuevo servicio en Railway con la imagen publicada.
- Volumen **nuevo** (no reutilizar los existentes).
- Variable `PGDATA=/var/lib/postgresql/data/pgdata` (obligatoria: `lost+found`).
- Verificar:
```bash
railway ssh -s <servicio-prueba> "psql -U postgres -d railway -At \
  -c \"select extname from pg_extension order by 1\" \
  -c \"select extversion from pg_extension where extname='postgis'\""
```

### 3. Migrar el servicio real
1. Respaldo primero: `pg_dump` completo (esquema + datos) y guardarlo fuera del contenedor.
2. Cambiar la imagen del servicio.
3. Volumen: si el existente fue creado por PG18, **no sirve**. Crear volumen nuevo y
   restaurar el respaldo.
4. `PGDATA=/var/lib/postgresql/data/pgdata`.
5. Redesplegar y verificar que arranca.

### 4. Aplicar el esquema del RAG
```bash
# 031 crea beauty_knowledge_embeddings con embedding vector(768)
railway ssh -s <db> "cat > /tmp/m.sql" < backend/migrations/031_aura_pgvector_and_knowledge_table.sql
railway ssh -s <db> "psql -U postgres -d railway -1 -v ON_ERROR_STOP=1 -f /tmp/m.sql"

# rag/* tiene runner propio con ledger y checksums
railway ssh -s glowapp-api "cd /app && RAG_DATABASE_URL=\"\$DATABASE_URL\" node scripts/runRagMigrations.js"
```

### 5. Verificación
| Qué | Consulta | Esperado |
|---|---|---|
| pgvector activo | `select extversion from pg_extension where extname='vector'` | versión visible |
| Dimensión | `select format_type(atttypid, atttypmod) from pg_attribute where attrelid='beauty_knowledge_embeddings'::regclass and attname='embedding'` | `vector(2048)` |
| Índice HNSW | `select indexname from pg_indexes where tablename='beauty_knowledge_embeddings'` | índice `hnsw` presente |
| PostGIS intacto | `select extversion from pg_extension where extname='postgis'` | `3.4.3` |
| Regresión | E2E del backend | **25/25** |

## Estado actual

- **Producción y staging** siguen en `postgis/postgis:16-3.4`: tienen PostGIS, **no** tienen pgvector.
- `beauty_knowledge_embeddings` **no existe en ningún entorno** → el RAG de Aura está inactivo.
- **La imagen ya está construida y verificada en local** (`glowapp-db:pg16-postgis-pgvector`, 949 MB).
  Falta **publicarla en un registry** para que Railway pueda consumirla: sin credenciales de
  Docker Hub (u otro registry) o un job de CI que la construya y publique, no hay forma de
  desplegarla.

### Comandos exactos para publicar y probar

```bash
# 1. Etiquetar y publicar (requiere haber hecho docker login)
docker tag glowapp-db:pg16-postgis-pgvector <registry>/glowapp-db:pg16-postgis-pgvector
docker push <registry>/glowapp-db:pg16-postgis-pgvector

# 2. Servicio desechable en Railway con esa imagen y volumen NUEVO
railway add -i <registry>/glowapp-db:pg16-postgis-pgvector -s prueba-pgvector \
  -v POSTGRES_USER=postgres -v POSTGRES_PASSWORD=<aleatoria> -v POSTGRES_DB=railway
railway variables set PGDATA=/var/lib/postgresql/data/pgdata   # obligatorio: lost+found

# 3. Verificar extensiones
railway ssh -s prueba-pgvector "psql -U postgres -d railway -At -c \
  \"select extname||'='||extversion from pg_extension where extname in ('postgis','vector')\""
```

## Verificación end-to-end en local (2026-11-01) ✅

Sobre la imagen construida (`glowapp-db:pg16-postgis-pgvector`), con PostgreSQL 16 y el
contenedor arrancado en limpio:

| Paso | Resultado |
|---|---|
| Restore del esquema de producción (`prod_schema_20261101.sql`) | ✅ 122 tablas, 49 políticas |
| Extensiones tras el restore | `btree_gist, fuzzystrmatch, pgcrypto, plpgsql, postgis, postgis_tiger_geocoder, postgis_topology` — idénticas a producción |
| `030_enable_pgvector.sql` | ✅ `pgvector version: 0.8.7` |
| `031_aura_pgvector_and_knowledge_table.sql` | ✅ crea `beauty_knowledge_embeddings` |
| `scripts/runRagMigrations.js` | ✅ **8/8** migraciones: 035, 046, 048, 054, 076, 113, 114, 115 · ledger `schema_migrations` con 8 filas |
| Tipo de la columna | **`halfvec(2048)`** — ojo: no es `vector(2048)`; 035/076 usan `halfvec` para la mitad de memoria |
| Índice vectorial | ✅ `idx_beauty_knowledge_embedding_hnsw` (HNSW) |
| Columnas del RAG | 23, incluidas `tenant_id`, `search_vector`, `chunk_id`, `content_hash`, `fuente`, `seccion` |

Notas de operación aprendidas en la prueba:
- El entrypoint de la imagen PostGIS **carga extensiones al arrancar**; si se restaura el
  esquema mientras termina, choca (`duplicate key value violates unique constraint
  "pg_extension_name_index"` en `postgis`) y el contenedor sale con código 3. Hay que esperar
  `pg_isready` + unos segundos antes de restaurar.
- Con el esquema de producción restaurado, `031` necesita `tenants` y el resto del esquema:
  el orden correcto es **restore → 030 → 031 → rag/***.

## Ejecutado en staging (2026-11-01) ✅ — sin registry

**`railway up` puede construir el Dockerfile del lado de Railway**, así que no hace falta
publicar la imagen en ningún registry:

```bash
railway environment staging && railway service <svc>
railway up infra/database --path-as-root -s <svc> -c
```

Resultado real en `postgres-postgis` (staging):

| Paso | Resultado |
|---|---|
| Deploy de la imagen nueva sobre el volumen existente | ✅ las **126 tablas se conservaron** (no hizo falta volumen nuevo) |
| `ALTER EXTENSION postgis UPDATE TO '3.6.4'` (+ topology, tiger) | ✅ de 3.4.3 a **3.6.4** |
| Aviso de collation | ⚠️ `database "railway" has a collation version mismatch` (glibc **2.31 → 2.41**) |
| Corrección | `ALTER DATABASE railway REFRESH COLLATION VERSION` + `REINDEX DATABASE railway` |
| `030` → `031` → `runRagMigrations.js` | ✅ pgvector **0.8.7**, `beauty_knowledge_embeddings`, **8/8** migraciones RAG |
| Esquema final | `embedding = halfvec(2048)`, índice `idx_beauty_knowledge_embedding_hnsw`, **129 tablas**, **8 extensiones** |
| Regresión | E2E del backend **25/25** ✅ |

### Lección que corrige la hipótesis anterior

El incidente del 2026-11-01 **no** fue causado por reutilizar el volumen, sino por dos cosas
distintas: (a) el volumen que se intentó montar era un clúster de **PostgreSQL 18**, y (b) la raíz
del montaje tiene `lost+found`, así que `PGDATA` debe apuntar a `pgdata/`.

Con la imagen correcta y `PGDATA=/var/lib/postgresql/data/pgdata`, **reutilizar el volumen
funciona** y conserva los datos. Solo hay que refrescar la collation y reindexar cuando cambia la
base de Debian (bookworm → trixie).

### Lo que falta para producción

Producción sigue en `postgis/postgis:16-3.4` (122 tablas, sin pgvector). El mismo procedimiento
aplica, pero producción **no** es territorio de pruebas: requiere autorización explícita y una
ventana, porque el paso de `REINDEX DATABASE` bloquea escrituras.
