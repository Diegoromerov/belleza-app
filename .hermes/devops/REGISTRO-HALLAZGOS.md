# Registro Maestro de Hallazgos — GlowApp DevOps Audit

> **Fecha inicio:** 2026-10-05  
> **Repo:** `belleza-app` (main: 2,217 commits, all refs: 2,481)  
> **Protocolo:** 7 pasos (Detecta → VER → Diego → FIX → CI → Diego review → Merge + Capa 3 si alto riesgo)  
> **Toolkit:** MIT-only (Hermes nativo, LangGraph opcional, gitleaks, actionlint)

---

## Índice de hallazgos

| ID | Severidad | Área | Auditor | Estado | Veredicto VER | Decisión Diego | PR | Merge | Capa 3 |
|---|---|---|---|---|---|---|---|---|---|
| SEC-01 | P0 | Secretos/Historial | SEC | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-02 | P0 | CI/CD | SEC/CICD | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-03 | P0 | Secretos/Código | SEC | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-04 | P0 | Autenticación | SEC | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-05 | P0 | Pagos | SEC | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-06 | P0 | Datos/Fail-open | SEC | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-07 | P0 | RLS/Tenancy | SEC/DATA | Detectado | — | — | — | — | Sí (alto riesgo) |
| SEC-NEW-01 | P1 | Secretos/Noise | SEC | Detectado | — | — | — | — | No |
| SEC-NEW-02 | P2 | Secretos/Local | SEC | Detectado | — | — | — | — | No |
| CICD-01 | P0 | CI/CD | CICD | Detectado | — | — | — | — | Sí (alto riesgo) |
| CICD-02 | P0 | CI/CD | CICD | Detectado | — | — | — | — | No |
| CICD-03 | P1 | CI/CD | CICD | Detectado | — | — | — | — | No |
| CICD-04 | P2 | CI/CD | CICD | Detectado | — | — | — | — | No |
| CICD-05 | P1 | CI/CD | CICD | Detectado | — | — | — | — | No |
| CICD-06 | P2 | CI/CD | CICD | Detectado | — | — | — | — | No |
| CICD-07 | P2 | CI/CD | CICD | Detectado | — | — | — | — | No |
| INF-01 | P1 | Contenedores | CICD | Detectado | — | — | — | — | Sí (docker-compose) |
| INF-02 | P1 | Contenedores | CICD | Detectado | — | — | — | — | No |
| INF-03 | P1 | Contenedores | CICD | Detectado | — | — | — | — | No |
| INF-04 | P1 | Observabilidad | OBS | Detectado | — | — | — | — | No |
| INF-05 | P1 | Observabilidad | OBS | Detectado | — | — | — | — | No |
| DAT-01 | P1 | Datos/Backfill | DATA | Detectado | — | — | — | — | Sí (migraciones) |
| DAT-02 | P1 | Datos/Migraciones | DATA | Detectado | — | — | — | — | Sí (migraciones) |
| SUP-01 | P2 | Supply Chain | SUP | Detectado | — | — | — | — | No |
| SC-03 | P1 | Supply Chain | SUP | Detectado | — | — | — | — | No |
| SC-04 | P1 | Supply Chain | SUP | Detectado | — | — | — | — | No |
| HIG-01 | P1 | Higiene | SUP | Detectado | — | — | — | — | No |
| HIG-02 | P1 | Higiene | SUP | Detectado | — | — | — | — | No |
| HIG-03 | P2 | Higiene | SUP | Detectado | — | — | — | — | No |
| HIG-04 | P2 | Higiene | SUP | Detectado | — | — | — | — | No |
| FL-01 | P1 | Flutter Release | REL | Detectado | — | — | — | — | No |
| FL-02 | P1 | Flutter Release | REL | Detectado | — | — | — | — | No |
| FL-03 | P2 | Flutter Release | REL | Detectado | — | — | — | — | No |
| FL-04 | P2 | Flutter Release | REL | Detectado | — | — | — | — | No |
| FL-05 | P1 | Flutter Release | REL | Detectado | — | — | — | — | No |
| RES-01 | P2 | Resiliencia | OBS | Detectado | — | — | — | — | No |
| RES-02 | P2 | Resiliencia | OBS | Detectado | — | — | — | — | No |

