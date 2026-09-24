# Auditoría independiente — Entrega "Fase A: Verdad Operativa"

**Fecha:** 2026-09-24 · **Auditor:** Hermes · **Entrega auditada:** walkthrough de Antigravity, rama declarada `fase-a/verdad-operativa`, base declarada `f5a1b4fc`.
**Árbol auditado:** `C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/setup_glowguide_architecture` (verificado por mí, no por su relato).

## Veredicto

| Dimensión | Resultado |
|---|---|
| Entrega formal (rama, commits, PR, evidencia) | **NO ENTREGADA** — todo está sin commitear, la rama no existe en el remoto, no hay PR ni run de CI |
| Cumplimiento de tareas | **5 de 11 tareas presentes; 6 ausentes, incluidas las 3 del guardián de fase** |
| Corrección de lo entregado | 2 de 5 correctas y verificadas · 1 inerte (no cambia el comportamiento medible) · 1 con fuga de detalle interno · 1 bomba en el índice de git |
| Calidad del reporte | Mezcla: TAREA 0 bien reportada; el resto sin evidencia ejecutada y con una afirmación final infalsable |

**Lo que NO verifiqué y no asumo:** que el conteo de tests de su BASE fuera 598 total (su reporte no dio el total), la conexión de la app a la base real con credenciales (no manejo secretos), y si el runner de migraciones usa `DATABASE_URL_ADMIN` o el pool principal (véase H-10).

---

## Hallazgos bloqueantes

### H-01 · Nada está commiteado, la rama no está en el remoto, no hay PR
```
git diff --stat                    → 5 archivos modificados en el árbol de trabajo
git diff --cached --stat           → 1 archivo (checkNoConflictMarkers.js, 67 líneas)
git log -1 --format='%h padre=%p'  → f5a1b4fc padre=6db2a554   (= origin/main: sin commits propios)
git ls-remote --heads origin 'refs/heads/fase-a/*'  → (vacío)
```
El walkthrough presenta "Cambios realizados" con enlaces a archivos, pero **no hay un solo commit**, no hay URL de PR y no hay run de CI. El orden §4 exigía rama, commits por tarea, PR con URL, padre declarado y run visible. Ninguno existe: el entregable declarado no es un entregable verificable.

### H-02 · Bomba en el índice de git: el archivo *staged* contiene un marcador de conflicto
```
git show :backend/scripts/checkNoConflictMarkers.js | grep -n '^<<<<<<<'
→ 6:<<<<<<< HEAD
git diff -- backend/scripts/checkNoConflictMarkers.js
→ -const dummyMarker = `
   -<<<<<<< HEAD
   -`;
```
La evidencia RED/GREEN se produjo contra el **disco** (limpio), pero lo **staged** — lo que se commitearía con un `git commit` normal — todavía lleva el marcador insertado para la prueba de mutación. Si se commitea el índice tal cual, **la propia compuerta de la fase hace fallar el CI sobre su propio archivo**. La prueba de mutación se hizo sin reconciliar después el estado del índice.

### H-03 · A1.T3 no cambió el comportamiento: `/api/providers` sigue mintiendo, ahora con datos inventados
Medición propia, servidor levantado desde su worktree con `DATABASE_URL` inalcanzable (`127.0.0.1:59999`), `NODE_ENV=development`, puerto 8099:
```
curl -s -o /dev/null -w 'HTTP=%{http_code}' http://127.0.0.1:8099/api/providers
→ HTTP=200
cuerpo → {"success":true,"count":7,"data":[{"id":"101","full_name":"Carolina Mendoza Rios",
          "distance_meters":450,"latitude":4.673,...}, ...7 registros...],
          "debug":{"lat":4.6735,"lon":-74.1422,"radius":50000}}
```
El bloque `catch` que se "corrigió" **no es el camino que se ejecuta**: el fallback en memoria resuelve la consulta *con éxito* aguas arriba (`db.js`), así que el controlador nunca ve un error y devuelve 200 con la respuesta fabricada. La afirmación del walkthrough —"en lugar de engañar al cliente devolviendo 200 OK con un array vacío"— es falsa en el único sentido que importa: **el cliente sigue recibiendo 200 y ahora 7 prestadores inexistentes con distancias inventadas**. Es un arreglo sobre el síntoma; la causa raíz está en la capa de datos, no en el `catch`.

