# Automatización y agentes en el repositorio — inventario y huecos

**Fecha:** 2026-10-24 · **Rama:** `feature/salon-redesign` · **HEAD:** `ce708d999`
**Árbol:** 43 entradas sin commitear (no afectan a las rutas citadas, pero impiden reproducir el estado exacto)
**Método:** lectura directa de `.github/workflows/`, `package.json`, `.hermes/`, `docs/agents/`, `.ui-audit/`, `backend/scripts/` y `grep` sobre el árbol. Cada afirmación lleva el archivo que la sostiene; lo que no se pudo medir aparece como *no verificado*.

---

## 0. Resumen en una frase

El repositorio tiene **una capa de CI real y bastante densa**, **una capa de agentes documentada pero detenida en el paso de detección**, y **cuatro puntos de entrada de automatización que llaman a scripts npm que no existen** — por lo que varios gates verdes/rojos de hoy no significan lo que dicen.

---

## 1. Lo que ya corre solo (sin humano)

| Proceso | Disparador | Qué hace | Evidencia |
|---|---|---|---|
| **CI backend** | push/PR a `main`, `staging` | 8 compuertas bloqueantes: marcadores de conflicto, secretos versionados, numeración de migraciones, guardas `node:test`, contrato OpenAPI, tests de contrato, esquema RLS + aislamiento multi-tenant, gate de jest | [ci.yml](<.github/workflows/ci.yml>) L44-221 |
| **CI frontend** | push/PR | `flutter pub get` + `flutter analyze` (sin build) | [ci.yml](<.github/workflows/ci.yml>) L223-244 |
| **E2E reglas del dinero** | PR que toca `backend/**` + manual | PostGIS efímero, restaura esquema, siembra, arranca backend, corre el arnés (split, propina, cancelación, IVA) | [e2e-reglas.yml](<.github/workflows/e2e-reglas.yml>) L9-135 |
| **Evaluación RAG** | push/PR en rutas RAG + **cron diario 03:00 UTC** + manual | lint/sintaxis, unit tests, (integración solo manual), comparación contra baseline, quality gates, comentario en PR | [rag-evaluation.yml](<.github/workflows/rag-evaluation.yml>) L3-23, L45-224 |
| **Actualización de baseline RAG** | `main` + manual | copia `eval_report.json` → `baseline_metrics.json` y **commitea y pushea solo** | [rag-evaluation.yml](<.github/workflows/rag-evaluation.yml>) L228-255 |
| **Deploy gate** | push a `main` | verifica gates y dispara `RAILWAY_DEPLOY_HOOK` | [rag-evaluation.yml](<.github/workflows/rag-evaluation.yml>) L260-277 |
| **Auditoría DevOps multi-agente** | PR + manual | 6 auditores en paralelo (gitleaks, actionlint, Dockerfiles, npm audit, pub outdated, configs release) → JSON de hallazgos → consolidación | [devops-audit.yml](<.github/workflows/devops-audit.yml>) L22-351 |
| **Despliegue** | push a `main`/`staging` | Railway despliega por rama según config-as-code | [railway.yml](<railway.yml>) L120-135 |

**Y lo que no existe** (búsqueda explícita, no supuesto): `.github/dependabot.yml`, `renovate.json`, `.pre-commit-config.yaml`, `.husky/`, `commitlint`. Los hooks de `.git/hooks/` son todos `.sample` y `core.hooksPath` no está definido: **no hay automatización en el momento del commit**.

---

## 2. Lo que es asistido por agentes (no automático)

### 2.1 Sistema de agentes de desarrollo — [docs/agents/SISTEMA.md](<docs/agents/SISTEMA.md>)

Cinco roles: **Arquitecto** (Hermes, planifica y audita), **Ejecutor** (Antigravity, una orden = una rama = un PR), **Auditor** (Hermes, sonda propia), **Guardián** (scripts sin LLM) y **Dueño** (Diego, mergea y decide dinero/seguridad/producción).

Ciclo: `ORDEN → rama + test que primero falla → PR → Guardián → Auditoría → merge humano`. Reglas duras que impiden el cierre automático: ningún fix sin rojo previo, ningún veredicto sin procedencia, **los agentes no mergean, no borran ramas del remoto y no reescriben historia** (§4 reglas 2, 6, 7).

