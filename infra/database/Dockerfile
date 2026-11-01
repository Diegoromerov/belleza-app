# Imagen de base de datos de GlowApp — PostgreSQL 16 + PostGIS + pgvector
#
# POR QUÉ EXISTE
# El esquema necesita TRES cosas que ninguna imagen oficial trae juntas:
#   · PostGIS   → `perfiles_prestador.ubicacion` es geography(POINT,4326) y
#                 /api/providers/nearby hace consultas espaciales.
#   · pgvector  → `beauty_knowledge_embeddings.embedding vector(2048)`, el RAG
#                 del chat de Aura (migraciones 031 y migrations/rag/*).
#   · PG 16     → versión mayor de los volúmenes actuales.
#
# POR QUÉ ESTA BASE Y NO OTRA (probado, no supuesto)
# 1) `postgis/postgis:16-3.4` → Debian bullseye. PGDG ya no publica `bullseye-pgdg`:
#        E: The repository '... bullseye-pgdg Release' does not have a Release file.
# 2) `postgres:16-bookworm` + postgis → funciona, pero el paquete
#    `postgresql-16-postgis-3` NO incluye `postgis_tiger_geocoder`, que el esquema
#    de producción sí tiene (falla al restaurar: control file not found).
# 3) `postgis/postgis:16-3.6` → Debian **trixie**, repo `trixie-pgdg` vigente,
#    incluye postgis, postgis_topology y postgis_tiger_geocoder, y su PGDG
#    ofrece `postgresql-16-pgvector` (0.8.7-1.pgdg13+1).
#
# Esa es la base: se hereda TODO PostGIS de la imagen oficial y se añade SOLO
# el paquete de pgvector del mismo repositorio. Nada de imágenes de terceros.

FROM postgis/postgis:16-3.6

RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*

# Compuerta de build: si el paquete no deja la extensión disponible, el build
# falla aquí y no en producción a las 3 de la mañana.
RUN test -f /usr/share/postgresql/16/extension/postgis.control \
 && test -f /usr/share/postgresql/16/extension/postgis_topology.control \
 && test -f /usr/share/postgresql/16/extension/postgis_tiger_geocoder.control \
 && test -f /usr/share/postgresql/16/extension/vector.control

# Comprobación explícita de versiones en el log de build.
RUN postgres --version \
 && ls /usr/share/postgresql/16/extension/ | grep -E '^(postgis|postgis_topology|postgis_tiger_geocoder|vector)\.control$'