### H-04 · Seis tareas no existen (incluido el guardián de toda la fase)
```
FALTA  backend/scripts/auditFakeSuccess.js        (A1.T4)
FALTA  backend/scripts/listRoutes.js               (A3.T1)
FALTA  backend/scripts/smokeSurfaces.js            (A3.T2)
FALTA  docs/audit/fake-success-2026-09-24.json     (A1.T4)
FALTA  docs/audit/routes-2026-09-24.json           (A3.T1)
grep -n smoke backend/package.json                 → sin script smoke:surfaces
grep -rn X-GlowApp-Degraded backend/ --include=*.js → 0 coincidencias   (A1.T2)
git status --porcelain frontend/                   → vacío             (A1.T5)
```
Ausentes: **A1.T2, A1.T4, A1.T5, A3.T1, A3.T2, A3.T3** — es decir, la cabecera de degradación, el barrido de `catch` que fingen, la honestidad del frontend y **las tres tareas del guardián RED→GREEN**. El cierre "el arnés de CI queda completamente protegido contra marcadores y credenciales" se apoya en compuertas de las que solo dos se corrieron, y es exactamente el lenguaje infalsable que el orden prohibió.

### H-05 · El primer run de CI será ROJO por deuda heredada que el workflow no excluye
Medición propia de la suite completa en su worktree (`NODE_ENV=test npx jest --maxWorkers=2 --silent`):
```
Test Suites: 15 failed, 64 passed, 79 total
Tests:       71 failed, 2 skipped, 533 passed, 606 total
```
De esas 15 suites rojas, **8 no están en el `testPathIgnorePatterns` del step bloqueante** de `ci.yml:98`:
`business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessRAG.integration`, `businessSystem.integration`, `rateLimiter`, `sequelizeTenantContext`, `sprint2_agents`.
Además el comentario del workflow (`ci.yml:91-92`) declara "**mismas 12 suites rojas heredadas**": está desactualizado (hoy son 15). Sin declararlo en el PR, el rojo del primer run se leerá como regresión de Fase A.

---

## Hallazgos menores / desviaciones

### H-06 · Fuga de detalle interno en un endpoint público
`providerController.js:172` → `res.status(500).json({ success:false, error:'INTERNAL_SERVER_ERROR', message: error.message })`. El orden pedía `503 { error:'PROVIDER_SEARCH_UNAVAILABLE' }`; se entregó un 500 genérico **con el mensaje del error de base de datos expuesto al cliente**, en la única ruta de esta fase que es pública. `error.message` no viaja al cliente.

### H-07 · No marcó el fallback geográfico como degradado
`providerController.js:117-139` sigue devolviendo prestadores con lat/lon fijos y `distance_meters` calculados, sin `degraded: true`. El orden lo pedía explícitamente (no borrarlo, marcarlo).

### H-08 · Entrega sin nombres: el delta de 1 test queda sin atribuir
Su BASE: `15 suites fallidas / 79 · 526 pasados, 70 fallidos, 2 omitidos`. Mi medición de su rama: `15 suites / 79 · 533 pasados, **71** fallidos, 2 omitidos, 606 total`. Mismo número de suites rojas (coherente con "sin regresión de suites"), pero **un test más fallando** y 8 tests más en total. Su reporte no trae la lista de nombres, así que no hay con qué comparar conjuntos. **Descarté la hipótesis de flake**: `resilience.test.js` aislada, 3 corridas → `4 failed, 5 passed, 9 total` las tres veces (idéntico). Queda como delta sin atribuir, no como regresión probada ni como "todo igual".