Estado real de la cola: [COLA.md](<docs/agents/COLA.md>) muestra órdenes cerradas con rondas numeradas (O-014, A-07, A-08), varias **pendientes de la firma del Dueño** y una bloqueada por "aprobación no entregable al cliente".

### 2.2 Protocolo DevOps de 7 pasos — [.hermes/skills/devops-agents/](<.hermes/skills/devops-agents/devops-orq.md>)

9 skills (ORQ, SEC, CICD, DATA, OBS, SUP, REL, FIX, VER) con presupuesto de tokens por agente y regla objetiva de "alto riesgo" (auth, pagos, migraciones, RLS, railway, backups) que obliga a revisión externa.

**Pero el ciclo nunca se cerró**: [REGISTRO-HALLAZGOS.md](<.hermes/devops/REGISTRO-HALLAZGOS.md>) tiene 36 hallazgos y **todos en estado `Detectado`**; columnas VER, decisión, PR y merge vacías. [ESTADO-SISTEMA.md](<.hermes/devops/ESTADO-SISTEMA.md>) confirma: 0 tokens usados, auditorías "Pendiente", 0 PRs, **Compuerta 3 bloqueada**.

### 2.3 Design Director (UI) — [.ui-audit/config.yaml](<.ui-audit/config.yaml>)

10 fases (`discover → static_audit → runtime_capture → diagnose → proposal → worktree_implementation → after_capture → visual_compare → regression_check → patch_export`) con tres candados explícitos: `require_evidence`, `require_before_capture`, `patch.apply_automatically: false` y `never_claim_user_test_results: true`. Salidas existentes: 2 parches y 1 informe en [.ui-audit](<.ui-audit/reports/design-director.md>).

### 2.4 gstack y el catálogo de skills

[CLAUDE.md](<CLAUDE.md>) invoca `/review`, `/qa`, `/ship`, `/land-and-deploy`… de `gstack/` (repo propio, invocación manual). [.agent/skills/](<.agent/skills>) contiene ~1.400 skills vendorizadas: es un **catálogo**, no automatización del producto, y conviene sacarlo del árbol de trabajo (no aporta a CI y engorda clones).

---

## 3. Automatización declarada que no funciona (hallazgos verificados)

