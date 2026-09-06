# AUDITORÍA DE RENDIMIENTO Y BASE DE DATOS - Beauty App

**Fecha:** 2026-09-02  
**Versión:** 1.0  
**Alcance:** PostgreSQL (Docker, puerto 5435→5432), Node.js Backend, 60+ migraciones, schema.sql (291 líneas / 11989 chars), backup 252MB

---

## 1. CONFIGURACIÓN DE CONNECTION POOLING (`backend/src/config/db.js`)

### Pool Principal (líneas 12-25)
| Parámetro | Valor | Evaluación |
|-----------|-------|------------|
| `max` | 30 prod / 20 dev | ✅ Apropiado para carga moderada. 30 conexiones en prod permite concurrencia razonable sin agotar recursos PG. |
| `idleTimeoutMillis` | 30,000 (30s) | ✅ Estándar. Libera conexiones inactivas rápido. |
| `connectionTimeoutMillis` | 5,000 (5s) | ⚠️ **Riesgoso en red inestable**. 5s puede causar fallos transitorios bajo carga o cold starts. Recomendado: 10-15s. |
| `ssl` | `rejectUnauthorized: false` en prod/staging | ⚠️ **Seguridad**: Desactiva validación de certificado. En Railway/Cloud usar certs válidos o `true`. |

### Pool RAG (líneas 46-56)
| Parámetro | Valor | Evaluación |
|-----------|-------|------------|
| `max` | 15 prod / 10 dev | ✅ Separado del pool principal. 15 conexiones para vector search (HNSW) es razonable. |
| Timeouts | Iguales al principal | ✅ Consistente. |

### Hallazgos Críticos
1. **Sin `allowExitOnIdle`** → El pool mantiene el proceso vivo indefinidamente. En serverless/container restart puede causar memory leaks.
2. **Sin `statement_timeout` / `query_timeout`** → Queries colgadas pueden agotar el pool silenciosamente.
3. **No hay monitoring de pool** (eventos `acquire`, `release`, `error` no loggean métricas).
4. **DATABASE_URL vs parámetros discretos** → Mezcla ambos enfoques (líneas 14-20). Si `DATABASE_URL` existe, ignora DB_USER, etc. Puede causar confusión en deployments.

---

## 2. ÍNDICES EN TABLAS CRÍTICAS

### Análisis del backup real (`backup_beauty_db.sql` - 4761 líneas, 252MB)

| Tabla | Índices Existentes | Índices Faltantes / Recomendados |
|-------|-------------------|----------------------------------|
| **usuarios** (PK id, 15+ columnas) | `idx_usuarios_email` (unique), `idx_usuarios_auth_provider`, `idx_usuarios_tenant_id` | ❌ **Falta**: `(tenant_id, rol)` para auth middleware, `(tenant_id, is_active)` para listados, `(email, tenant_id)` composite para login multi-tenant |
| **bookings** (UUID PK, 15 cols) | `idx_bookings_tenant_id` | ❌ **Falta**: `(provider_id, scheduled_at)` para agenda, `(client_id, estado)` para historial cliente, `(estado, scheduled_at)` para dashboard, `(tenant_id, estado, scheduled_at)` composite crítico |
| **servicios** (UUID PK) | `idx_servicios_tenant_id` | ❌ **Falta**: `(provider_id, is_active)`, `(tenant_id, category, is_active)`, `(tenant_id, price)` |
| **perfiles_prestador** | **NO EXISTE EN BACKUP** (schema.sql sí la tiene) | ⚠️ **Discrepancia schema vs backup**. Si existe: `(tenant_id, is_active, ubicacion)` + GiST en `ubicacion` |
| **productos** (SERIAL PK) | `idx_productos_tenant_id` | ❌ **Falta**: `(tenant_id, tag_especialidad, stock)`, `(tenant_id, precio)` |
| **user_activity_logs** (BIGSERIAL PK) | `idx_activity_logs_session`, `idx_activity_logs_event`, `idx_user_activity_logs_tenant_id` | ⚠️ **Parcial**: Falta `(tenant_id, user_id, creado_en DESC)` para analytics por usuario, `(tenant_id, event_type, creado_en)` para métricas |
| **beauty_knowledge_embeddings** (RAG) | HNSW en `embedding`, índices en `category`, `tenant_id`, `deleted_at`, `expires_at`, `document_id`, `chunk_id`, `content_hash`, `fuente`, `skin_type`, `season_station`, `age_range`, GIN en `ingredients`, `contraindications` | ✅ **Completo** - Bien indexado para vector + metadata filtering |
| **rag_query_logs** | Índices en `created_at`, `trace_id`, `user_id_hash`, `category`, `threshold_used`, `retrieval_mode`, `fallback_triggered`, composite `(created_at, category)` | ✅ **Completo** para observabilidad RAG |

