# GIA-18-B — DOCKER ARCHITECTURE

## Container Topology

| Service | Image | Container | Host Port | Internal Port | Healthcheck |
|---------|-------|-----------|-----------|---------------|-------------|
| postgres | backend-postgres (pgvector:pg16) | beauty-postgres | 5435 | 5432 | pg_isready |
| redis | redis:7-alpine | beauty-redis | 6379 | 6379 | redis-cli ping |
| backend | backend-backend (node:20-alpine) | beauty-backend | 8080 | 8080 | — |

## Dockerfile (Backend)
- Base: node:20-alpine
- Steps: WORKDIR /app → COPY package*.json → npm install --only=production → COPY . .
- CMD: node index.js
- EXPOSE: 8080

## Environment Variables (Backend)
| Variable | Value |
|----------|-------|
| PORT | 8080 |
| DB_HOST | postgres |
| DB_PORT | 5432 |
| DB_NAME | beauty_db |
| DB_USER | admin |
| REDIS_URL | redis://redis:6379 |
| JWT_SECRET | beauty_app_super_secret_key_2026_change_in_production |
| NODE_ENV | development |
| SEED_DATABASE | true |

## Volumes
- `postgres_data` — Persistent PostgreSQL data
- `./uploads:/app/uploads` — Shared upload directory
