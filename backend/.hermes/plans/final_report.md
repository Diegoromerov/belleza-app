# Reporte final — validación de la suite y despliegue de CI

**Proyecto:** beauty-app (`C:\beauty-app`)
**Rama:** `ci/verify-suite` · **Head:** `13080625e`
**PR:** https://github.com/Diegoromerov/belleza-app/pull/64 — **OPEN**, `MERGEABLE`, `mergeStateStatus: CLEAN`
**Fecha:** 2026-10-24

---

## Resultado en una tabla (ANTES → DESPUÉS)

| Suite | ANTES | DESPUÉS | Exit |
|---|---|---|---|
| **Jest backend** | 4 suites rojas / 17 tests rojos (1.482 passed) · 1.150 s | **0 rojos** · 189 suites passed + 1 skipped (190) · **1.501 tests passed**, 8 skipped (1.509) · 604 s | **0** |
| **Flutter** | +110 passed / −7 (7 goldens) | **+146 passed / −7** (los mismos 7 goldens) | 1 (goldens aceptados) |

Baseline histórico de la sesión anterior sobre `feature/crm-salon`: 26 suites rojas / 20 tests rojos. Ese estado era el punto de partida real del trabajo, pero no es comparable archivo a archivo con esta rama; por eso la tabla usa el primer run de esta sesión como ANTES.

Los 7 fallos de Flutter son exclusivamente de golden (`phase5_goldens_test.dart`: Booking pasos 1-3 y ProviderDetail) y se asumen **aceptados** según la instrucción: no se modificó código de UI ni se regeneraron los PNG.

---

## Pasos ejecutados

### 1. Limpieza e instalación del backend

```powershell
taskkill /F /IM node.exe        # no había procesos node vivos
Remove-Item -Recurse -Force C:\beauty-app\backend\node_modules
New-Item -ItemType Directory -Path C:\beauty-app\backend\node_modules
cd C:\beauty-app\backend
npm ci --legacy-peer-deps
```

**Resultado:** `added 872 packages, and audited 873 packages in 2m` · **exit 0**.
**Vulnerabilidades registradas (no se actualizó nada):** `31 vulnerabilities (5 low, 11 moderate, 14 high, 1 critical)`.
Log completo: [npm_ci_backend.txt](../../../.hermes/plans/npm_ci_backend.txt).

### 2. Jest backend

Script usado: `backend/.hermes/tmp/run_jest.bat` (mantiene `JWT_SECRET=ci_secret`, `NODE_ENV=test` y redirección a `backend/.hermes/plans/jest_backend_output.txt`).

Ajustes necesarios en el script (documentados en el propio `.bat`):

| Ajuste | Motivo medido |
|---|---|
| `set "PATH=C:\Program Files\Git\bin;%PATH%"` | `ciRagEvaluation.test.js` ejecuta `bash -n`; sin Git Bash en PATH, Windows resuelve `bash.exe` a WSL, que no entiende `C:/...` y la suite da 2 rojos. |
| `--maxWorkers=2` en vez de `--runInBand --detectOpenHandles` | Con ~190 suites en un solo proceso, los timers/cron/pools de cada suite se acumulan: medido **1.450 s y 3 rojos falsos** (timeouts de 30 s y SLAs de 315/414 ms). Con 2 workers: **185-604 s y 0 rojos**, en línea con lo que hace CI por defecto. |

**Run final:** `Test Suites: 1 skipped, 189 passed, 189 of 190 total` · `Tests: 8 skipped, 1501 passed, 1509 total` · `Time: 603.862 s` · **exit 0** · 0 líneas `FAIL`.
Log: [jest_backend_output.txt](jest_backend_output.txt) · Código: [jest_exit_code.txt](../../../.hermes/plans/jest_exit_code.txt).

### 3. Flutter

```powershell
cd C:\beauty-app\frontend
flutter test
```

**Resultado:** `+146 -7: Some tests failed.` · **exit 1**.
Los 7 rojos son golden tests (ver arriba), aceptados sin tocar código.
Log: [flutter_test_output.txt](../../../frontend/.hermes/plans/flutter_test_output.txt) · Código: [flutter_exit_code.txt](../../../frontend/.hermes/plans/flutter_exit_code.txt).