### Resumen Índices
- **Crítico**: 6/7 tablas core carecen de índices compuestos para query patterns reales
- **RAG/pgvector**: Bien indexado (migraciones 035, 046, 047)
- **Multi-tenancy**: Solo índices simples en `tenant_id` — necesitan compuestos con columnas de filtrado frecuente

---

## 3. MIGRACIONES PROBLEMÁTICAS - MULTI-TENANCY (055-058)

### 055_create_tenants_table.sql ✅
- Crea tabla `tenants` con `id SERIAL PK`, `slug UNIQUE`
- Inserta tenant default (id=1) — **Hardcodeado id=1** puede colisionar con sequence

### 056_add_tenant_id_to_core_tables.sql ⚠️ **PROBLEMAS**
```sql
-- Agrega tenant_id NULLABLE a 10 tablas core
-- NO crea FK a tenants(id) — se añade en migración posterior
-- NO backfilla datos existentes
```
**Riesgo**: Tablas quedan con `tenant_id NULL` hasta migración 057. Ventana de inconsistencia.

### 057_backfill_tenant_id.sql ⚠️ **PROBLEMAS CRÍTICOS**
1. **Secuencia rota**: `PERFORM setval(pg_get_serial_sequence('tenants', 'id'), COALESCE((SELECT MAX(id) FROM tenants), 0) + 1, false);` — Si 055 insertó id=1, sequence queda en 2. OK.
2. **Demo tenant vs Default tenant**: Inserta 'Demo Tenant' (slug='demo') y usa su ID para backfill. Pero 055 ya insertó 'Default Tenant' (slug='default', id=1). **Dos tenants por defecto** → confusión.
3. **Backfill UPDATE sin WHERE optimizado**: `UPDATE usuarios SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;` — Escaneo secuencial completo en tabla grande. Sin `WHERE id > 0` chunking.
4. **Tablas opcionales alteradas inline**: `platform_config`, `admin_mfa`, `productos`, `beauty_knowledge_embeddings` — **ALTER TABLE + ADD COLUMN + REFERENCES + UPDATE** en misma transacción → locks exclusivos prolongados.
5. **Índices creados en DO block dinámico**: `CREATE INDEX IF NOT EXISTS idx_%s_tenant_id` — No verifican si columna existe antes (aunque 056 debería haberla creado).

### 058_enable_rls_policies.sql ⚠️ **PROBLEMAS**
1. **Array `rls_tables` incluye `'services'`** → En backup la tabla es `servicios` (no `services`). **Falla silenciosamente** (IF EXISTS pasa, pero no habilita RLS en la tabla real).
2. **Políticas usan `current_setting('app.tenant_id')`** → Requiere `SET app.tenant_id = 'X'` en cada conexión. **No hay middleware que lo haga** → RLS inefectivo.
3. **Policy `FOR ALL`** → Aplica a SELECT, INSERT, UPDATE, DELETE. Para INSERT debería usar `WITH CHECK`, no solo `USING`.
4. **No hay policy para `perfiles_prestador` en backup** (tabla no existe en backup).

---

## 4. TABLAS RAG / PGVECTOR (Migraciones 031, 035, 046, 047, 048)

