# GLOWAPP — BASELINE DE DESARROLLO
**Fecha:** 2026-11-01 · **Propósito:** documento único de contexto para continuar el trabajo en otra sesión
**Repo:** `Diegoromerov/belleza-app` · **Rama de trabajo:** `staging` @ `9a624b06` · `main` @ `4099472a`

---

## 0. Cómo usar este documento

Si abres este baseline en un chat nuevo, esto es lo que necesitas saber antes de tocar nada:

- Hay **tres mundos** y confundirlos es el error más caro: el código en GitHub, la **base real** en Railway (`grateful-harmony`) y el **runtime nuevo** (Firebase + Railway `glowapp`).
- El entorno `glowapp` **no es** la base real: es un esquema reconstruido y casi vacío.
- La fuente de verdad del **esquema** es `grateful-harmony` (151 tablas), no `glowapp` (122/129).
- Nada de `grateful-harmony` se modifica sin autorización explícita. Es solo lectura.

---

## 1. Qué es GlowApp hoy

Aplicación de belleza (usuarios + prestadores/salones) que creció como **monolito Flutter** y se está **dividiendo en dos apps**:

| Lado | App | Audiencia | Backend |
|---|---|---|---|
| Usuarios | `apps/glow_client` | `client` | API única con JWT `roles[]` + `audience` + header `X-App-Audience` |
| Prestadores / salón | `apps/glow_provider` | `provider` / `salon` | ídem |
| Admin | `admin-dashboard` (Next.js) | `admin` | ídem |

**Monorepo:** `packages/glow_core` (compartido) + `apps/glow_client` + `apps/glow_provider` + `admin-dashboard` + `backend` (Node/Express + PostgreSQL).

**Código Dart:** `glow_core` 209 · `glow_client` 54 · `glow_provider` 68 = **331 archivos**. El monolito original quedó archivado en `frontend-archive/` (201 `.dart`).

---

## 2. Los tres mundos

### 2.1 GitHub — el código
- Monolito archivado (`frontend-archive/`, 309 MB, fuera del repo por `.gitignore` pero presente en disco).
- Split actual en `packages/` + `apps/` + `admin-dashboard/` + `backend/`.
- CI: `.github/workflows/glowapp-firebase-deploy.yml` (workflow `402270471`) — jobs: `Monorepo Setup & Analyze`, `Backend Tests & Lint`, `Deploy Backend to Railway`, `Deploy Client/Provider to Firebase Hosting`.

### 2.2 `grateful-harmony` (Railway) — **LA BASE REAL**
- Proyecto Railway `grateful-harmony`, entorno `production`.
- Postgres `postgis/postgis:16-3.4`, volumen `postgis-volume` **313 MB**, **151 tablas**, 11 extensiones (`vector` incluida).
- Migraciones: `knex_migrations` con **192** entradas.
- **Datos reales (244.161 filas en las 50 tablas mayores):**

| Tabla | Filas |
|---|---|
| `analytics_events` | 188.775 |
| `curated_collections` | 18.551 |
| `user_activity_logs` | 15.274 |
| `productos` | 10.187 |
| `precios_producto` | 10.185 |
| `messages` | 341 |
| `bookings` | 58 |
| `usuarios` / `users` | 44 |
| `transactions` | 40 |

- Otros servicios del proyecto: `admin-dashboard` (Next.js, 22 páginas), `belleza-app`, `Belleza graficos`, `chic-grace`, `Redis`.
- **RAG:** `beauty_knowledge_embeddings` 6 filas (`embedding` tipo `real[]`), `rag_entities` 8, `rag_relations` 2, `rag_feedback_signals` 0, `rag_query_logs` **156** (el RAG sí corrió).

### 2.3 `glowapp` (Railway) + Firebase — el runtime nuevo
- Proyecto Railway `glowapp` (`a6f51ac4-aac5-4cd6-915e-f87e9da05f2a`).
- Servicios: `glowapp-api`, `postgres-postgis` (staging), `postgres-postgis-prod` (producción), `Redis`. Los `Postgres` legacy están **Offline**.
- Firebase:
  - **Client** → proyecto `glowapp-client` (nº 634593218804) · https://glowapp-client.web.app
  - **Provider** → proyecto `glowapp-provider` (nº 509840252897) · https://glowapp-provider.web.app
  - Staging (preview channels): `glowapp-client--staging-dxkv99y1.web.app` · `glowapp-provider--staging-srdlyu0q.web.app`
  - Storage de vídeos: `glowapp-client.firebasestorage.app` / `glowapp-provider.firebasestorage.app`
  - FCM activo (`firebase_messaging`). **Firestore y Firebase Auth son vestigiales**: `glow_core` solo declara `firebase_core` + `firebase_messaging`.