| # | Qué se rompe | Evidencia | Efecto |
|---|---|---|---|
| **H-01** | `ci.yml` ejecuta `npm run test:node`; `backend/package.json` solo define `test:backend`, `seed`, `test` | [ci.yml](<.github/workflows/ci.yml>) L93 · [backend/package.json](<backend/package.json>) L6-10 | `npm` sale 1 ("Missing script") ⇒ **paso bloqueante rojo siempre**, y las guardas `*.nodetest.js` (existen 3) nunca corren |
| **H-02** | `ci.yml` ejecuta `npm test` dentro de `backend/`, pero ese script es `cd frontend && flutter test` y `backend/frontend` no existe | [ci.yml](<.github/workflows/ci.yml>) L189, L221 · [backend/package.json](<backend/package.json>) L9 | El "gate de 592 tests" no ejecuta jest: ejecuta un `cd` imposible |
| **H-03** | `e2e-reglas.yml` llama `npm run e2e` (inexistente) y restaura `backend/scripts/e2e/schema-base.sql` (el archivo vive en `backend/tests/`; `backend/scripts/e2e/` está vacío) | [e2e-reglas.yml](<.github/workflows/e2e-reglas.yml>) L83, L119 | El arnés de reglas del dinero **no corre**, justo el que encontró IVA duplicado y reprogramación infinita |
| **H-04** | `rag-evaluation.yml` llama `npm run lint` con `|| echo "No lint script configured"` | [rag-evaluation.yml](<.github/workflows/rag-evaluation.yml>) L67 | Puerta que no distingue "no corrió" de "limpio" (ya registrado como CICD-07) |
| **H-05** | `devops-fix.yml` no corrige nada: paso titulado "Aplicar corrección (placeholder)" | [devops-fix.yml](<.github/workflows/devops-fix.yml>) L53-56 | El eslabón FIX del protocolo es decorativo: commit sin cambios ⇒ `gh pr create` falla |
| **H-06** | `devops-ver.yml` captura el exit de `tee`, no del comando; y trata `exit ≠ 0` como "hallazgo posiblemente corregido" ⇒ FAIL | [devops-ver.yml](<.github/workflows/devops-ver.yml>) L49-50, L58-69 | El verificador independiente emite veredicto invertido en el caso más probable |
| **H-07** | `gitleaks` corre sin `continue-on-error` en un `run:` de bash con `-e`; el `echo exit_code=$?` posterior nunca se ejecuta | [devops-audit.yml](<.github/workflows/devops-audit.yml>) L91-105 | Cuando hay secreto, el job muere y **el generador de hallazgos nunca se dispara** |
| **H-08** | La consolidación hace `git commit && git push` dentro de un workflow disparado por PR, y encadena 6 jobs sin `if: always()` | [devops-audit.yml](<.github/workflows/devops-audit.yml>) L326-351 | Push falla en PRs sin permiso de escritura; una auditoría roja cancela la consolidación de todas |
| **H-09** | Los jobs OBS y DATA leen `backend/src/index.js`, que no existe (el entry es `backend/index.js`) | [devops-audit.yml](<.github/workflows/devops-audit.yml>) L177-217 | `cat`/`sed` fallan antes de generar hallazgos |
| **H-10** | Sin Dependabot/Renovate, sin SBOM, sin `npm audit` bloqueante | verificado por ausencia de archivos | SUP-01 sigue abierto |
| **H-11** | Ningún workflow fija actions por SHA; `ci.yml` no tiene `concurrency` | [ci.yml](<.github/workflows/ci.yml>) L1-8 | Reruns apilan runners y se cancelan entre sí (CICD-04) |
| **H-12** | No hay build ni firma de Flutter en CI; el artefacto web se versiona a mano en `backend/public/main.dart.js` | FL-01…FL-05 en [REGISTRO-HALLAZGOS.md](<.hermes/devops/REGISTRO-HALLAZGOS.md>) | Releases manuales, acoplamiento frontend↔backend |
| **H-13** | El `cron` semanal del Guardián se administra **fuera del repo** | [SISTEMA.md](<docs/agents/SISTEMA.md>) §1 "Gobernanza" | No verificable ni reproducible desde el repositorio |
| **H-14** | Backup y drill de restauración existen como cron de sistema (`/opt/glowapp`, `sudo`) | [backup.cron](<scripts/backup.cron>) | Sin instalación no hay respaldo; nada en CI lo prueba |
| **H-15** | El único "deploy gate" vive en `rag-evaluation.yml`, que solo se dispara si cambian rutas de RAG; `railway.yml` declara la rama pero ningún paso exige CI verde antes del deploy | [railway.yml](<railway.yml>) L120-123 · [rag-evaluation.yml](<.github/workflows/rag-evaluation.yml>) L6-11, L260-277 | El despliegue es automático pero no está condicionado al verde (si Railway espera checks es un ajuste de dashboard, *no verificado en el repo*) |

> **Hipótesis, no hecho:** si H-01 y H-02 están rojos en el runner, el "CI verde" que [POLITICA-GIT.md](<docs/POLITICA-GIT.md>) §6 exige como condición de merge no existe hoy. La afirmación es deducible de los archivos, pero **no se verificó contra un run real** en esta revisión.

---

## 4. Qué podría automatizarse, por orden de retorno

### P0 — desbloquean todo lo demás (horas, riesgo bajo)

| Proceso | Propuesta | Archivo |
|---|---|---|
| Entradas npm fantasma | Añadir `"test:node": "node --test src/tests/*.nodetest.js"`, `"e2e": "node tests/reglas.js"`, `"lint": "eslint ."` y corregir `"test": "jest"` | [backend/package.json](<backend/package.json>) |
| Rutas del arnés E2E | Mover `schema-base.sql`/`seed-ci.sql` a `backend/scripts/e2e/` (o corregir las rutas) | [e2e-reglas.yml](<.github/workflows/e2e-reglas.yml>) L83 |
| Verificador (VER) | Veredicto por `exit code` del `evidence_cmd` (0 = corregido) sin `grep` de `impact`; `set -o pipefail` | [devops-ver.yml](<.github/workflows/devops-ver.yml>) |
| Consolidación | Quitar el `git push`; publicar artefacto + comentario en el PR | [devops-audit.yml](<.github/workflows/devops-audit.yml>) L346-351 |

