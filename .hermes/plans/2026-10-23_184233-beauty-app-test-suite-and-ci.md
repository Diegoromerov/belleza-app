# Plan — Ejecutar el suite completo de beauty-app y dejar CI en verde

**Ubicación del plan:** `.hermes/plans/2026-10-23_184233-beauty-app-test-suite-and-ci.md`
**Repositorio objetivo:** `C:\beauty-app` (rama actual `feature/crm-salon`, 28 archivos con cambios sin commitear)
**Fecha:** 2026-10-23

---

## Goal

Ejecutar localmente el suite completo (Jest backend + Flutter), corregir lo que impida que pase, y dejar el workflow de GitHub Actions ejecutándose y en verde con evidencia real (números de tests y URL del run).

---

## Contexto y supuestos (verificado, no supuesto)

Estos datos se comprobaron en el repo antes de escribir el plan. Cualquiera que lo ejecute debe poder confiar en ellos sin volver a investigar.

| Hecho | Evidencia |
|---|---|
| El repo es `C:\beauty-app`, no `belleza-app-audit` | `ls /c/beauty-app` existe; el otro repo es distinto |
| `backend/src/app.js`, `backend/src/database.js`, `backend/src/models/Salon.js` existen | comprobación con `[ -f ]` → los tres EXISTEN |
| `database.js` es Sequelize con `sqlite::memory:` | 13 líneas, `new Sequelize('sqlite::memory:', { logging: false })` |
| **`sqlite3` NO está instalado** y no está declarado | `node_modules/sqlite3`, `backend/node_modules/sqlite3` → ausentes |
| `sequelize` y `winston` sí están, pero **solo en `backend/node_modules`** | resuelven desde `backend/src`, no desde la raíz (`require.resolve` desde raíz: NO RESUELVE) |
| Raíz `package.json` declara solo `jest@30.5.2` y `supertest@7.3.1` como dev | falta `sequelize`, `sqlite3`, `winston` |
| `backend/package.json` declara `jest@29.7.0` y `sequelize-cli` | versiones distintas a la raíz |
| `backend/package.json` **no tiene script `lint`** | scripts: dev, start, test, test:node, test:audit-log, migrate, ingest:rag, purge:rag, eval:rag, ci:eval, smoke:surfaces, verify:wompi, e2e:wompi:sandbox, openapi:generate, openapi:check, test:contract |
| 49 archivos de test en `backend/tests/` | `ls backend/tests \| wc -l` → 49 |
| 27 archivos de test en `frontend/test/` | `find frontend/test -name "*_test.dart" \| wc -l` → 27 |
| Flutter 3.44.0 instalado | `which flutter` → `/c/flutter/bin/flutter` |
| **`.github/workflows/ci.yml` en el árbol de trabajo está destrozado**: 51 líneas frente a 244 en `HEAD` | `git diff --stat` → `31 insertions(+), 224 deletions(-)` |
| Ese stub no puede pasar: usa `npm run lint` (no existe), `working-directory: ../../frontend` (escapa del repo), no instala Flutter y dispara en `feature/crm-salon` | lectura del archivo |
| El workflow de `HEAD` es el bueno: PostGIS, `npm ci --legacy-peer-deps`, guardas, `test:node`, OpenAPI, contrato, `prepareRlsDatabase.js`, `verifyTenantIsolation.js`, y job `frontend-ci` con `subosito/flutter-action@v2` | `git show HEAD:.github/workflows/ci.yml` |
| Triggers del workflow bueno: `push`/`pull_request` a `main` y `staging` | idem |
| **No hay `workflow_dispatch`** → no se puede lanzar a mano; hay que empujar rama o abrir PR | `grep workflow_dispatch` → sin coincidencias |

**Supuestos:** no hay PostgreSQL local escuchando en `127.0.0.1:5432`; los tests de backend usan `src/config/pgMemory.js` cuando falta `DATABASE_URL_ADMIN`. Si hubiera Postgres local, los pasos 4 y 5 pueden tomar la ruta real (el plan indica cómo detectarlo).

