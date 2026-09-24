# PROMPT PARA ANTIGRAVITY — Cierre de la auditoría de Academia Glow: merge, deploy a Railway y poda de ramas

> Uso: pegar tal cual. Todo lo que sigue está verificado con comandos reales sobre `C:\beauty-app`
> (repo autoritativo, remoto `https://github.com/Diegoromerov/belleza-app.git`).
> No hay nada especulativo: cada afirmación tiene su comando o su archivo.

---

## 0. Regla de trabajo

El merge a `main` está **expresamente aprobado por Diego** en esta iteración (es el disparador del
deploy). La regla del `AGENTS.md` ("never apply patches to main automatically") queda exceptuada
**solo** para este fast-forward, y **nunca** se usa `--force` sobre `main`.

Prohibido en esta tarea:
- `git push --force` / `--force-with-lease` sobre `main` o sobre ramas publicadas.
- Tocar el trabajo sin commitear de los 4 worktrees sucios (lista en la Fase 4).
- Volver a aplicar a mano las migraciones `066`/`067` (el runner las aplica una sola vez; ver Fase 3).
- Commitear `analyze_rows.pkl` / `audit_lib.pkl` (ya están en `.gitignore`).
- "Arreglar" las suites rojas preexistentes de `main` (son deuda previa, no de esta rama).

---

## 1. Estado exacto del que partes (verifícalo antes de tocar nada)

```
git -C C:/beauty-app status --porcelain      # debe salir VACÍO (árbol limpio)
git -C C:/beauty-app branch --show-current   # fix/academia-glow-auditoria-2026-09-22
git -C C:/beauty-app rev-parse --short HEAD  # 362b590c
git -C C:/beauty-app rev-list --left-right --count origin/main...HEAD   # 0    14
```

- La rama `fix/academia-glow-auditoria-2026-09-22` **ya está pusheada** y su SHA remoto es idéntico
  (`git ls-remote --heads origin fix/academia-glow-auditoria-2026-09-22` → `362b590c…`).
- Contiene **14 commits** sobre `origin/main`: 7 de la Auditoría 360 (`fix/audit-360-remediation`,
  que quedó como rama aparte) + 7 de la auditoría de Academia Glow.
- `0` commits detrás ⇒ **el merge es fast-forward puro, sin conflictos**.
- Los 10 archivos que tenías sin commitear (panel: `login`, `AuthContext`, `api-client`, `middleware`,
  `useBookings`, docs y generados de Flutter) **ya están preservados** en el commit `362b590c`
  (`wip(audit360): preserva el trabajo en curso del panel y el inventario de pendientes`).
  No los vuelvas a aplicar.

**Puerta de calidad antes del merge** (debe dar 90/90; ya verificado en este SHA, re-confírmalo):

```
cd C:/beauty-app/backend
npx jest tests/audit360-remediation.test.js tests/academy.service.test.js \
         tests/academy.routes.test.js tests/academy.migrations.test.js \
         tests/academy.retention.test.js
```

---

## 2. FASE 1 — Unificar en `main` (esto es lo que dispara Railway)

```
cd C:/beauty-app
git fetch origin
git switch main
git merge --ff-only fix/academia-glow-auditoria-2026-09-22
git push origin main
```

Si `--ff-only` falla, **DETENTE y repórtalo**: significa que alguien empujó a `main` después de la
verificación y el merge ya no es lineal. No uses `--no-ff` ni resuelvas conflictos a ciegas.

Verificación del push (no la asumas por el output del push):

```
git ls-remote --heads origin main
git log --oneline -1 origin/main          # debe ser 362b590c (o el merge ff resultante)
git rev-list --count origin/main..main    # 0  → main local y remoto alineados
```

Aviso esperado y **no bloqueante**: el workflow `ci.yml` corre tests en push a `main`. `main` arrastra
fallos preexistentes en las suites `business*` (`req.user.id` es string y `user_id` es INTEGER) y en
`sprint4_agents` (8 vs 11 herramientas) — son anteriores a esta rama. Deja constancia de que siguen
siendo los mismos y no los persigas en esta iteración.

---

## 3. FASE 2 — Deploy a Railway (aquí está el único bloqueo real)

Lo verificado sobre el repo:

- **No existe job de deploy en el repo**: `.github/workflows/ci.yml` solo corre tests + `flutter analyze`
  + escáner de secretos, y `rag-evaluation.yml` es un quality gate. No hay `k8s/`, `helm/` ni
  `railway.json` / `railway.toml`.