| Migración | Propósito | Estado |
|-----------|-----------|--------|
| **031** | Crear `beauty_knowledge_embeddings` con `vector(768)` | ✅ Base |
| **035** | Cambiar a `vector(1024)` (NV-Embed-QA), crear HNSW (`m=16, ef_construction=64`), añadir metadata (skin_type, season_station, age_range, ingredients[], contraindications[]), fallback IVFFlat | ✅ **Robusta** - Idempotente, verifica extensión, maneja errores |
| **046** | Trazabilidad R3: `document_id`, `document_version`, `chunk_id`, `content_hash`, `fuente`, `seccion` + UK `(document_id, chunk_id)` + backfill desde `metadata` JSONB | ✅ **Completa** - Índices dedicados, constraint única |
| **047** | Trazabilidad query logs: `category`, `threshold_used`, `filters_applied` JSONB, `all_scores`[], `retrieval_mode`, `fallback_triggered`, `breaker_state_at_query` | ✅ **Completa** - Para observabilidad RAG |
| **048** | **Fix crítico**: `chunk_id` VARCHAR(64)→TEXT, `document_id` VARCHAR(255)→TEXT (22.8% chunk_ids > 64 chars en corpus canónico) | ✅ **Necesaria y correcta** - No destructiva, mantiene UK |

### Evaluación General RAG
- **Esquema maduro**: 1024-dim, HNSW, metadata filtering, trazabilidad completa
- **Índices**: HNSW + GIN (arrays) + B-tree (metadata) → Cobertura completa
- **Backup incluye**: `rag_query_logs` con todas las columnas de trazabilidad (047 aplicada)
- **Riesgo**: `embedding vector(1024)` consume ~4KB/row. Con 5000+ chunks = ~20MB solo vectores. Monitor `pg_total_relation_size`.

---

## 5. TRIGGERS Y FUNCIONES

### En `schema.sql` (291 líneas)
| Objeto | Tipo | Evaluación |
|--------|------|------------|
| `calc_booking_split()` | Trigger function (BEFORE INSERT/UPDATE ON bookings) | ✅ Calcula comisión 12% + impuestos 8% = 20% total. **Hardcodeado** — debería leer de `platform_config`. |
| `before_booking_insert_update` | Trigger | ✅ Correcto |

### En `backup_beauty_db.sql` (Producción real)
| Objeto | Tipo | Evaluación |
|--------|------|------------|
| `calc_booking_split()` | Function v2 | ⚠️ **Versión distinta a schema.sql**: Fórmula continua `max(15%, 28% - 0.00008 * valor_bruto)`. **Drift de schema vs prod**. |
| `set_disputa_sla()` | Trigger function | ✅ SLA 48h automático |
| `update_user_preferences_updated_at()` | Trigger function | ✅ Updated_at automático |
| `trg_disputa_sla` | Trigger ON disputas | ✅ |
| `trigger_update_user_preferences_updated_at` | Trigger ON user_preferences | ✅ |
| **RLS Policies (5)** | `tenant_isolation_*` ON bookings, productos, sos_alerts, user_activity_logs, usuarios | ⚠️ **Sin middleware que setee `app.tenant_id`** → No funcionan |

### Funciones Huérfanas / Rotas Detectadas
1. **`calc_booking_split` tiene 2 versiones** (schema.sql vs backup) — **Drift crítico**
2. **No hay triggers de updated_at** en: usuarios, perfiles_prestador, servicios, productos, transactions, reviews, messages, nail_tryon_jobs, sos_alerts
3. **No hay trigger de limpieza** para `nail_tryon_jobs.expires_at` (job externo `paymentJobs.js` lo hace)
4. **RLS habilitado pero inefectivo** — Falta `SET LOCAL app.tenant_id` en middleware o `SET app.tenant_id` en pool connection

---

## 6. QUERY PATTERNS EN AUTH MIDDLEWARE

### `backend/src/middleware/auth.js` línea 31
```javascript
const userRes = await pool.query('SELECT rol, tenant_id FROM usuarios WHERE id = $1', [verified.id]);
```
**Ejecutada en CADA request autenticado** (salvo cache `req.user` preexistente).