---

## Detalle por hallazgo (formato HALLAZGO-<id>.json)

### SEC-01
```json
{
  "id": "SEC-01",
  "severity": "P0",
  "area": "Secretos/Historial",
  "file": "backend/.env.production",
  "line": "N/A (archivo completo en commit 1cc662fd)",
  "evidence_cmd": "git show 1cc662fd:backend/.env.production",
  "impact": "11 credenciales de producción en historial público: JWT_SECRET, ENCRYPTION_KEY (base64), DATABASE_URL Railway (caboose.proxy.rlwy.net:18931), GEMINI_API_KEY, YOCAM_API_KEY, OPENUV_API_KEY, REDIS_URL, ALLOWED_ORIGINS",
  "proposed_fix": "1. Rotar 7 secretos en proveedores 2. Purgar historial con BFG/git-filter-repo (eliminar .env.production y 3 scripts scratch/) 3. Verificar post-rotación con gitleaks sobre espejo --all",
  "effort_h": 4
}
```

### SEC-02
```json
{
  "id": "SEC-02",
  "severity": "P0",
  "area": "CI/CD",
  "file": ".github/workflows/rag-evaluation.yml",
  "line": "27, 98-128",
  "evidence_cmd": "grep -n 'RAILWAY_DATABASE_URL' .github/workflows/rag-evaluation.yml && sed -n '98,128p' .github/workflows/rag-evaluation.yml",
  "impact": "Workflow escribe en BD de producción en cada push a main (migraciones + ingest + eval contra RAILWAY_DATABASE_URL)",
  "proposed_fix": "Cambiar a service container PostgreSQL efímero (como ci.yml). Quitar secrets.RAILWAY_DATABASE_URL. Usar postgres://postgres:***@localhost:5432/glowtest",
  "effort_h": 2
}
```

### SEC-03
```json
{
  "id": "SEC-03",
  "severity": "P0",
  "area": "Secretos/Código",
  "file": "backend/src/config/jwt.js",
  "line": "36-39",
  "evidence_cmd": "cat backend/src/config/jwt.js | sed -n '36,39p'",
  "impact": "Fallback incondicional a DEFAULT_PROD_SECRET = 'glowapp_jwt_production_secure_secret_key_at_least_32_chars' literal en repo público → cualquiera forja token admin",
  "proposed_fix": "Exigir JWT_SECRET env var; fallar arranque si falta en prod; eliminar fallback literal",
  "effort_h": 1
}
```

### SEC-04
```json
{
  "id": "SEC-04",
  "severity": "P0",
  "area": "Autenticación",
  "file": "backend/src/services/websocketService.js",
  "line": "61, 80-84, 87-93, 95-107",
  "evidence_cmd": "cat backend/src/services/websocketService.js | sed -n '61p;80,107p'",
  "impact": "WS sin auth, registro por userId plano, join_booking_room sin validar pertenencia, location_update usa providerId del cliente → suplantación, fuga geo, manipulación ubicación",
  "proposed_fix": "Token obligatorio en handshake; derivar providerId del token; validar pertenencia a reserva",
  "effort_h": 3
}
```

### SEC-05
```json
{
  "id": "SEC-05",
  "severity": "P0",
  "area": "Pagos",
  "file": "backend/src/controllers/bookingController.js",
  "line": "462-470, 546-550",
  "evidence_cmd": "cat backend/src/controllers/bookingController.js | sed -n '462,470p;546,550p'",
  "impact": "payBooking simulador incondicional, marca paid sin verificación, referenceToken = 'wompi_sim_' → pérdida ingresos, contabilidad contaminada",
  "proposed_fix": "En prod: 501 PAYMENT_GATEWAY_NOT_INTEGRATED; integrar Wompi real; renombrar ref a simdev_*",
  "effort_h": 4
}
```

### SEC-06
```json
{
  "id": "SEC-06",
  "severity": "P0",
  "area": "Datos/Fail-open",
  "file": "backend/src/config/db.js",
  "line": "428-497",
  "evidence_cmd": "cat backend/src/config/db.js | sed -n '428,497p'",
  "impact": "isPgAvailable empieza false, handleMemoryQuery sirve 24 ramas con datos inventados, testConnection() retorna true en fallo → degradación silenciosa a datos ficticios",
  "proposed_fix": "Eliminar fallback en prod (ALLOW_MEMORY_FALLBACK prohibited); testConnection debe fallar y abortar arranque; reintento con backoff",
  "effort_h": 3
}
```