- El `railway.yml` de la raíz **no es un archivo que Railway consuma** (Railway lee
  `railway.json` / `railway.toml`, y su config-as-code ya está deprecado a favor de
  `.railway/railway.ts`). Ese archivo es una plantilla estilo compose de tu stack
  (`pgvector-db` con `Dockerfile.postgres`, `redis`, `ai-worker`, `backend` con `./backend/Dockerfile`).
- Por descarte verificado, el deploy ocurre por **auto-deploy de Railway sobre el branch conectado**:
  *"services linked to a GitHub repo automatically deploy when new commits are detected in the
  connected branch"*. Por eso el paso 2 es el disparador.
- **Bloqueo**: el `RAILWAY_TOKEN` del entorno está **inválido** (`railway whoami` → *Unauthorized*;
  CLI en `v5.12.1` vs `v5.59.0` actual). No se pudo verificar ni disparar el deploy desde aquí.

Qué hacer, en este orden:

1. `railway upgrade --yes` y luego, con un token válido que debe aportar Diego
   (`railway login` interactivo o `RAILWAY_TOKEN=<válido>`): `railway whoami` → debe responder con
   la cuenta, no *Unauthorized*.
2. `railway status` / dashboard: confirmar **qué branch está conectado** al servicio del backend y
   que sea `main`; confirmar que el servicio usa `backend/Dockerfile` (build desde `./backend`),
   que `PORT` es coherente con el healthcheck y que existen `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`,
   `DB_PASSWORD`, `REDIS_HOST`, `REDIS_PORT`, `JWT_SECRET`, `ALLOWED_ORIGINS`, `GEMINI_API_KEY`,
   `DEEPSEEK_API_KEY`, `DEEPSEEK_BASE_URL` (son las que declara `railway.yml`).
3. Si el branch conectado **no** es `main`: cámbialo en el dashboard a `main` (o haz el push sobre el
   branch conectado, pero **no** crees una rama nueva para esto).
4. Leer el log del deploy y confirmar: build OK, arranque sin `ECONNREFUSED`, y el healthcheck en verde.

**Criterio de éxito del deploy** (evidencia ejecutada, no inferida):

```
curl -s -o /dev/null -w "%{http_code}\n" https://<host-backend>/health                  # 200
curl -s https://<host-backend>/api/academy/courses/c0000000-0000-0000-0000-000000000003 # 9 módulos, 15 lecciones
curl -s -o /dev/null -w "%{http_code}\n" https://<host-backend>/api/academy/verify/GLW-NOEXISTE  # 404 controlado, NO 500
```

Y en la base de producción (`railway connect` o el cliente que uses):

```sql
SELECT version FROM schema_migrations ORDER BY version;  -- deben aparecer 066 y 067
SELECT COUNT(*) FROM academy_modules WHERE course_id = 'c0000000-0000-0000-0000-000000000003';  -- 9
SELECT COUNT(*) FROM academy_lessons WHERE module_id IN
  (SELECT id FROM academy_modules WHERE course_id = 'c0000000-0000-0000-0000-000000000003');    -- 15
```

Las migraciones `066`/`067` se aplican **una sola vez** en el primer arranque y quedan registradas en
`schema_migrations`. **No** las re-ejecutes a mano: si el curso 3 no sale con 9/15, el diagnóstico es
que el runner no las aplicó, no que falten más parches.

---

## 4. FASE 3 — Operación en producción (lo que la app promete y hoy no corre)

Estos dos scripts están versionados y son idempotentes; hasta ahora **solo se probaron contra una
réplica local**, nunca contra producción:

1. **Publicar el material didáctico real** (4 lecciones de `docs/academy/modulo-1/*.md`). Sin esto,
   producción sigue mostrando el aviso honesto de "en preparación":
   ```
   cd backend && DATABASE_URL=<producción> node scripts/publishAcademyContent.js        # simulación
   cd backend && DATABASE_URL=<producción> node scripts/publishAcademyContent.js --apply
   ```
   Comprobar después: 4 lecciones con `content_text` largo (>10 000 caracteres), 0 residuos de
   `CONTENIDO_LECCION_` y las 11 restantes con el aviso de "en preparación".