### Problemas de Rendimiento
| Aspecto | Impacto |
|---------|---------|
| **Sin índice compuesto** | Solo `idx_usuarios_tenant_id` y `idx_usuarios_email` (PK id ya indexado). Query por PK es O(1) — **OK para lookup individual**. |
| **N+1 potencial** | Si middleware se llama en chain sin cache, cada request = 1 roundtrip PG. Con 30 pool max, 1000 req/s = agotamiento. |
| **No selecciona `tier`** | `rateLimiter.js` línea 153 hace **query separada**: `SELECT tier FROM usuarios WHERE id = $1` → **2 queries por request autenticado**. |
| **Redis token blacklist** | `redisClient.get()` antes de JWT verify — **latencia extra** por request. |

### Optimización Recomendada
```javascript
// Query único en authMiddleware
const userRes = await pool.query(
  'SELECT rol, tenant_id, tier FROM usuarios WHERE id = $1', 
  [verified.id]
);
// Cachear tier en req.user.tier para rateLimiter
```

---

## 7. BACKUP / RESTORE STRATEGY

| Aspecto | Estado Actual | Evaluación |
|---------|---------------|------------|
| **Archivo** | `backup_beauty_db.sql` (252MB, 4761 líneas) | ✅ Existe |
| **Formato** | `pg_dump` plain SQL (verbose, no comprimido) | ⚠️ **Ineficiente** — 252MB texto = restore lento. Usar `-Fc` (custom) + `pg_restore -j N` paralelo. |
| **Frecuencia** | No documentada / manual | ❌ **Crítico** — Sin automatización (cron, pg_cron, WAL-G, Barman). |
| **Retención** | No documentada | ❌ |
| **Testing restore** | No documentado | ❌ **Riesgo alto** — Backup sin test = no backup. |
| **PITR / WAL Archiving** | No configurado | ❌ Para 252MB DB, WAL-G o pgBackRest recomendado. |
| **Schema vs Data** | Backup incluye schema + data (DUMP completo) | ✅ Completo pero monolítico. |
| **RAG Data** | `beauty_knowledge_embeddings` + `rag_query_logs` incluidos | ✅ Vector data backed up (pg_dump maneja vector type). |

### Tamaño y Tiempos Estimados
- **Backup (pg_dump plain)**: ~2-5 min
- **Restore (psql)**: ~15-30 min (single-threaded, indexes rebuild)
- **Restore (pg_restore -j 4 custom)**: ~3-5 min

---

## 8. SCHEMA.SQL ACTUAL (11989 chars / 291 líneas)

### Discrepancias Críticas vs Backup (Producción)
| Elemento | schema.sql | backup_beauty_db.sql | Impacto |
|----------|------------|---------------------|---------|
| **usuarios** | `tipo_rol` ENUM, `tipo_auth_provider` ENUM, `password_hash`, `provider_id` NOT NULL | `rol` VARCHAR(20), `auth_provider` VARCHAR(50), sin `provider_id` NOT NULL | **Drift mayor** — Auth puede fallar |
| **perfiles_prestador** | Existe (líneas 62-80) | **NO EXISTE** | **Tabla faltante en prod** — Features de prestador rotas |
| **services** | Existe (líneas 86-96) | `servicios` existe (distinto nombre/estructura) | **Incompatibilidad** — Código usa `services`, BD tiene `servicios` |
| **bookings** | `service_id UUID REFERENCES services(id)` | `service_id UUID` (nullable, sin FK), `tenant_id` | **FK rota en prod** |
| **calc_booking_split** | 20% fijo (12% + 8%) | Fórmula continua decreciente | **Lógica de negocio divergente** |
| **RAG embeddings** | `vector(768)` (línea 288) | `vector(1024)` (migración 035 aplicada) | **Dimensión errónea en schema.sql** |
| **Tablas RAG** | Solo `beauty_knowledge_embeddings` básica | + `rag_query_logs` completa, índices HNSW, trazabilidad 046/047 | **Schema.sql desactualizado** |

### Conclusión
**`schema.sql` NO refleja el estado real de producción**. Es un artefacto de desarrollo desactualizado. **No usar para recrear entornos**.

---

## 9. RESUMEN EJECUTIVO - PRIORIDADES

