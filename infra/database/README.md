# Base de datos con PostGIS + pgvector — procedimiento de cambio

Imagen objetivo: `postgis/postgis:16-3.4` + `postgresql-16-pgvector` (ver `Dockerfile`).

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
- Bloqueo para ejecutar este procedimiento: hace falta un registry donde publicar la imagen
  (o un runner con Docker). Sin eso no hay imagen que desplegar.