### SEC-07
```json
{
  "id": "SEC-07",
  "severity": "P0",
  "area": "RLS/Tenancy",
  "file": "backend/migrations/058_enable_rls_policies.sql",
  "line": "30, 61-63",
  "evidence_cmd": "cat backend/migrations/058_enable_rls_policies.sql | grep -A2 -B2 'ENABLE\\|FORCE\\|WITH CHECK'",
  "impact": "RLS inerte: ENABLE sin FORCE, sin WITH CHECK, tenantContext.js no montado → fuga cross-tenant (PII, biométricos, transacciones)",
  "proposed_fix": "1. ALTER TABLE ... FORCE ROW LEVEL SECURITY 2. Añadir WITH CHECK a políticas 3. Montar tenantContext.js en middleware real 4. Usar SET LOCAL app.tenant_id en misma conexión 5. Rol app sin BYPASSRLS",
  "effort_h": 4
}
```

### SEC-NEW-01
```json
{
  "id": "SEC-NEW-01",
  "severity": "P1",
  "area": "Secretos/Noise",
  "file": "Varios (test fixtures, docs, ejemplos)",
  "line": "N/A",
  "evidence_cmd": "gitleaks detect --source /c/Users/Compu\\ casa/belleza-mirror --report-format json | jq '.[] | select(.RuleID==\"generic-api-key\")'",
  "impact": "19 hallazgos gitleaks en repo público — todos test fixtures/docs/ejemplos (contrasena-invalida-123, consent-uuid-123, Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff, etc.). Ruido en escaneos, no riesgo real",
  "proposed_fix": "Documentar allowlist en .gitleaks.toml para fixtures conocidos; no bloquear CI por estos",
  "effort_h": 1
}
```

### SEC-NEW-02
```json
{
  "id": "SEC-NEW-02",
  "severity": "P2",
  "area": "Secretos/Local",
  "file": "backend/.env.backup",
  "line": "N/A",
  "evidence_cmd": "git ls-files backend/.env.backup && git log --all --oneline -- backend/.env.backup",
  "impact": "Archivo solo en working dir local (ignorado por .gitignore), no en repo público. Falsa alarma si se escanea local",
  "proposed_fix": "Añadir a .gitignore explícito; configurar CI para no escanear archivos ignorados",
  "effort_h": 0.5
}
```

### CICD-01 (alias SEC-02)
```json
{
  "id": "CICD-01",
  "severity": "P0",
  "area": "CI/CD",
  "file": ".github/workflows/rag-evaluation.yml",
  "line": "27, 98-128",
  "evidence_cmd": "grep -n 'RAILWAY_DATABASE_URL' .github/workflows/rag-evaluation.yml",
  "impact": "Ver SEC-02",
  "proposed_fix": "Ver SEC-02",
  "effort_h": 2
}
```

### CICD-02
```json
{
  "id": "CICD-02",
  "severity": "P0",
  "area": "CI/CD",
  "file": ".github/workflows/rag-evaluation.yml",
  "line": "32-34",
  "evidence_cmd": "cat .github/workflows/rag-evaluation.yml | sed -n '32,34p'",
  "impact": "Modelo embeddings EOL: nvidia/nv-embedqa-e5-v5 (comentario: EOL 2026-08-25, API 410 Gone). Job no genera embeddings hasta migrar a nemotron-3-embed-1b (2048 dims vs 1024)",
  "proposed_fix": "Migrar a nemotron-3-embed-1b; actualizar esquema pgvector (1024→2048 dims); re-ingesta corpus",
  "effort_h": 4
}
```

### CICD-03
```json
{
  "id": "CICD-03",
  "severity": "P1",
  "area": "CI/CD",
  "file": ".github/workflows/ci.yml",
  "line": "38",
  "evidence_cmd": "cat .github/workflows/ci.yml | sed -n '38p'",
  "impact": "JWT_SECRET: ci_secret_key_glowapp_2026_super_secure en texto plano en workflow. Aceptable SOLO si exclusivo del CI efímero (BD service container glowtest). Secreto no sale del runner",
  "proposed_fix": "Documentar explícitamente que es CI-only; renombrar a CI_JWT_SECRET_TEST",
  "effort_h": 0.5
}
```