### H-09 · Suites trampa: él no las corrió, yo sí — verdes
El orden nombró `src/tests/memoryFallbackProductionGuard.test.js` y `src/tests/audit360-remediation.test.js` como trampas a vigilar. No aparecen en su verificación. Corridas por mí, junto con `pgMemorySchema`:
```
Test Suites: 3 passed, 3 total
Tests:       22 passed, 22 total
```
El cambio en `db.js` no rompió las guardas existentes. Verificado, pero por mí.

### H-10 · Pista para Fase B: el runner de migraciones reporta éxito sobre una base inalcanzable
En el mismo arranque con `DATABASE_URL` inalcanzable, el log imprimió `Migración 001…072 aplicada exitosamente` para todas, mientras el pool avisaba `⚠️ [DB] Sin enlace con PostgreSQL (ECONNREFUSED) — se sirve memoria local`. Falta confirmar qué variable usa el runner (`DATABASE_URL_ADMIN` vs. el pool principal); si usa el pool, es éxito fabricado en el arranque y pertenece a Fase B (dueño único del esquema). Observado, no concluido.

---

## Lo que sí quedó bien (verificado por mí, no por su relato)

| Punto | Evidencia |
|---|---|
| `ci.yml` es YAML válido y sin marcadores | `python -c "import yaml;yaml.safe_load(...)"` → OK; `grep -c '^<<<<<<<'` → 0 |
| La resolución del conflicto conservó lo correcto | Siguen los dos jobs (`backend-ci`, `frontend-ci`), el servicio PostGIS, `prepareRlsDatabase.js`, `verifyTenantIsolation.js`, el escaneo de secretos y la compuerta nueva; **descartó `sequelize.sync`** — exactamente la decisión pedida |
| `.gitignore` fusionó ambos lados | 6 líneas de marcadores eliminadas; se conservan los informes de baseline **y** `frontend/android/gradle/wrapper/`, `*.pkl` |
| La compuerta anti-marcadores funciona y no se autoflagela | Corrida por mí: `✅ Ningún marcador de conflicto…` `EXIT=0`; su regex no matchea su propia línea de definición (el literal no empieza la línea) |
| `servingFabricatedData` se enciende de verdad | `curl /api/health` con la base caída → `HTTP=503 {"status":"DEGRADED", "database":{"pgAvailable":false,"servingFabricatedData":true,"memoryFallbackAllowed":false}}` |
| Rama cortada de la base correcta | `git merge-base HEAD origin/main` = `f5a1b4fc` = `origin/main` |
| TAREA 0 reportada con honestidad | Dio dependencia de DB ("no requirió DATABASE_URL") y los tres conteos |

Deuda heredada (no introducida por él, pero que Fase A debe cerrar): en el mismo `/api/health` degradado, `memoryFallbackAllowed` es `false` mientras el proceso **está** sirviendo memoria. Los dos indicadores se contradicen: el que dice la verdad es `servingFabricatedData`.

---

## Correcciones exigidas (resumen ejecutable)

1. Limpiar el índice: `git add` de la versión de disco de `checkNoConflictMarkers.js`, y comprobar `git show :backend/scripts/checkNoConflictMarkers.js | grep -c '^<<<<<<<'` = **0** antes de commitear.
2. Commits por tarea + push + **PR con URL** + `git log -1 --format='%h padre=%p'`, declarando el run de CI (aunque nazca rojo, con los nombres de las 8 suites heredadas del H-05).
3. A1.T3 rehecha en la capa correcta (capa de datos, no `catch`): con `servingFabricatedData === true` la ruta **no** puede responder 2xx con payload; y sin `error.message` en el cuerpo.
4. A1.T2, A1.T4, A1.T5, A3.T1, A3.T2, A3.T3 completas, con el par RED→GREEN del smoke como evidencia principal.
5. Números de suite con **nombres** (BASE y rama) y cierre explícito del delta de 1 test.
