# GIA-18-F — POSTGRESQL & REDIS VERIFICATION

## PostgreSQL
- Image: pgvector/pgvector:pg16 (custom Dockerfile.postgres)
- Container: beauty-postgres
- Host port: 5435 → Internal 5432
- Database: beauty_db / User: admin
- Healthcheck: pg_isready → Healthy
- Tables: 55 verified (glow_cycles, glow_cycle_measurements, usuarios, face_scores, etc.)
- Migrations: 61 applied automatically
- Volume: postgres_data (persistent)

## Redis
- Image: redis:7-alpine
- Container: beauty-redis
- Host port: 6379 → Internal 6379
- Healthcheck: redis-cli ping → PONG / Healthy
- Backend log: "Redis connected"
- Usage: Token blacklisting, biometric cache, session state

## Fix Applied
Added REDIS_URL=redis://redis:6379 to docker-compose.yml backend environment.
The Redis client config uses REDIS_URL, not REDIS_HOST/REDIS_PORT.