### CICD-04
```json
{
  "id": "CICD-04",
  "severity": "P2",
  "area": "CI/CD",
  "file": ".github/workflows/ci.yml",
  "line": "46, 49",
  "evidence_cmd": "cat .github/workflows/ci.yml | sed -n '46p;49p'",
  "impact": "actions/checkout@v4 y actions/setup-node@v4 sin pinning por SHA (deberían ser @11bd71901bbe5b1630ceea73d27597364c9af683 etc.)",
  "proposed_fix": "Pinnear por SHA completo todas las actions",
  "effort_h": 0.5
}
```

### CICD-05
```json
{
  "id": "CICD-05",
  "severity": "P1",
  "area": "CI/CD",
  "file": ".github/workflows/ci.yml",
  "line": "1 (nombre) vs contenido",
  "evidence_cmd": "cat .github/workflows/ci.yml | head -5 && grep -n 'deploy' .github/workflows/ci.yml",
  "impact": "ci.yml se llama 'CI / CD Pipeline' pero solo hace CI. No hay workflow de deploy real",
  "proposed_fix": "Renombrar a 'CI Pipeline'; crear workflow deploy separado con gatillo manual + aprobaciones",
  "effort_h": 2
}
```

### CICD-06
```json
{
  "id": "CICD-06",
  "severity": "P2",
  "area": "CI/CD",
  "file": ".github/workflows/ci.yml",
  "line": "253-256",
  "evidence_cmd": "cat .github/workflows/ci.yml | sed -n '253,256p'",
  "impact": "Flakiness documentada: src/tests/ciRagEvaluation.test.js falla aleatoriamente por serialización circular de Error en jest-worker → suite desaparece del conteo (41 vs 42 passed)",
  "proposed_fix": "Corregir test: evitar lanzar Error objetos circulares; usar string o objeto plano",
  "effort_h": 1
}
```

### CICD-07
```json
{
  "id": "CICD-07",
  "severity": "P2",
  "area": "CI/CD",
  "file": ".github/workflows/rag-evaluation.yml",
  "line": "62",
  "evidence_cmd": "cat .github/workflows/rag-evaluation.yml | sed -n '62p' && cat backend/package.json | grep -A2 -B2 '\"scripts\"'",
  "impact": "npm run lint 2>/dev/null || echo 'No lint script configured' → puerta que no distingue 'no corrió' de 'limpio' (backend/package.json no tiene script lint)",
  "proposed_fix": "Añadir script lint a backend/package.json (eslint) o quitar puerta falsa",
  "effort_h": 0.5
}
```

### INF-01
```json
{
  "id": "INF-01",
  "severity": "P1",
  "area": "Contenedores",
  "file": "docker-compose.prod.yml",
  "line": "40",
  "evidence_cmd": "grep -n '5432:5432' docker-compose.prod.yml",
  "impact": "Puerto 5432 de Postgres publicado al host → acceso directo a BD desde fuera del compose. En producción (Railway) no aplica, pero en local/docker-host es vector de ataque",
  "proposed_fix": "Quitar mapeo 5432:5432; usar red interna Docker",
  "effort_h": 0.5
}
```

### INF-02
```json
{
  "id": "INF-02",
  "severity": "P1",
  "area": "Contenedores",
  "file": "backend/Dockerfile, backend/Dockerfile.prod, backend/Dockerfile.postgres, backend/Dockerfile.pgvector",
  "line": "N/A (archivo completo)",
  "evidence_cmd": "ls -la backend/.dockerignore 2>/dev/null || echo 'NO EXISTE' && cat backend/Dockerfile && cat backend/Dockerfile.prod",
  "impact": "Ningún Dockerfile tiene .dockerignore → copia .git, node_modules (local), tests, docs, .md → imagen inflada, superficie de ataque",
  "proposed_fix": "Crear .dockerignore (excluir .git, node_modules, tests, *.md, docs, .env*, *.log, coverage, .nyc_output)",
  "effort_h": 0.5
}
```

