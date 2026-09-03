# GIA-18-J — PORT MATRIX

## Port Allocation

| Port | Service | Protocol | Binding | Container/Process |
|------|---------|----------|---------|-------------------|
| 3000 | Frontend (Flutter Web) | HTTP | Host only | python http.server |
| 5435 | PostgreSQL | TCP | 0.0.0.0 | beauty-postgres |
| 6379 | Redis | TCP | 0.0.0.0 | beauty-redis |
| 8080 | Backend API | HTTP | 0.0.0.0 | beauty-backend |

## Internal Docker Network Ports

| Service | Internal Port | Accessed By |
|---------|---------------|-------------|
| postgres | 5432 | backend (DB_HOST=postgres) |
| redis | 6379 | backend (REDIS_URL=redis://redis:6379) |

## Access URLs

| URL | Purpose |
|-----|---------|
| http://localhost:3000 | Frontend Flutter Web App |
| http://localhost:8080/api/health | Backend health check |
| http://localhost:8080/api/test-db | Database connectivity test |
| http://localhost:8080/api/glow-cycle/* | Glow Cycle API |
