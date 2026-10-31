# GlowApp — Deploy Runbook

**Versión:** 1.0 — 2026-10-31  
**Objetivo:** Procedimientos operativos para deploy a staging y producción

---

## 1. Arquitectura de Despliegue

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   GitHub        │────▶│  GitHub Actions  │────▶│  Firebase       │
│   (main/staging)│     │  (dual pipeline) │     │  Hosting        │
└─────────────────┘     └────────┬─────────┘     │  (client/prov)  │
                                 │               └─────────────────┘
                                 ▼
                        ┌──────────────────┐
                        │  Railway         │
                        │  (backend API)   │
                        └──────────────────┘
```

---

## 2. Staging Deploy (Automático)

**Trigger:** Push a branch `staging`

### Pipeline Frontend (`.github/workflows/glowapp-firebase-deploy.yml`)

```yaml
Jobs paralelos:
  ├── deploy-client-staging
  │   ├── flutter build web --dart-define=APP_AUDIENCE=client
  │   ├── FirebaseExtended/action-hosting-deploy@v0
  │   │   ├── projectId: glowapp-client
  │   │   ├── entryPoint: apps/glow_client
  │   │   ├── channelId: staging
  │   │   └── token: ${{ secrets.FIREBASE_TOKEN }}
  │   └── URL resultado: https://glowapp-client--staging-<hash>.web.app
  │
  └── deploy-provider-staging
      ├── flutter build web --dart-define=APP_AUDIENCE=provider
      ├── FirebaseExtended/action-hosting-deploy@v0
      │   ├── projectId: glowapp-provider
      │   ├── entryPoint: apps/glow_provider
      │   ├── channelId: staging
      │   └── token: ${{ secrets.FIREBASE_TOKEN }}
      └── URL resultado: https://glowapp-provider--staging-<hash>.web.app
```

### Pipeline Backend (`.github/workflows/glowapp-build-deploy.yml`)

```yaml
Jobs:
  ├── backend-ci
  │   ├── Wait for PostgreSQL (pg_isready loop 30x10s)
  │   ├── npm ci
  │   ├── npm test (contract tests 47/47)
  │   └── npm run lint
  │
  └── deploy-backend-staging (si backend-ci success)
      ├── railway up --service glowapp-api
      └── Health check: GET /health → 200 OK
```

### Validación Staging

```bash
# Verificar ambos frontends
curl -s -o /dev/null -w "%{http_code}" https://glowapp-client--staging-<hash>.web.app
# → 200 OK

curl -s -o /dev/null -w "%{http_code}" https://glowapp-provider--staging-<hash>.web.app
# → 200 OK

# Verificar backend
curl -s https://glowapp-api-production.up.railway.app/health
# → {"status":"ok",...}

# Verificar onboarding videos (sample)
curl -s -o /dev/null -w "%{http_code}" "https://storage.googleapis.com/download/storage/v1/b/glowapp-client.firebasestorage.app/o/step_01_welcome.mp4?generation=...&alt=media"
# → 200 OK
```

---

## 3. Production Deploy (Manual + Automático)

**Trigger:** Push a branch `main` (protected)

### Frontend

- Mismo workflow, `channelId: live` → deploya a canal `live` (producción)
- URLs finales requieren DNS custom domains configurados

### Backend

- Mismo workflow, `railway up --service glowapp-api` con variables de producción
- Requiere variables `NODE_ENV=production`, `JWT_SECRET` (64 chars base64)

### DNS Custom Domains (Pendiente compra `glowapp.com`)

| Subdominio | Target | Tipo | Status |
|------------|--------|------|--------|
| `app.glowapp.com` | `glowapp-client.web.app` | CNAME | ⏳ Pendiente |
| `pro.glowapp.com` | `glowapp-provider.web.app` | CNAME | ⏳ Pendiente |
| `api.glowapp.com` | `glowapp-api-production.up.railway.app` | CNAME | ⏳ Pendiente |
| `admin.glowapp.com` | (futuro admin-dashboard) | CNAME | ⏳ Pendiente |

**Configuración Firebase Hosting:**
```bash
# En cada proyecto Firebase Console > Hosting > Custom domains
# 1. Add custom domain → app.glowapp.com
# 2. Verify ownership (TXT record)
# 3. Configure DNS (CNAME to <project>.web.app)
# 4. SSL auto-provisioned
```

---

## 4. Variables Críticas por Servicio

### Railway — glowapp-api (Backend)

```bash
# Configuradas (22 variables)
APP_AUDIENCE=admin
NODE_ENV=production
JWT_SECRET=<64-char-base64>
JWT_AUDIENCE=admin
X_APP_AUDIENCE=admin
DATABASE_URL=postgresql://postgres:<PASS>@postgres.railway.internal:5432/railway
REDIS_URL=redis://:<PASS>@redis.railway.internal:6379
FIREBASE_SERVICE_ACCOUNT=<client-backend-SA-json>
BACKEND_FIREBASE_CLIENT_SERVICE_ACCOUNT=<client-backend-SA-json>
BACKEND_FIREBASE_PROVIDER_SERVICE_ACCOUNT=<provider-backend-SA-json>
FIREBASE_PROVIDER_VAPID_KEY=<provider-vapid>
FIREBASE_CLIENT_VAPID_KEY=<client-vapid>
SEED_PASSWORD=<secure>
```

### Railway — glowapp-client (Frontend, deprecated)

```bash
APP_AUDIENCE=client
FIREBASE_PROJECT_ID=634593218804
FIREBASE_AUTH_DOMAIN=glowapp-client.firebaseapp.com
FIREBASE_API_KEY=<client-web-api-key>
FIREBASE_STORAGE_BUCKET=glowapp-client.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=634593218804
FIREBASE_WEB_APP_ID=1:634593218804:web:<id>
FIREBASE_IOS_APP_ID=  # Vacío (sin iOS)
```

### Railway — glowapp-provider (Frontend, deprecated)

```bash
APP_AUDIENCE=provider
FIREBASE_PROJECT_ID=509840252897
FIREBASE_AUTH_DOMAIN=glowapp-provider.firebaseapp.com
FIREBASE_API_KEY=<provider-web-api-key>
FIREBASE_STORAGE_BUCKET=glowapp-provider.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=509840252897
FIREBASE_WEB_APP_ID=1:509840252897:web:<id>
FIREBASE_IOS_APP_ID=  # Vacío (sin iOS)
```

---

## 5. Rollback Procedures

### Frontend (Firebase Hosting)

```bash
# Via Firebase Console
# 1. Hosting > Versions history
# 2. Click "Rollback" en versión anterior
# 3. Confirm

