# GIA-18-M — EVIDENCE LEDGER

## Evidence Timestamps (UTC)

| # | Evidence | Timestamp | Result |
|---|----------|-----------|--------|
| E1 | Git baseline verified | 2026-09-02T21:29:03Z | HEAD=ef15b20e, branch=r7-stage3-shadow |
| E2 | Docker build backend | 2026-09-02T21:25:55Z | Image backend-backend:latest built |
| E3 | beauty-postgres running | 2026-09-02T21:28:23Z | Up (healthy), port 5435 |
| E4 | beauty-redis running | 2026-09-02T21:28:23Z | Up (healthy), port 6379 |
| E5 | beauty-backend running | 2026-09-02T21:28:23Z | Up, port 8080 |
| E6 | Backend health OK | 2026-09-02T21:31:46Z | {"status":"OK"} |
| E7 | PostgreSQL connected | 2026-09-02T21:31:46Z | {"status":"success"} |
| E8 | Redis PONG | 2026-09-02T21:26:16Z | PONG |
| E9 | Redis connected (backend) | 2026-09-02T21:31:38Z | Log: "Redis connected" |
| E10 | Frontend 200 on :3000 | 2026-09-02T21:28:42Z | Status 200, 4789 bytes |
| E11 | 55 PostgreSQL tables | 2026-09-02T21:26:11Z | \dt shows 55 tables |
| E12 | Unit tests 11/11 PASS | 2026-09-02T21:28:58Z | 2 suites, 11 tests, 0 failures |
| E13 | verifyToken fix applied | 2026-09-02T21:24:57Z | auth.js export updated |
| E14 | CORS fix applied | 2026-09-02T21:25:09Z | localhost:3000 added |
| E15 | REDIS_URL fix applied | 2026-09-02T21:31:12Z | docker-compose.yml updated |
| E16 | 61 migrations applied | 2026-09-02T21:31:38Z | Backend startup logs |
