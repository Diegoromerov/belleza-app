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
# `postgis/postgis:16-3.4` trae PostGIS y contrib, pero NO pgvector.
# `pgvector/pgvector:pg16` trae pgvector, pero NO PostGIS (y sin PostGIS la base
# ni siquiera arranca con el esquema actual: `could not access file "$libdir/postgis-3"`).
#
# Por eso: partir de la imagen oficial de PostGIS y añadir SOLO el paquete
# de pgvector desde el mismo repositorio PGDG del que ya depende la imagen.
# No se usan imágenes de terceros: son de procedencia dudosa y sin garantía de
# versión de PostGIS/pgvector.

FROM postgis/postgis:16-3.4

RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*

# Compuerta de build: si el paquete no deja la extensión disponible, el build
# falla aquí y no en producción a las 3 de la mañana.
RUN test -f /usr/share/postgresql/16/extension/vector.control \
 && test -f /usr/share/postgresql/16/extension/postgis.control

# Comprobación explícita de ambas versiones en el log de build.
RUN postgres --version && ls /usr/share/postgresql/16/extension/ | grep -E '^(postgis|vector)\.control$'