- `app.glowapp.com` **no resuelve**: dominio no comprado, custom domains pendientes.

---

## 3. Estado verificado (2026-11-01)

### Backend en `glowapp`

| Métrica | Staging | Producción |
|---|---|---|
| `/api/health` | 200 (`pgAvailable: true`) | 200 |
| `/api/providers` (`X-App-Audience: client`) | 200 | 200 |
| Tablas | **129** | **122** |
| Extensiones | 8 (incl. `postgis`, `vector`) | 7 (sin `vector`) |
| RLS con FORCE + política | 37/37 | 37/37 |
| E2E (`npm run e2e`) | **25/25 · 0 fallan** | no ejecutado |
| Imagen Postgres | `postgis 3.6.4` + `pgvector 0.8.7` | `postgis 3.4.3` (sin pgvector) |

### CI
- `Monorepo Setup & Analyze` → **success**
- `Backend Tests & Lint` → **success** (30/30 contrato, 1437 tests)
- `Glow Client - Test & Build` y `Glow Provider - Test & Build` → **failure** (preexistente, fuera de alcance)

---

## 4. Trabajo ejecutado el 2026-11-01

### 4.1 Cadena de fallos del backend (resuelta)
| # | Causa | Fix |
|---|---|---|
| 1 | `.railwayignore` excluía `*.sql` → imagen sin `migrations/` ni `init.sql` | Exclusión eliminada |
| 2 | SQL embebido como constantes JS; `058` evaluaba a `NaN` | `prepareRlsDatabase.js` lee migraciones desde disco |
| 3 | Imagen Postgres de Railway sin PostGIS | Servicios con `postgis/postgis:16-3.4` |
| 4 | `068` forzaba RLS sobre lista fija; 4 tablas sin política → crash loop | Migración `120` genérica y type-aware |
| 5 | `frontend-archive/` (309 MB) provocaba timeout en `railway up` | Excluido en `.railwayignore` |

PRs fusionados: **#91** y **#93**.

### 4.2 CI en verde
- `intl` alineado a `^0.19.0` (lo que fija Flutter 3.29.2).
- Postgres del job publicado como `ports: ["5432:5432"]` (antes `[5432,5432]` → puerto aleatorio).
- `RAILWAY_PROJECT_ID` movido del `env` global al job de deploy (se filtraba a los tests).
- `NODE_ENV=test` ya no se considera entorno estricto.
- `X-App-Audience` exento en `/api/health` y `/api/metrics` (una sonda no tiene identidad de app).
- Arnés E2E envía `X-App-Audience` derivado del token.

### 4.3 Fase 8 (Cleanup & Docs) — **100 %**
Archivado del monolito, docs (`SPLIT_ARCHITECTURE_FINAL.md`, `DEPLOY_RUNBOOK.md`, `VIDEO_MAPPING_REGISTRY.md`), RLS funcional verificado con 2 tenants reales (`verifyTenantIsolation.js` exit 0), limpieza de branches (2 remotas + 13 locales, con tags `archive/*-20261101`), legacy Postgres apagado con respaldo en `.backups/`.

### 4.4 Plan de faltantes (monolito → split)
| Fase | Estado |
|---|---|
| 1 · l10n (`.arb` + `l10n.yaml`) e iconos | ✅ `flutter gen-l10n` exit 0 |
| 2 · Inventario y alquileres al provider | ✅ compilan limpio, expuestos en el tab «Más» |
| 5 · Imagen PostGIS+pgvector + RAG | ✅ **staging**: 8/8 migraciones RAG, `halfvec(2048)`, HNSW |
| 3 · Overview del salón | 🟢 acotado a ~200 líneas (no 1.230) |
| 4 · Superadmin en `admin-dashboard` | 🟢 decidido, sin implementar |

