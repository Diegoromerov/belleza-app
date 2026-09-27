# FASE A — Verdad operativa · orden de trabajo

**Objetivo de la fase:** que la app deje de afirmar éxito cuando no lo tuvo. Al terminar, cualquier superficie que finja funcionar se ve en un comando. No se arregla ningún flujo de negocio aquí: los flujos son la Fase C (el OTP y el cobro **no** se tocan en A).

**Duración:** 2,0 días-persona · **Rama:** `fase-a/verdad-operativa` (una rama, commits por tarea) · **Prohibido:** `git switch main`, tocar `main`, mezclar tareas de C.

**Punto de partida verificado (2026-09-24, `C:/beauty-app`):**
- `ci.yml` es YAML inválido por marcadores de conflicto (`git show main:.github/workflows/ci.yml` → líneas 60/84/90). `rag-evaluation.yml` está OK.
- `servingFabricatedData` se declara en `src/config/db.js:709`, se expone en `getDbStatus()` (`:720-723`) y **nunca se asigna** ⇒ el detector de datos fabricados de `/api/health` (`index.js:418-428`) nunca puede dispararse.
- `GET /api/providers` responde `200 {count:0,data:[]}` cuando la consulta falla (`src/controllers/providerController.js:170-173`).
- Stack local disponible: `backend/docker-compose.yml` (postgres:5435, redis:6379, backend:8080).
- Guardianes ya escritos que se pueden cablear sin escribir código nuevo: `backend/scripts/verifyNoFabricatedPayments.js`, `verifyNoVersionedSecrets.js`, `verifyTenantIsolation.js`, `verifyTestBaseline.js`, `smoke_test_prod.js`.

**Criterios de salida de la fase (los 4 deben cumplirse; con su mutación):**

| # | Afirmación | Mutación que debe probarla |
|---|---|---|
| S1 | Ninguna superficie responde 2xx cuando la consulta falló | Apagar Postgres ⇒ las rutas de datos devuelven 503/500 con error real, ninguna `200 {data:[]}` |
| S2 | La degradación es visible desde fuera | En modo memoria, `/api/health` responde 503 `DEGRADED` y toda respuesta lleva la cabecera de degradación |
| S3 | El CI existe y puede fallar | Romper un test a propósito ⇒ run rojo; `yaml.safe_load` de los dos workflows sin error |
| S4 | Hay un comando que recorre todas las superficies y sale ≠0 si algo finge | `npm run smoke:surfaces` con la base caída ⇒ exit ≠0 y listado de culpables |

---

## A2 · Resucitar el CI — 0,5 d · **empezar por aquí** (desbloquea la verificación de todo lo demás)

### A2.T1 — Resolver el conflicto de `.github/workflows/ci.yml`
**Archivos:** `.github/workflows/ci.yml` (líneas 60/84/90).
**Decisión a tomar (explícita):** quedarse con el lado que prepara RLS —`node scripts/prepareRlsDatabase.js` + `verifyTenantIsolation.js`, con `DATABASE_URL_ADMIN` y `RLS_ROLE_PASSWORD`— y **descartar** el lado que hacía `npm run migrate` (`sequelize.sync({force:true})`), porque un esquema derivado de modelos no lleva políticas de RLS y ya divergió del desplegado.
**Verificación:** `python -c "import yaml;yaml.safe_load(open('.github/workflows/ci.yml'))"` sin error; `git show HEAD:.github/workflows/ci.yml | grep -c '^<<<<<<<'` = 0.

### A2.T2 — Resolver el conflicto de `.gitignore`
**Archivos:** `.gitignore` (32/36/37 y 84/85/94).
**Decisión:** fusionar ambos lados (reglas de informe de baseline **y** `frontend/android/gradle/wrapper/`, `*.pkl`). Perder una regla reintroduce artefactos járdin.
**Verificación:** `git status --porcelain` no lista artefactos de Gradle/`*.pkl` tras un build local; sin marcadores.