# Via CLI (requiere FIREBASE_TOKEN)
firebase hosting:channel:deploy live --project glowapp-client --expired
# O promover versión anterior:
firebase hosting:clone <SOURCE_SITE>:<SOURCE_CHANNEL> <TARGET_SITE>:live
```

### Backend (Railway)

```bash
# Via Railway Dashboard
# 1. Service glowapp-api > Deployments
# 2. Click "Redeploy" en deployment anterior

# Via CLI
railway service glowapp-api
railway redeploy <DEPLOYMENT_ID>
```

### Database Migrations (Si aplica)

```bash
# Railway: conectar a DB y ejecutar migraciones manualmente
railway connect postgres
# O desde backend container:
npm run migrate
```

---

## 6. Secrets Management

### GitHub Secrets (47 configurados)

| Secreto | Uso | Rotación |
|---------|-----|----------|
| `FIREBASE_TOKEN` | Deploy Firebase Hosting | Anual / al rotar SA |
| `RAILWAY_TOKEN` | Deploy Railway (Project Token, `project:admin`) | Anual |
| `JWT_SECRET` | Firma JWT backend | Rotar si compromiso |
| `DATABASE_URL` / `REDIS_URL` | Conexión DB/Cache | Rotar credenciales Railway |
| `BACKEND_FIREBASE_*_SERVICE_ACCOUNT` | FCM Admin SDK | Rotar SA keys en GCP |
| `*_VAPID_KEY` | Web Push FCM | Rotar si compromiso |
| `GRAFANA_CLOUD_*` | Observabilidad | Rotar API keys Grafana |

### Railway Variables (No secrets, pero sensibles)

- Configurar via `railway variable set --service <svc> KEY=value`
- Ver: `railway variables --service <svc> --kv`

---

## 7. Troubleshooting Común

| Síntoma | Causa Probable | Acción |
|---------|----------------|--------|
| Frontend 404 en rutas profundas | Falta SPA rewrite | Verificar `firebase.json` → `rewrites: [{source: "**", destination: "/index.html"}]` |
| Backend 500 "JWT_SECRET obligatoria" | Variable no seteada en Railway | `railway variable set --service glowapp-api JWT_SECRET=<val>` |
| FCM no llega a web | VAPID key mismatch | Verificar `FIREBASE_VAPID_KEY` en frontend + `FIREBASE_*_VAPID_KEY` en backend |
| Audience 400 "Missing X-App-Audience" | Header no enviado | Frontend: `headers: {'X-App-Audience': 'client\|provider'}` |
| PostgreSQL connection refused en CI | DB no lista | Workflow ya tiene `Wait for PostgreSQL` step (pg_isready) |
| Secrets scanner bloquea CI | `***` o `API_KEY \|\|` en código | Usar `REPLACE_ME` o reestructurar validación |

---

## 8. Comandos Útiles

```bash
# Ver estado Railway
railway status --service glowapp-api
railway logs --service glowapp-api --tail 100

# Ver variables
railway variables --service glowapp-api --kv
railway variables --service glowapp-client --kv
railway variables --service glowapp-provider --kv

# Trigger manual deploy staging
gh workflow run glowapp-firebase-deploy.yml --ref staging

# Ver runs
gh run list --branch staging --limit 5
gh run watch <RUN_ID>

# Firebase Hosting channels
firebase hosting:channel:list --project glowapp-client
firebase hosting:channel:list --project glowapp-provider
```

---

## 9. Checklist Pre-Deploy Producción

- [ ] DNS custom domains comprados y configurados
- [ ] `JWT_SECRET` rotado y ≥32 chars
- [ ] Service Accounts con roles mínimos (`firebase.messaging`, `datastore.user`, `firebaseauth.admin`)
- [ ] VAPID keys sincronizadas frontend/backend
- [ ] Staging smoke tests pasan (login → reserva → chat)
- [ ] RLS multi-tenant verificado en staging
- [ ] Observabilidad dashboards/alertas operativos
- [ ] Runbook accesible al equipo
- [ ] Rollback probado en staging

---

*Parte de Fase 8 — Cleanup & Docs*