### 4.5 Base de datos
- **Drift resuelto:** staging alineado con producción (122 = 122) clonando el esquema de prod.
- **Imagen nueva:** `postgis/postgis:16-3.6` + `postgresql-16-pgvector` (`infra/database/Dockerfile`). Se construye y despliega **sin registry**: `railway up infra/database --path-as-root -s <servicio>`.
- **Migración de PostGIS** 3.4.3 → 3.6.4 y ajuste de collation (glibc 2.31 → 2.41): `ALTER DATABASE railway REFRESH COLLATION VERSION` + `REINDEX DATABASE railway`.
- **RAG en staging:** `030` → `031` → `runRagMigrations.js` (8/8). Columna `embedding = halfvec(2048)`, índice `idx_beauty_knowledge_embedding_hnsw`.

---

## 5. Decisiones tomadas

| ID | Decisión | Fundamento |
|---|---|---|
| **D-1** | Superadmin se construye en `admin-dashboard` (Next.js) | Ya tiene 22 páginas, auth propia y el backend expone `/api/superadmin` (`/tenants`, `/tenants/:id`, `/tenants/:id/plan`, `/tenants/:id/suspend`, `/revenue`) |
| **D-2** | El dashboard de salón **no** se reconstruye: se porta solo el Overview (~200 líneas) | El original **no usa** `salon_miembros`; el shell nuevo ya cubre Equipo, Servicios y Caja. Falta solo el bloque de KPIs (`Citas Hoy`, `Equipo Activo`, salud del negocio) |
| **D-3** | Imagen en GHCR si se publica | El repo ya está en GitHub y CI se autentica ahí. **En la práctica no hizo falta**: `railway up --path-as-root` construye del lado de Railway |
| **D-4** | Migraciones desde disco, nunca embebidas | El SQL embebido se corrompe al re-escapar comillas |

---

## 6. Brechas de paridad abiertas

### 6.1 Tablas que existen en la base real y NO en el esquema nuevo (30)

| Grupo | Tablas |
|---|---|
| RAG | `beauty_knowledge_embeddings`, `rag_entities`, `rag_relations`, `rag_feedback_signals` |
| Belleza IA | `beauty_consents`, `beauty_profile`, `beauty_scan_consents`, `beauty_scan_jobs`, `beauty_scan_sessions`, `color_dnas`, `color_recommendations`, `color_try_on_history`, `evolution_snapshots`, `hair_health_reports`, `hair_treatment_plans` |
| Biometría | `biometric_consent`, `biometric_consent_log` |
| Precios | `listas_precios`, `precios_historial`, `precios_producto` (✅ en staging, faltan en prod) |
| Afiliados | `affiliates`, `affiliate_commissions` |
| Otros | `users`, `legal_holds`, `tiktok_hashtag_trends`, `scan_product_matches`, `knex_migrations` (+lock), `pg_stat_statements` (+info) |

Y una tabla existe solo en el esquema nuevo: `corpus_ingest_manifest` (artefacto de la reconstrucción).

### 6.2 El fork de usuarios — **bloqueante**
La base real tiene `users`; el esquema nuevo tiene `usuarios`. Mientras no se decida cuál es canónico, los splits no pueden quedar "idénticos".

### 6.3 RAG: los chunks
La base real tiene **6 chunks** y **156 consultas registradas**. Los **5.000+ chunks** que se recuerdan **no están en ninguna base viva** de ningún entorno. Lugares sin revisar (por estar apagados y no tocarse):

- Volumen `postgres-volume` de **98 MB, desconectado** en `grateful-harmony` producción.
- `Postgres` de `belleza-app-pr-64` y `belleza-app-pr-87` (ambos Offline).

Nota: la columna en la base real es `real[]`; en staging quedó `halfvec(2048)`. No es el mismo modelo de embeddings.

### 6.4 Metadatos de producción sin personalizar
`https://glowapp-client.web.app` y `https://glowapp-provider.web.app` cargan con `<title>glow_client</title>` y `<meta description="A new Flutter project.">`. Falta título, descripción, theme-color, favicon e iconos PWA en `apps/*/web/index.html`.

---

## 7. Próximos pasos priorizados