### INF-03
```json
{
  "id": "INF-03",
  "severity": "P1",
  "area": "Contenedores",
  "file": "backend/Dockerfile.postgres, backend/Dockerfile.pgvector",
  "line": "USER (ausente)",
  "evidence_cmd": "cat backend/Dockerfile.postgres && cat backend/Dockerfile.pgvector | grep -i user",
  "impact": "2 Dockerfiles Postgres corren como root (no USER postgres) — riesgo si escape de contenedor",
  "proposed_fix": "Añadir USER postgres / USER 999",
  "effort_h": 0.5
}
```

### INF-04
```json
{
  "id": "INF-04",
  "severity": "P1",
  "area": "Observabilidad/Health",
  "file": "backend/src/index.js",
  "line": "420-431",
  "evidence_cmd": "cat backend/src/index.js | sed -n '420,431p'",
  "impact": "/api/health hace setval en secuencia (write + lock) y miente 200 OK aunque BD caída → orquestador (K8s/EKS) toma decisiones erróneas",
  "proposed_fix": "Separar /healthz (proceso vivo, SELECT 1 sin write) y /ready (BD accesible). Proteger /status, /api-docs con auth",
  "effort_h": 1
}
```

### INF-05
```json
{
  "id": "INF-05",
  "severity": "P1",
  "area": "Observabilidad",
  "file": "backend/monitoring/",
  "line": "N/A",
  "evidence_cmd": "ls -la backend/monitoring/ && cat backend/monitoring/prometheus.yml && cat backend/monitoring/alerts.yml",
  "impact": "Config Prometheus + Alertmanager lista (6 reglas P0) pero NO hay evidencia de despliegue en producción (Railway no los provee nativamente)",
  "proposed_fix": "Desplegar Prometheus + Alertmanager (managed: Grafana Cloud, Datadog) o confirmar que Railway los provee",
  "effort_h": 4
}
```

### DAT-01
```json
{
  "id": "DAT-01",
  "severity": "P1",
  "area": "Datos/Backfill",
  "file": "backend/migrations/057_backfill_tenant_id.sql",
  "line": "35",
  "evidence_cmd": "cat backend/migrations/057_backfill_tenant_id.sql",
  "impact": "TODO histórico asignado a tenant 'demo' → multi-tenant nominal, datos mezclados (PII, biométricos, transacciones)",
  "proposed_fix": "Backfill por dueño real (owner_id, salon_id, etc.); verificar conteos antes de activar aislamiento RLS",
  "effort_h": 2
}
```

### DAT-02
```json
{
  "id": "DAT-02",
  "severity": "P1",
  "area": "Datos/Migraciones",
  "file": "backend/src/config/db.js, backend/knexfile.js",
  "line": "1623-1636 (index.js), knexfile.js",
  "evidence_cmd": "cat backend/src/config/db.js | sed -n '1623,1636p' && cat backend/knexfile.js",
  "impact": "2 runners migraciones (arranque + knex), sin tabla tracking unificada, 15 duplicados legacy congelados → esquema irreproducible, CI vs prod drift",
  "proposed_fix": "Un solo runner, tabla schema_migrations, migraciones inmutables, fallar en error (no warn)",
  "effort_h": 4
}
```

### SUP-01
```json
{
  "id": "SUP-01",
  "severity": "P2",
  "area": "Supply Chain/Deps",
  "file": "backend/package.json, frontend/pubspec.yaml, ai-worker/requirements.txt",
  "line": "N/A",
  "evidence_cmd": "cd backend && npm audit --json && cd ../frontend && flutter pub outdated && cd ../ai-worker && pip list --outdated",
  "impact": "Sin automatización de actualizaciones (Dependabot/Renovate) ni para npm ni para pub ni para pip → vulnerabilidades no detectadas",
  "proposed_fix": "1. .github/dependabot.yml (npm + GitHub Actions) 2. buddy-bot (MIT) para pub/pip/Dockerfiles 3. syft (MIT) para SBOM en CI 4. license-checker (MIT) para auditoría licencias",
  "effort_h": 2
}
```

