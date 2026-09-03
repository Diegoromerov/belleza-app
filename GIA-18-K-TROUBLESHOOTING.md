# GIA-18-K — TROUBLESHOOTING

## Issues Encountered and Resolved

### Issue 1: Backend crash — verifyToken undefined
Error: Route.post() requires a callback function but got a [object Undefined] at glowCycleRoutes.js:12
Root Cause: auth.js exported authMiddleware/adminMiddleware but not verifyToken
Fix: Added verifyToken: authMiddleware to module.exports in auth.js
File: backend/src/middleware/auth.js

### Issue 2: Redis connection failures in backend container
Error: Repeated "Redis Client Error" in backend logs
Root Cause: redis.js uses REDIS_URL env var, falls back to redis://localhost:6379. Inside Docker, localhost doesn't reach redis container.
Fix: Added REDIS_URL=redis://redis:6379 to docker-compose.yml backend environment
File: backend/docker-compose.yml

### Issue 3: CORS blocking frontend on port 3000
Root Cause: defaultOrigins in index.js did not include http://localhost:3000
Fix: Added http://localhost:3000 and http://127.0.0.1:3000 to defaultOrigins
File: backend/index.js

### Non-Critical Warnings (Not Fixed — Outside Frozen Core)
- Missing workers: nailTryonWorker, pqrsfReviewWorker, vtoAttributionWorker
- Missing tables: wallet_transactions, perfiles_prestador, reviews
- npm EBADENGINE warnings (Babel 8.x/Node 22 vs container Node 20)
- 22 npm audit vulnerabilities (development dependencies)