### 4. PR #64

- Estado inicial: **CLOSED**, `mergeable: CONFLICTING`, base `main`.
- `gh pr reopen 64` → OPEN.
- `git merge main` → 4 conflictos, resueltos **tomando la versión de `main`** porque ya contiene los mismos arreglos, más nuevos (PRs #65, #66, #67):
  - `backend/src/services/auraToolExecutor.js`
  - `backend/src/services/biometricCryptoService.js`
  - `backend/src/tests/auraToolExecutor.test.js`
  - `backend/src/tests/geminiFallback.test.js`
- Al avanzar `main` (#67), segundo `git merge origin/main` (sin conflictos).
- `git push origin ci/verify-suite` → `6acd71ca1..13080625e`.

Commit de test añadido en la rama (9 líneas, revisable): warm-up en el test de SLA de consentimiento. La primera petición mide el arranque perezoso de pg-mem (600-1.000 ms en Windows), no el endpoint; con el calentamiento la medición estable queda en ~85-100 ms y el caso deja de ser un falso rojo por entorno. No cambia API ni lógica de negocio.

### 5. CI de GitHub Actions

El workflow `.github/workflows/ci.yml` se dispara solo con `push`/`pull_request` a `main`; no requiere `workflow_dispatch`. El push del head final disparó los 5 workflows.

**Run principal (GlowApp CI / CD Pipeline):** [40119059850](https://github.com/Diegoromerov/belleza-app/actions/runs/40119059850) — **success**
- `Backend Tests & Lint`: pass (1 m 40 s)
- `Frontend Flutter Analyze & Build Check`: pass (1 m 42 s)

URL guardada en [ci_run_url.txt](ci_run_url.txt).

**Estado de todas las checks del PR** ([pr_checks.txt](pr_checks.txt)):

| Check | Estado |
|---|---|
| Backend Tests & Lint | **pass** |
| Frontend Flutter Analyze & Build Check | **pass** |
| Arnés E2E (reglas del dinero) | **pass** |
| Unit Tests (Core) / Lint & Type Check | **pass** |
| DevOps Multi-Agent Audit (ORQ, SEC, DATA, OBS, REL, SUP, CICD) | **pass** |
| Railpack deploy (Railway, `belleza-app-pr-64`) | **pass** |
| Deploy Gate / Integration Tests (RAG) / Update Baseline | skipping (condicionales por diseño en PR) |

`gh pr view 64` final: `state: OPEN`, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`.

Nota: en el head intermedio `6acd71ca1` falló el E2E en el paso «Restaurar el esquema base»; tras mergear `main` (que incluye el fix del enum de `estado_cita`, PR #67) el rerun pasó en 50 s. No hizo falta tocar nada del arnés E2E.

---

## Cambios en el repositorio (revisables)

```
13080625e Merge remote-tracking branch 'origin/main' into ci/verify-suite
6acd71ca1 test(biometric): calentar pg-mem antes de medir el SLA de consentimiento
81b03736f Merge branch 'main' into ci/verify-suite
```

Diff neto contra `main`: `package.json` (scripts `test`/`test:backend` + devDependencies de test), `package-lock.json` y el test de biometría (+9 líneas). No se tocaron `main`, la API, el backend de negocio, pagos, ni el theme.

---

## Riesgos y notas abiertas

1. **31 vulnerabilidades npm** quedan registradas sin corregir: `npm audit fix` podría romper la API y la regla del contrato es no actualizar versiones por ello.
2. **Goldens de Flutter:** 7 diferencias asumidas como aceptadas; CI solo ejecuta `flutter analyze`, no `flutter test`, por lo que no bloquean el PR.
3. **`run_jest.bat`** vive en `backend/.hermes/tmp/` (untracked) y ahora usa `--maxWorkers=2`; se documenta aquí para que la evidencia sea reproducible.
4. **Evidencia untracked:** `backend/.hermes/` y `.hermes/plans/` no forman parte del PR; son artefactos locales de verificación.