---

## Decisiones propuestas (y por qué)

- **D1 — Restaurar `.github/workflows/ci.yml` desde `HEAD`** (`git checkout -- .github/workflows/ci.yml`). El stub del árbol no puede pasar por cuatro motivos independientes; arreglarlo es reescribir el pipeline entero, mientras `HEAD` ya está probado. Antes de restaurar, `git diff .github/workflows/ci.yml` para confirmar que nadie metió un cambio intencional que haya que conservar.
- **D2 — La fuente de verdad local es `backend/`**, igual que CI (`working-directory: backend`). Los comandos de la raíz se usan solo para el atajo `npm test`.
- **D3 — No añadir `sqlite3` de entrada.** Los tests usan pg-mem. Solo se instala si un test falla literalmente con `Please install sqlite3 package manually` (tarea 6b).
- **D4 — `PUB_CACHE` explícito en Windows.** En esta máquina hubo fallos de `flutter pub get` por `PUB_CACHE=D:\Pub\Cache` inexistente. Se exporta a `C:/Users/Compu casa/AppData/Local/Pub/Cache` antes de cualquier comando Flutter.
- **D5 — Verificar CI con PR a `main`**, no con la rama `ci-test` que sugiere el enunciado: los triggers son `main`/`staging`, así que `git push origin HEAD:refs/heads/ci-test` no lanza nada.
- **D6 — No tocar los 28 archivos sin commitear sin revisarlos.** CI valida lo que se empuja: si se empuja con cambios a medias, el rojo será ambiguo.

---

## Arquitectura / enfoque

Dos capas con un solo origen: primero se reproduce localmente lo que hace CI (`npm ci` + `npx jest` dentro de `backend`, `flutter pub get` + `flutter test` dentro de `frontend`), se anota el baseline real de tests, y solo cuando local está verde se restaura el workflow y se dispara un run por PR. Cualquier fallo se arregla en el nivel mínimo (test, código o configuración) y se re-ejecuta **solo** el archivo afectado antes de volver al suite completo.

---

## Tareas paso a paso

Cada tarea dura 2–5 minutos. Los commits son frecuentes y con mensaje concreto.

### T1 — Congelar el estado del árbol (2 min)

```powershell
cd C:\beauty-app
git status --short | tee .hermes/plans/baseline-git-status.txt
git diff --stat | tee .hermes/plans/baseline-diffstat.txt
git branch --show-current
```

**Esperado:** rama `feature/crm-salon`, ~28 líneas de estado, `ci.yml` con `224 deletions`. Si hay archivos que no reconoces, **detente y pregunta** antes de seguir.

**Commit:** no (solo reconocimiento).

---

### T2 — Revisar el `ci.yml` del árbol y restaurar el de `HEAD` (4 min)

```powershell
cd C:\beauty-app
git diff .github/workflows/ci.yml | tee .hermes/plans/ci-yml-tree-vs-head.diff
```

**Esperado:** un diff con `-224 +31`. Si NO aparece ningún cambio intencional que haya que salvar:

```powershell
git checkout -- .github/workflows/ci.yml
git diff --stat .github/workflows/ci.yml
```

**Esperado:** sin salida (archivo idéntico a `HEAD`).

**Commit:**
```powershell
git add .github/workflows/ci.yml
git commit -m "ci: restaurar el pipeline completo (el stub local rompía lint, flutter y triggers)"
```

**Verificación de que el workflow restaurado es el bueno:**
```powershell
git show HEAD:.github/workflows/ci.yml | Select-String -Pattern "flutter-action|prepareRlsDatabase|test:node" | Measure-Object | Select-Object -ExpandProperty Count
```
**Esperado:** `3` (o más).

---

### T3 — Instalar dependencias de backend exactamente como CI (3 min)