### SC-03
```json
{
  "id": "SC-03",
  "severity": "P1",
  "area": "Supply Chain/Exposición",
  "file": "backend/package.json (express-status-monitor)",
  "line": "N/A",
  "evidence_cmd": "grep -r 'express-status-monitor' backend/src/ && cat backend/src/index.js | grep -A5 -B5 'status'",
  "impact": "express-status-monitor (v1.3.4) expone /status sin auth → fuga métricas internas",
  "proposed_fix": "Proteger /status con auth o deshabilitar en prod (NODE_ENV=production)",
  "effort_h": 0.5
}
```

### SC-04
```json
{
  "id": "SC-04",
  "severity": "P1",
  "area": "Supply Chain/Exposición",
  "file": "backend/package.json (swagger-ui-express)",
  "line": "N/A",
  "evidence_cmd": "grep -r 'swagger-ui-express\\|api-docs' backend/src/ && cat backend/src/index.js | grep -A5 -B5 'api-docs'",
  "impact": "swagger-ui-express expone /api-docs sin auth en producción → fuga especificación API",
  "proposed_fix": "Proteger /api-docs con auth o deshabilitar en prod",
  "effort_h": 0.5
}
```

### HIG-01
```json
{
  "id": "HIG-01",
  "severity": "P1",
  "area": "Higiene/Build versionado",
  "file": "backend/public/main.dart.js",
  "line": "N/A",
  "evidence_cmd": "ls -la backend/public/main.dart.js && file backend/public/main.dart.js",
  "impact": "Build Flutter Web (5.9MB, 189K líneas) versionado en backend. Dockerfile no compila Flutter → fixes frontend exigen rebuild manual + commit. Acopla frontend a backend",
  "proposed_fix": "Mover build a artifact de CI; backend/public/ en .gitignore; Dockerfile compila o descarga artifact",
  "effort_h": 2
}
```

### HIG-02
```json
{
  "id": "HIG-02",
  "severity": "P1",
  "area": "Higiene/Licencia",
  "file": "LICENSE (raíz)",
  "line": "N/A",
  "evidence_cmd": "ls -la LICENSE* 2>/dev/null || echo 'SIN LICENSE EN RAÍZ'",
  "impact": "Sin LICENSE en raíz → riesgo legal, adopción empresarial bloqueada",
  "proposed_fix": "Añadir licencia (MIT recomendado por mandato usuario)",
  "effort_h": 0.5
}
```

### HIG-03
```json
{
  "id": "HIG-03",
  "severity": "P2",
  "area": "Higiene/.gitignore",
  "file": ".gitignore",
  "line": "66-67",
  "evidence_cmd": "cat .gitignore | sed -n '66,67p'",
  "impact": "backend/public/ comentado en .gitignore con comentario 'A-04: backend/public versionado intencionalmente' — decisión consciente pero riesgosa",
  "proposed_fix": "Descomentar y mover build a CI artifact",
  "effort_h": 0.5
}
```

### HIG-04
```json
{
  "id": "HIG-04",
  "severity": "P2",
  "area": "Higiene/Backups versionados",
  "file": "backend/migrations/*.bak, *.backup",
  "line": "70-72 .gitignore",
  "evidence_cmd": "ls -la backend/migrations/*.bak backend/migrations/*.backup 2>/dev/null && cat .gitignore | sed -n '70,72p'",
  "impact": "3 archivos .bak/.backup versionados en backend/migrations/ (líneas 70-72 del .gitignore los ignoran pero ya están trackeados)",
  "proposed_fix": "git rm --cached backend/migrations/*.bak backend/migrations/*.backup; commit",
  "effort_h": 0.5
}
```

### FL-01
```json
{
  "id": "FL-01",
  "severity": "P1",
  "area": "Flutter Release",
  "file": ".github/workflows/ci.yml",
  "line": "N/A (falta job)",
  "evidence_cmd": "grep -n 'flutter build' .github/workflows/ci.yml || echo 'SIN BUILD'",
  "impact": "Sin pipeline de build automatizado para Android/iOS/web en CI → releases manuales",
  "proposed_fix": "GitHub Actions + subosito/flutter-action + keystore/key.properties via secrets + fastlane/flutter build",
  "effort_h": 6
}
```