1. **Decidir el modelo canónico de usuarios** (`users` vs `usuarios`) — bloquea todo lo demás.
2. **Buscar los 5.000 chunks** en el volumen suelto de 98 MB (montaje de solo lectura).
3. **Replicar la imagen PostGIS+pgvector a producción** — requiere autorización y ventana: `REINDEX DATABASE` bloquea escrituras.
4. **Portar el Overview del salón** (~200 líneas) al shell del provider.
5. **Superadmin en `admin-dashboard`** (páginas nuevas contra `/api/superadmin`).
6. **Cargar la base de conocimiento del RAG** (corpus + `ingest_json_chunks.js` + `NVIDIA_API_KEY`, `NVIDIA_EMBED_URL`, `NVIDIA_EMBEDDING_MODEL` — hoy **no existen** esas variables en ningún entorno).
7. **Metadatos de las dos apps** en `web/index.html`.

---

## 8. Referencias técnicas

```
Repo local:        C:\Users\Compu casa\belleza-app-audit  (bash: ~/belleza-app-audit)
Ramas:             staging = 9a624b06 · main = 4099472a (protegida, solo PR)
Workflow CI:       402270471 (glowapp-firebase-deploy.yml)
Railway glowapp:   a6f51ac4-aac5-4cd6-915e-f87e9da05f2a
  staging:         postgres-postgis.railway.internal · API glowapp-api-staging.up.railway.app
  producción:      postgres-postgis-prod.railway.internal · API glowapp-api-production.up.railway.app
Railway real:      grateful-harmony (production) · Postgres 151 tablas · 313 MB
Firebase:          glowapp-client (634593218804) · glowapp-provider (509840252897)
Admin panel:       https://admin-dashboard-production-ecd5.up.railway.app
Backups:           .backups/  (staging_pre_drift_*, staging_full_pre_swap_*, prod_schema_*)
Runbook BD:        infra/database/README.md   ·   Dockerfile: infra/database/Dockerfile
Baseline de fases: PLAN_UNIFICADO_BASELINE_2026-10-29.md
```

Comandos útiles:
```bash
# Migraciones y RLS (dentro del contenedor, no en local)
railway ssh -s glowapp-api "cd /app && node scripts/prepareRlsDatabase.js"
# Arnés E2E (puerto real del contenedor: 3000)
railway ssh -s glowapp-api 'cd /app && E2E_PASSWORD=<aleatoria> API_URL=http://127.0.0.1:3000 npm run e2e'
# Migraciones del RAG (ledger propio en schema_migrations)
railway ssh -s glowapp-api 'cd /app && RAG_DATABASE_URL="$DATABASE_URL" node scripts/runRagMigrations.js'
# Redesplegar la imagen de BD
railway up infra/database --path-as-root -s postgres-postgis -c
```

**Trampas conocidas:**
- `railway ssh` exige `-s <servicio>` y no admite rutas MSYS; para copiar archivos usa `railway ssh -s <svc> "cat > /tmp/x.sql" < archivo.sql`.
- `PGDATA` debe apuntar a `/var/lib/postgresql/data/pgdata` (la raíz del montaje tiene `lost+found`).
- Exigir `X-App-Audience` en `/api/health` rompe las sondas (ya corregido).
- `ports: [x, x]` en GitHub Actions publica en puerto aleatorio; debe ser `["x:x"]`.

---

## 9. Bloqueos externos

| Bloqueo | Afecta a | Desbloqueo |
|---|---|---|
| Dominio `glowapp.com` no comprado | custom domains (Fase 6) | Compra del dominio |
| Tarjeta en Cloudflare | Cloudflare Stream / HLS (Fase 7) | Método de pago |
| Sin Apple Developer Program | certs iOS | Suscripción Apple |
| Sin `NVIDIA_API_KEY` | RAG (generar embeddings) | Clave de NVIDIA |
| Token `gh` sin `write:packages` | publicar imagen en GHCR | `gh auth refresh -s write:packages` (innecesario: se usa `railway up`) |

---

## 10. Autorizaciones

El Director exige la frase exacta para operar sobre una fase:
`AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F<NN>`

Consumidas: **F004-BACKEND**, **F005**, **F006-RAILWAY**, **F007** (parcial), **F008**.
Producción queda **fuera** de cualquier operación sin autorización nueva.