```powershell
cd C:\beauty-app\backend
npm ci --legacy-peer-deps 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-npm-ci-backend.txt
```

**Esperado:** termina con `added N packages` y sin `npm ERR!`.

Si falla por lockfile desincronizado (`npm ci can only install packages when your package.json and package-lock.json are in sync`):

```powershell
npm install --legacy-peer-deps 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-npm-install-backend.txt
```
y **commit del lockfile**:
```powershell
git add package-lock.json
git commit -m "chore(backend): sincronizar package-lock con package.json"
```

**Verificación de módulos críticos:**
```powershell
node -e "for (const m of ['jest','supertest','sequelize','winston']) { try { require.resolve(m); console.log('OK', m) } catch { console.log('FALTA', m) } }"
```
**Esperado:** `OK` en los cuatro. Si `FALTA sqlite3` no importa todavía (ver D3).

---

### T4 — Baseline de Jest en backend (5 min)

```powershell
cd C:\beauty-app\backend
npx jest --runInBand --coverage=false 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-jest-backend.txt
```

**Esperado:** al final, un bloque tipo:

```
Test Suites: A passed, A total
Tests:       B passed, B total
Snapshots:   0 total
Time:        ...
```

**Qué anotar:** `A`, `B` y, si hay rojos, la lista `● suite › test` de `baseline-jest-backend.txt`. **No se conoce el conteo previo**: este paso lo fija como referencia; no se inventa un número.

**Si el proceso aborta por base de datos** (`ECONNREFUSED 127.0.0.1:5432`):
```powershell
$env:DATABASE_URL_ADMIN=""
$env:DATABASE_URL=""
npx jest --runInBand --coverage=false 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-jest-backend-pgmem.txt
```
Los tests deben caer a `src/config/pgMemory.js`. **Esperado:** el mismo bloque de resumen, ahora sin errores de conexión.

**Si aparecen rojos:** ir a T6 por cada uno. No seguir a T5 con rojos abiertos.

**Commit:** no (baseline).

---

### T5 — Baseline de Flutter (5 min)

```powershell
$env:PUB_CACHE="C:/Users/Compu casa/AppData/Local/Pub/Cache"
cd C:\beauty-app\frontend
flutter pub get 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-flutter-pubget.txt
flutter test 2>&1 | Tee-Object -FilePath ..\.hermes\plans\baseline-flutter-test.txt
```

**Esperado (pub get):** `Got dependencies!`
**Esperado (test):** última línea `All tests passed!` y `+N` donde N ≈ 27 archivos × casos.

**Si falla `pub get` con `Creation failed, path = 'D:\'`:** el `PUB_CACHE` no se aplicó; repetir el export en la **misma** sesión de terminal.

**Si falla `flutter test`:** copiar el bloque `Expected/Actual` de cada test rojo a `.hermes/plans/flutter-fallos.txt` y resolver en T6.

---

### T6 — Reparar cada rojo con ciclo TDD (2–5 min por rojo)

Para **cada** test rojo, en este orden estricto:

**6.1 Reproducir aislado**
```powershell
cd C:\beauty-app\backend
npx jest tests\<archivo>.test.js --runInBand --coverage=false
```
**Esperado:** falla con el mismo mensaje que en el baseline.

**6.2 Clasificar el fallo** (una de tres):
- **Test obsoleto** (espera un contrato que el código ya cambió) → corregir el test, nunca el comportamiento.
- **Bug real** → escribir primero el caso mínimo que lo demuestra (ya lo es el test rojo), luego el arreglo mínimo en `backend/src/...`.
- **Entorno** (`Cannot find module`, `ECONNREFUSED`, `Please install sqlite3 package manually`) → corregir dependencia o variable, no el test.