### 🔴 CRÍTICO (Bloqueadores / Riesgo Alto)
1. **Schema drift**: `schema.sql` vs producción divergen en tablas core (usuarios, perfiles_prestador, services/servicios, bookings, commission logic). **Reconciliar urgentemente**.
2. **RLS inefectivo**: Políticas creadas pero `app.tenant_id` nunca seteado → **Fuga de datos multi-tenant**.
3. **Connection timeout 5s**: Demasiado agresivo → errores transitorios bajo carga.
4. **Backup sin automatización ni testing**: 252MB sin restore verificado = **pérdida de datos garantizada en desastre**.
5. **2 queries por request autenticado** (auth + rateLimiter) → latencia innecesaria.

### 🟡 ALTO (Optimización Necesaria)
6. **Índices compuestos faltantes** en 6/7 tablas core para query patterns reales (tenant_id + filtros frecuentes).
7. **Migración 058**: `services` vs `servicios` — RLS no aplicado a tabla real.
8. **Migración 057**: Backfill sin chunking + doble tenant default + ALTER TABLE locks en tablas opcionales.
9. **Pool sin statement_timeout / monitoring** → Queries colgadas agotan pool silenciosamente.
10. **`calc_booking_split` hardcodeado** vs `platform_config` — Config no respeta dinamismo.

### 🟢 MEDIO (Mejora Continua)
11. **Backup format**: Migrar a `pg_dump -Fc` + `pg_restore -j N` + compresión.
12. **Triggers `updated_at`** faltantes en 10+ tablas.
13. **Pool RAG**: Considerar `statement_timeout` más bajo para vector search (HNSW puede ser lento en cold start).
14. **Documentar**: Runbooks de backup/restore, disaster recovery, multi-tenant onboarding.

---

## 10. ACCIONES RECOMENDADAS (ORDEN DE EJECUCIÓN)

| # | Acción | Esfuerzo | Riesgo |
|---|--------|----------|--------|
| 1 | **Generar schema real desde prod** (`pg_dump -s`) y reemplazar `schema.sql` | 30 min | Bajo |
| 2 | **Añadir middleware `SET LOCAL app.tenant_id`** en authMiddleware tras leer `tenant_id` | 15 min | Bajo |
| 3 | **Unificar query auth + rateLimiter**: `SELECT rol, tenant_id, tier FROM usuarios WHERE id = $1` | 15 min | Bajo |
| 4 | **Subir `connectionTimeoutMillis` a 10000** (10s) | 1 min | Bajo |
| 5 | **Añadir `statement_timeout: 30000`** a ambos pools | 1 min | Bajo |
| 6 | **Crear índices compuestos críticos** (ver tabla sección 2) via migración nueva | 1-2 h | Medio (locks) |
| 7 | **Fix migración 058**: Cambiar `'services'` → `'servicios'` en array RLS | 10 min | Bajo |
| 8 | **Automatizar backup**: `pg_dump -Fc -Z 3` + cron + `pg_restore` test mensual | 2 h | Bajo |
| 9 | **Reconciliar `calc_booking_split`**: Usar `platform_config.comision_plataforma_pct` | 30 min | Medio |
| 10 | **Auditar migraciones 056-057**: Verificar estado tenant_id en prod (NULLs?, FKs?) | 1 h | Medio |

---

## ANEXO: COMANDOS ÚTILES PARA VERIFICACIÓN

```bash
# Ver estado real de tablas e índices en prod
psql $DATABASE_URL -c "\dt+"
psql $DATABASE_URL -c "\di+"

# Verificar RLS habilitado
psql $DATABASE_URL -c "SELECT relname, relrowsecurity FROM pg_class WHERE relrowsecurity;"

# Ver políticas
psql $DATABASE_URL -c "SELECT * FROM pg_policies WHERE schemaname='public';"

# Tamaño tablas
psql $DATABASE_URL -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname='public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 20;"

# Backup comprimido paralelo
pg_dump -Fc -Z 3 -j 4 $DATABASE_URL > backup_$(date +%F).dump

# Restore paralelo
pg_restore -j 4 -d $DATABASE_URL backup_2026-09-02.dump

# Verificar drift schema vs prod
pg_dump -s $DATABASE_URL > prod_schema.sql
diff -u backend/schema.sql prod_schema.sql
```

---

**Fin del Informe**