### FL-02
```json
{
  "id": "FL-02",
  "severity": "P1",
  "area": "Flutter Release",
  "file": "frontend/android/key.properties.example",
  "line": "N/A",
  "evidence_cmd": "cat frontend/android/key.properties.example",
  "impact": "Sin firma automatizada (keystore + key.properties inyectados por secrets) → releases manuales, riesgo humano",
  "proposed_fix": "Keystore base64 en GitHub Secrets; key.properties generado en CI desde secrets",
  "effort_h": 2
}
```

### FL-03
```json
{
  "id": "FL-03",
  "severity": "P2",
  "area": "Flutter Release",
  "file": "frontend/pubspec.yaml",
  "line": "1",
  "evidence_cmd": "cat frontend/pubspec.yaml | grep version",
  "impact": "Versionado hardcodeado (1.0.0+1), sin automatización build number desde CI",
  "proposed_fix": "version: major.minor.patch+${{ github.run_number }} en workflow",
  "effort_h": 1
}
```

### FL-04
```json
{
  "id": "FL-04",
  "severity": "P2",
  "area": "Flutter Release",
  "file": "N/A (falta config)",
  "line": "N/A",
  "evidence_cmd": "ls -la fastlane/ codemagic.yml bitrise.yml .github/workflows/*release* 2>/dev/null || echo 'SIN CONFIG'",
  "impact": "Sin publicación automatizada a tiendas (internal testing, production)",
  "proposed_fix": "Fastlane para Play Store/App Store; GitHub Actions deploy job",
  "effort_h": 3
}
```

### FL-05
```json
{
  "id": "FL-05",
  "severity": "P1",
  "area": "Flutter Release",
  "file": "backend/public/main.dart.js",
  "line": "N/A",
  "evidence_cmd": "ls -la backend/public/main.dart.js",
  "impact": "Build web versionado en backend/public/ — acopla frontend a backend, rompe separación de concerns",
  "proposed_fix": "Ver HIG-01: mover a CI artifact",
  "effort_h": 0
}
```

### RES-01
```json
{
  "id": "RES-01",
  "severity": "P2",
  "area": "Resiliencia",
  "file": "backend/src/index.js, backend/package.json",
  "line": "266-272, package.json",
  "evidence_cmd": "cat backend/src/index.js | sed -n '266,272p' && grep -i 'opossum\\|circuit\\|retry' backend/package.json",
  "impact": "Sin circuit breaker (opossum), retry con backoff exponencial, bulkhead; rate limit global 1000/15min excesivo → cascada de fallos, DoS fácil",
  "proposed_fix": "Añadir opossum; rate limit por tenant/usuario; timeouts por cliente",
  "effort_h": 3
}
```

### RES-02
```json
{
  "id": "RES-02",
  "severity": "P2",
  "area": "Resiliencia/DR",
  "file": "railway.yml, backend/scripts/",
  "line": "N/A",
  "evidence_cmd": "cat railway.yml | grep -i restart && ls -la backend/scripts/backup*.js backend/scripts/restore*.js 2>/dev/null && echo 'RUNBOOKS:' && find . -name '*runbook*' -o -name '*dr*' -o -name '*disaster*' 2>/dev/null",
  "impact": "Sin plan DR documentado (RPO/RTO, runbooks, failover, backup restore tested). railway.yml: restartPolicyType: ON_FAILURE sin multi-AZ/region. PostgreSQL Railway managed sin evidencia PITR",
  "proposed_fix": "Documentar RPO/RTO (ej. RPO=1h, RTO=4h); probar restore railway_seed.sql; runbooks por escenario (BD caída, región caída, ransomware, fuga datos)",
  "effort_h": 4
}
```

---

## Dashboard estado (ESTADO-SISTEMA.md)

```
AUDITORÍAS ACTIVAS: 0
HALLAZGOS ABIERTOS: 36 (7 P0, 6 P1, 4 P2 confirmados Fase 1 + 2 nuevos + 17 adicionales)
PRs PENDIENTES: 0
TOKENS USADOS HOY: 0
PRÓXIMA ACCIÓN: Ejecutar SEC sobre espejo --all (2,481 refs)
```

---

**Fin del registro. Actualizado por ORQ tras cada paso del protocolo.**