### A2.T3 — Compuerta anti-marcadores + wiring de guardianes
**Archivo:** `.github/workflows/ci.yml` (nuevo step) o `backend/scripts/checkNoConflictMarkers.js` reutilizable en local.
**Contenido:** fallar si cualquier archivo versionado contiene `^<<<<<<<`, `^=======` o `^>>>>>>>`; y añadir `node scripts/verifyNoVersionedSecrets.js` si el step no existe.
**Mutación:** insertar `<<<<<<< HEAD` en cualquier archivo ⇒ el step falla.

---

## A1 · Apagar la fabricación — 1,0 d

### A1.T1 — Encender el detector `servingFabricatedData`
**Archivos:** `src/config/db.js:149` (`handleMemoryQuery`), `:591-595` (`pasarAMemoria`), `:709-723`.
**Cambio:** marcar `servingFabricatedData = true` en el momento exacto en que una consulta se responde desde memoria y volverlo a `false` cuando el modo pasa a `postgres` (`testConnection` en `:657-680` y la recuperación de `:613-624`). `pgAvailable` debe derivarse de `dbMode === 'postgres'` y no de un flag que nunca se actualiza.
**Test:** `src/tests/dbTruthfulDegradation.test.js` — simular error de enlace, comprobar `getDbStatus().servingFabricatedData === true`, después simular recuperación ⇒ `false`.
**Mutación:** forzar el fallback y pedir `/api/health` ⇒ **503 `DEGRADED`** (hoy responde 200 OK).

### A1.T2 — Cabecera de degradación en cada respuesta
**Archivo:** `index.js` (junto a los middlewares de `:340-380`).
**Cambio:** si `getDbStatus().servingFabricatedData`, añadir `X-GlowApp-Degraded: memory-fallback` a toda respuesta. Sin la cabecera, un cliente no puede distinguir una lista vacía legítima de una fabricada.
**Mutación:** en modo memoria toda respuesta lleva la cabecera; en modo Postgres ninguna.

### A1.T3 — `GET /api/providers` deja de mentir
**Archivo:** `src/controllers/providerController.js:170-173` (y el fallback de `:117-139`, que devuelve lat/lon fijos: marcarlo con `degraded: true` en el cuerpo, no borrarlo todavía).
**Cambio:** error de consulta ⇒ `503 {error:'PROVIDER_SEARCH_UNAVAILABLE'}`. `200 {count:0}` queda reservado a "la consulta corrió y no hay resultados".
**Mutación:** apagar Postgres ⇒ 503; con base viva y ciudad sin prestadores ⇒ 200 `count:0`. Hoy ambos casos devuelven lo mismo.

### A1.T4 — Barrido mecánico: `catch` que responden 2xx
**Nuevo:** `backend/scripts/auditFakeSuccess.js` (analiza el AST o, mínimo viable, líneas `catch` seguidas de `res.status(2xx)`/`res.json({success:true})` dentro de 15 líneas).
**Entregable:** `docs/audit/fake-success-2026-09-24.json` con `archivo:línea` + veredicto (`finge` / `legítimo con aviso`). Candidato ya visto: `src/controllers/analyticsController.js:36` (telemetría que devuelve 200 con warning — decidir y documentar, no arreglar a ciegas).
**Mutación:** el script detecta al menos el caso conocido de `providerController.js` antes del fix de T3 (correrlo **antes** de T3 y guardar la salida como línea base).

### A1.T5 — Quitar de la UI las afirmaciones no ejecutadas
**Archivos:** `frontend/lib/widgets/wompi_payment_sheet.dart:594-684` (formularios Nequi/Tarjeta) y `frontend/lib/screens/provider_dashboard_screen.dart:350-378`.
**Cambio:** (a) mientras no haya pasarela, no recolectar número de tarjeta/vencimiento/CVV — reemplazar por un aviso de "cobro en línea no disponible" (además de que recoger datos de tarjeta sin integración es un riesgo de cumplimiento); (b) el desglose de liquidación debe usar `comision_plataforma`/`impuestos_estado`/`pago_neto_prestador` que la API ya devuelve (`bookingController.js:246-281`) y borrar el `gross * 0.20` hardcodeado y el texto "la plataforma asume este impuesto".
**Mutación:** `grep -rn "0\.20\|cvvCtrl\|_cvvCtrl" frontend/lib` ⇒ 0 coincidencias en las rutas de cobro de cita.
**Nota de traspaso a C:** el texto "Se envió el código al cliente" (`paymentRoutes.js:164`) y "el cliente recibirá su código" (`provider_dashboard_screen.dart:914-921`) son promesas de un flujo inexistente; se corrigen en Fase C (C-03), no aquí. Registrar en el backlog de C para que no se pierdan.

