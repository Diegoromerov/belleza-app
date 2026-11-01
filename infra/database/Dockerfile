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
# POR QUÉ PARTIMOS DE `postgres:16-bookworm` Y NO DE `postgis/postgis`
# El tag `postgis/postgis:16-3.4` está construido sobre Debian **bullseye**, y
# PGDG ya no publica `bullseye-pgdg`:
#     E: The repository 'http://apt.postgresql.org/pub/repos/apt bullseye-pgdg
#        Release' does not have a Release file.
# La imagen oficial `postgres:16-bookworm` ya trae el repositorio PGDG de
# bookworm (vigente) y de ahí se instalan los dos paquetes. Mismo PostgreSQL 16,
# misma familia de paquetes, base soportada.
#
# Alternativa descartada: `pgvector/pgvector:pg16` + instalar PostGIS encima.
# Funciona igual, pero así PostGIS —lo más crítico del esquema— queda como
# paquete de primera clase y no como añadido.
#
# No se usan imágenes de terceros: procedencia dudosa y sin garantía de versión.

FROM postgres:16-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-16-postgis-3 \
      postgresql-16-postgis-3-scripts \
      postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*

# Compuerta de build: si el paquete no deja la extensión disponible, el build
# falla aquí y no en producción a las 3 de la mañana.
RUN test -f /usr/share/postgresql/16/extension/postgis.control \
 && test -f /usr/share/postgresql/16/extension/postgis_topology.control \
 && test -f /usr/share/postgresql/16/extension/vector.control

# Comprobación explícita de ambas versiones en el log de build.
RUN postgres --version \
 && ls /usr/share/postgresql/16/extension/ | grep -E '^(postgis|postgis_topology|vector)\.control$'