### P1 — cierran huecos de seguridad y fiabilidad (días)

1. **Dependabot/Renovate** (npm, pub, pip, Docker, actions) + **SBOM `syft`** + `npm audit --omit=dev` bloqueante ⇒ cierra SUP-01.
2. **Smoke post-deploy automático**: `workflow_run` sobre el deploy de Railway que compare `/api/health` con el SHA desplegado (hoy es paso 5 manual del checklist de merge).
3. **Dividir `/healthz` y `/ready`** y alertar (INF-04: hoy `/api/health` hace `setval` y miente 200 con la base caída).
4. **Backup como workflow programado** + drill mensual automatizado (los scripts `db_backup.sh`, `db_restore_test.sh` ya existen y están probados; solo falta el disparador en CI y el destino).
5. **Poda de ramas** (O-003/O-004): `branchTriage` + `checkAlignment` + job semanal, con la caducidad 5/14 días que ya está escrita en [ramas.md](<docs/policies/ramas.md>).

### P2 — producto y release (semanas)

6. **Flutter release**: `subosito/flutter-action` + keystore desde secrets + `flutter build appbundle/ipa` + `version: x.y.z+${{ github.run_number }}` + Fastlane para internal testing. (FL-01…FL-04)
7. **Gate visual de UI**: golden tests/screenshots en CI para `ProviderDetailScreen` y `BookingScreen`; sustituye la captura manual del Design Director por una comparación reproducible.
8. **`openapi:check` en el cliente**: el contrato ya se regenera y compara en backend; extenderlo a un cliente Dart generado evita deriva silenciosa.
9. **Runner único de migraciones + `schema_migrations`** (DAT-02): hoy conviven arranque y knex con 15 duplicados congelados.

### FIX con LLM: cómo sí tendría sentido

El `devops-fix.yml` actual promete corregir y no corrige. La versión realista y auditable es **"propuesta de parche"**: el agente genera un `diff` + comandos de verificación como artefacto, abre un **PR draft** y nunca aplica sobre `main` ni mergea — exactamente el contrato que ya exige [AGENTS.md](<AGENTS.md>) (parches independientemente revisables) y el que [.ui-audit/config.yaml](<.ui-audit/config.yaml>) ya implementa con `apply_automatically: false`.

---

## 5. Lo que no conviene automatizar (o solo con firma humana)

- **Merge a `main`** — prohibido por [SISTEMA.md](<docs/agents/SISTEMA.md>) §4 regla 6-7 y por [AGENTS.md](<AGENTS.md>) regla 1.
- **Rotación de secretos y purga de historial** (SEC-01): irreversible sobre 2.481 refs.
- **Backfill de `tenant_id`** (DAT-01) y cualquier migración destructiva.
- **Cobro real / Wompi** (SEC-05): hay un simulador que marca `paid` sin verificación.
- **Decisiones de tenancy y RLS** (D001): cambian el modelo de datos de todos los clientes.
- **Aprobación de diseño**: el propio contrato del Design Director lo prohíbe.

---

## 6. Cómo verificar este informe (comandos)

```bash
# 1. Los scripts npm que los workflows invocan existen?
node -e "console.log(Object.keys(require('./backend/package.json').scripts))"

# 2. El esquema del arnés está donde el workflow lo busca?
ls backend/scripts/e2e/ ; ls backend/tests/schema-base.sql

# 3. El verificador captura el exit correcto?
grep -n "tee\|exit_code\|VERDICT" .github/workflows/devops-ver.yml

# 4. Estado real del ciclo de agentes
grep -c "Detectado" .hermes/devops/REGISTRO-HALLAZGOS.md

# 5. Automatización de dependencias / hooks
ls .github/dependabot.yml renovate.json .pre-commit-config.yaml 2>/dev/null ; git config --get core.hooksPath
```