---

## A3 · Smoke honesto por superficie — 0,5 d

### A3.T1 — Inventario mecánico de rutas
**Nuevo:** `backend/scripts/listRoutes.js`. Levanta la app sin `listen()` y recorre `app._router.stack` para emitir `{method, path, middleware}` de todos los mounts de `index.js:379-414`, `:522-526` y `:983`.
**Entregable:** `docs/audit/routes-2026-09-24.json`. Nada de listas a mano: el inventario envejece en días.

### A3.T2 — Smoke por superficie
**Nuevo:** `backend/scripts/smokeSurfaces.js` + script `npm run smoke:surfaces`.
**Comportamiento:** contra el stack local (`cd backend && docker compose up -d`), toma un token por rol (cliente, prestador, admin), recorre cada ruta del inventario y reporta por ruta: `status`, `empty_like` (2xx con cuerpo vacío o `data: []`), `degraded_header`, `wrote_to_db` (conteo antes/después de la tabla que le corresponde) y `faked_success` (2xx en una mutación que debía fallar).
**Entregable:** `docs/audit/smoke-<fecha>.json` + resumen en consola + exit ≠0 si hay cualquier `faked_success`.

### A3.T3 — Corrida con la base caída (la evidencia que abre la Fase C)
Ejecutar el smoke con Postgres detenido y guardar el reporte. Ese archivo es la lista priorizada de lo que finge hoy, y con ella se entra a las Fases B y C sin discusión de opiniones.

---

## Orden de ejecución y responsable sugerido

| Orden | Tarea | Días | Perfil |
|---|---|---|---|
| 1 | A2.T1-T3 (CI + compuerta) | 0,5 | Mecánico, revisión de Hermes |
| 2 | A1.T4 primero como línea base, luego A1.T1-T3 | 0,5 | Hermes (criterio sobre qué es degradación legítima) |
| 3 | A1.T5 (UI honesta) | 0,25 | Mecánico |
| 4 | A3.T1-T3 (inventario + smoke + corrida roja) | 0,25 | Hermes |

## Riesgos y contra-medidas

| Riesgo | Contra-medida |
|---|---|
| A1 rompe el desarrollo de quien trabaja sin Postgres | `ALLOW_MEMORY_FALLBACK=true` sigue disponible **solo** en dev, documentado en `AGENTS.md`; en `NODE_ENV=test` el flag no basta para callar la cabecera |
| Los tests siguen verdes con datos fabricados (`db.js:145` habilita memoria en test) | A1.T2 los delata; el endurecimiento definitivo va en Fase B (compuerta de esquema) |
| Antigravity edita el mismo working tree | Una rama `fase-a/verdad-operativa`; `git add` por rutas explícitas; archivos ajenos en commit aparte con autoría declarada |
| Tentación de arreglar el OTP o el cobro aquí | El alcance de A es "no fingir", no "hacer funcionar": C-01/C-02/C-03 viven en Fase C |
| El smoke necesita datos para no dar falsos rojos | Sembrar con el seed reproducible (B3) o marcar las rutas que requieren fixture como `skipped`, nunca como verde |

## Evidencia que debe quedar en el PR de la fase

1. Salida de `yaml.safe_load` de ambos workflows y un run de CI en rojo provocado a propósito.
2. Antes/después de `/api/health` con la base caída (200 OK → 503 DEGRADED).
3. Antes/después de `GET /api/providers` con la base caída (200 `count:0` → 503).
4. `docs/audit/fake-success-*.json` y `docs/audit/smoke-*.json`.
5. `grep` de verificación de T5 (sin PAN/CVV, sin `0.20`).