**6.3 Si el fallo es `Please install sqlite3 package manually`** (único caso que autoriza D3):
```powershell
cd C:\beauty-app\backend
npm install --save-dev sqlite3 --legacy-peer-deps
node -e "require('sqlite3'); console.log('sqlite3 OK')"
git add package.json package-lock.json
git commit -m "test(backend): añadir sqlite3 para el Sequelize en memoria de database.js"
```

**6.4 Verificar el aislado**
```powershell
npx jest tests\<archivo>.test.js --runInBand --coverage=false
```
**Esperado:** `Tests: N passed, N total` sin `failed`.

**6.5 Commit del arreglo**
```powershell
git add -A
git commit -m "fix(<área>): <qué> — <test que lo cubre>"
```

**6.6 Volver al suite** (T4) y confirmar que el total de rojos bajó. Repetir hasta `0 failed`.

---

### T7 — Suite completo tal como lo pide el enunciado (3 min)

```powershell
cd C:\beauty-app
npm run test:backend 2>&1 | Tee-Object -FilePath .hermes\plans\run-test-backend.txt
```
**Esperado:** mismo resumen que T4 (`0 failed`).

```powershell
$env:PUB_CACHE="C:/Users/Compu casa/AppData/Local/Pub/Cache"
npm test 2>&1 | Tee-Object -FilePath .hermes\plans\run-npm-test.txt
```
**Esperado:** primero el resumen de Jest, después `All tests passed!` de Flutter. Código de salida `0`:
```powershell
echo "exit=$LASTEXITCODE"
```

**Nota importante:** la raíz usa `jest@30` y su propio `jest.config.js` (roots `backend` + `frontend`), mientras CI usa `jest@29` dentro de `backend`. Si `npm run test:backend` da resultados **distintos** a T4, la causa es la versión de Jest, no el código. En ese caso (y solo en ese) alinear la raíz con CI:

```json
// package.json (raíz) — reemplazar el bloque scripts
"scripts": {
  "test:backend": "cd backend && npx jest --runInBand --coverage=false",
  "test": "npm run test:backend && cd frontend && flutter test",
  "seed": "node run_seed.js"
}
```
**Verificación:** `npm run test:backend` debe imprimir exactamente el mismo `Tests: B passed` que T4.

**Commit (si se cambió `package.json`):**
```powershell
git add package.json
git commit -m "chore(test): delegar test:backend al jest de backend para que local y CI midan lo mismo"
```

---

### T8 — Revisar y cerrar los 28 cambios pendientes (5 min)

```powershell
cd C:\beauty-app
git status --short
git diff --stat
```
**Esperado:** decidir por cada archivo: se commitea (con mensaje propio) o se descarta (`git checkout -- <archivo>`). **No se empuja nada a medias**: CI valida el árbol empujado, no el local.

**Commit por grupo lógico**, por ejemplo:
```powershell
git add backend/index.js backend/src/models/index.js
git commit -m "feat(backend): <qué cambia y por qué>"
```

---

### T9 — Disparar CI por PR a `main` (3 min)

```powershell
cd C:\beauty-app
git push origin HEAD:refs/heads/ci/verify-suite
gh pr create --base main --head ci/verify-suite --title "ci: verificar suite completo en verde" --body "Ejecuta el pipeline restaurado sobre el suite completo (Jest backend + Flutter). Evidencia local en .hermes/plans/run-*.txt."
```
**Esperado:** `gh` imprime la URL del PR.

```powershell
gh pr checks --watch
```
**Esperado:** cada check pasa a `pass`; el job `Backend Tests & Lint` tarda varios minutos (levanta PostGIS, migra, corre RLS).

**Si un check falla:**
```powershell
gh run view --log-failed | Tee-Object -FilePath .hermes\plans\ci-fallos.txt
```
Leer la primera línea `::error::`, corregir, `git commit`, `git push` (el PR re-dispara solo) y volver a `gh pr checks --watch`.

---

### T10 — Reporte final (2 min)

Responder con una de dos formas, **sin adornos**:

- **Todo verde:**
  > Todas las pruebas pasaron exitosamente.
  acompañado de: conteo de Jest (`Test Suites`/`Tests`), conteo de Flutter (`+N`), y la URL del run de CI.

- **Algo rojo:** pegar la salida del comando que falló (bloque `Tests:`/`●` o el `::error::` del run) y adjuntar la ruta del log guardado en `.hermes/plans/`.

---

## Tests y validación

| Nivel | Comando | Criterio de aceptación |
|---|---|---|
| Jest aislado | `npx jest tests/<archivo>.test.js --runInBand --coverage=false` | `N passed`, `0 failed` |
| Jest completo | `npx jest --runInBand --coverage=false` (en `backend/`) | `0 failed` y conteo registrado |
| Atajo raíz | `npm run test:backend` | mismo `Tests: B passed` que el anterior |
| Flutter | `flutter test` (en `frontend/`, con `PUB_CACHE`) | `All tests passed!`, exit 0 |
| Suite encadenado | `npm test` (raíz) | Jest verde **y** `All tests passed!`, exit 0 |
| CI | `gh pr checks --watch` | todos los checks en `pass`; URL del run adjunta |

**Ciclo TDD obligatorio en T6:** test rojo aislado → fallo reproducido → arreglo mínimo → test verde aislado → suite completo → commit. Nunca se arregla un rojo sin haberlo visto fallar aislado primero.

---

## Riesgos, tradeoffs y preguntas abiertas

1. **El `ci.yml` del árbol podría ser intencional.** Si al revisar el diff (T2) aparece un cambio deliberado (p. ej. correr solo backend por velocidad), la decisión correcta es portarlo al workflow restaurado, no descartarlo. **Pregunta para el dueño del repo:** ¿el recorte de `ci.yml` fue un intento de acelerar CI en `feature/crm-salon`?
2. **Los 28 archivos sin commitear** incluyen `backend/index.js`, `backend/src/models/index.js`, un test modificado y una plantilla borrada. Si CI falla, puede ser por ellos y no por el suite. Mitigación: T8 antes de T9.
3. **Sin `workflow_dispatch`** no hay botón de "run manual": siempre implica rama/PR. Si se quiere botón, hay que añadir `workflow_dispatch:` al `on:` (cambio pequeño, pero requiere commit).
4. **Postgres local**: si aparece `ECONNREFUSED`, T4 usa pg-mem. Eso valida menos que CI (que corre PostGIS real). El run de CI es la única prueba de la ruta con base real.
5. **Dos versiones de Jest** (30 raíz / 29 backend) es una bomba de tiempo: mismo test, distinto resultado. T7 lo resuelve delegando en el de backend.
6. **`sqlite3` ausente**: hoy no bloquea porque los tests usan pg-mem, pero `backend/src/database.js` queda inservible fuera de tests. Añadirlo (T6.3) solo si aparece el error; declararlo en `package.json` es deuda recomendable.
7. **Tiempo de CI**: el job de backend levanta PostGIS + migraciones + RLS; 8–15 min es normal. No asumir cuelgue antes de los 20 min.
8. **Coste de `--runInBand`**: más lento localmente pero evita colisiones de pg-mem entre workers. Es lo que hace CI.

---

## Orden de ejecución (checklist)

- [ ] T1 baseline del árbol
- [ ] T2 revisar y restaurar `ci.yml` (+ commit)
- [ ] T3 `npm ci` backend (+ commit si cambia el lock)
- [ ] T4 baseline Jest backend
- [ ] T5 baseline Flutter
- [ ] T6 reparar rojos uno por uno (+ commit por arreglo)
- [ ] T7 `npm test` completo (+ commit si se alinea `package.json`)
- [ ] T8 cerrar los 28 cambios pendientes (+ commits)
- [ ] T9 PR a `main` y `gh pr checks --watch`
- [ ] T10 reporte con evidencia