2. **Cumplir la retención de 12 meses** que promete el consentimiento biométrico. Debe quedar
   **programado** (cron/scheduler de Railway), no ejecutado a mano una vez:
   ```
   node scripts/purgeAcademyEvidence.js            # simulación: cuántas evidencias vencerían
   node scripts/purgeAcademyEvidence.js --apply
   ```
   Borra `evidencia_foto_url`, marca `respuestas_texto` como purgada y **conserva** la constancia de
   entrega y el consentimiento. Si no se programa, la promesa legal sigue siendo falsa.

---

## 5. FASE 4 — Cerrar el backlog de ramas (no dejar que vuelva a crecer)

Estado ya alcanzado en esta iteración: **26 → 10 ramas locales**, **11 → 4 remotas**, **13 → 5
worktrees**. Se borró todo lo que era demostrablemente redundante (cada rama borrada estaba en
`git branch -r --merged origin/main`, o apuntaba al mismo commit que otra). El registro con los SHAs
está en `C:/Users/Compu casa/auditorias/belleza-app/RAMAS-PODADAS-2026-09-22.md`.

Al mergear la Fase 1, estas dos quedan obsoletas y **deben borrarse** (ese es el pedido explícito de
Diego: unificar → hacer obsoleta → borrar):

```
git push origin --delete fix/academia-glow-auditoria-2026-09-22   # ya está en main
git branch -D fix/audit-360-remediation                           # sus 3 commits ya están en main
git branch -D fix/academia-glow-auditoria-2026-09-22              # (hazlo desde main, no desde ella)
```

Quedan **5 ramas con trabajo NO integrado**. Para cada una, aplica este criterio y actúa — no las
borres a ciegas, pero tampoco las dejes crecer:

| Rama | Commits propios | Qué hacer |
|---|---|---|
| `feature/ai-nail-tryon-legacy` | +25 | Revisar `git log --oneline origin/main..feature/ai-nail-tryon-legacy`. Si es funcionalidad viva → PR. Si no → anotar SHA y borrar. |
| `audit/hermes` | +190 | Rama de auditoría (informes/docs). Si el valor es documental → PR solo de `docs/` o mover los informes fuera del repo y borrar. |
| `baseline-v1-stable` | +3 | Tiene 132 archivos sin commitear en su worktree: **decidir y commitear** o descartar explícitamente. No borrar antes de eso. |
| `feature/saas-railway-integrated` | +0 | Tiene 142 archivos sin commitear en su worktree. Igual que la anterior. |
| `audit_glowapp_architecture_integrity` | +1 | Tiene 12 archivos sin commitear. Igual. |
| `backup/linea-base-osm-modifications` | +4 | Tiene 1 archivo sin commitear. Igual. |

**Worktrees con trabajo sin commitear — no los borres ni los podes**:
`database_audit_read_only` (142), `setup_glowguide_architecture` (132),
`audit_glowapp_architecture_integrity` (12), `startup_glowapp_antigravity` (1).
También hay **15 stashes** sin evaluar: no los toques sin decidir uno por uno.

Regla para el futuro, que es el objetivo real de la poda: **una rama por PR, y se borra al mergear**.
Sin ramas acumuladas y sin worktrees huérfanos.

---

## 6. FASE 5 — Evidencia que debes devolverme

Con etiqueta explícita, igual que en la auditoría: **[V]** = verificado ejecutando, **[L]** = leído en
archivo, **[D]** = deducido.

1. [V] `git rev-list --count origin/main..main` = 0 y el SHA de `origin/main`.
2. [V] Salida de la puerta de calidad (5 suites, 90/90) en el SHA mergeado.
3. [V] Código HTTP de `/health` y del endpoint de verificación de certificado.
4. [V] Filas de `schema_migrations` con `066` y `067` + conteo `9` módulos / `15` lecciones del curso 3.
5. [V] Resultado de la publicación de contenido (cuántas lecciones quedaron con material real).
6. [V] Si el job de retención quedó programado o no (y dónde).
7. [L] Confirmación del branch conectado en Railway y del doctor de variables del backend.
8. [V] Salida final de `git branch | wc -l` y `git ls-remote --heads origin | wc -l`.
9. Cualquier desviación de este prompt, con el error textual completo — sin parches silenciosos.

**Pendiente declarado, no incluido aquí**: quitar `@ts-nocheck` de
`admin-dashboard/src/app/(dashboard)/admin/academia/[id]/page.tsx` (1425 líneas). Merece su propia
sesión con el build en la mano; no lo mezcles con el deploy.
