# Estado actual — Belleza App / GlowApp

**Medición:** 2026-09-25 00:15 UTC · **§4, §5 y §8 re-medidos el 2026-09-25 ~06:30 UTC** (rondas 3-6 de Fase A sobre `fase-a/verdad-operativa` @ `b545ef22`) · **Copia de referencia:** `C:/beauty-app` ↔ `github.com/Diegoromerov/belleza-app` · **Base:** `main = f5a1b4fc` (sin mover desde el 2026-09-24)
**Regla:** todo número de este documento tiene un comando que lo produce. Lo que no se pudo medir dice `NO VERIFICADO`.

---

## 1. Resumen en una línea

La app está **funcionalmente a medias por dentro y aparentemente terminada por fuera**: descubrimiento, agenda y perfiles funcionan; **el dinero y la verificación de identidad no** (no hay cobro real, el OTP no tiene canal, hay caminos que permiten cobrar dos veces). Además el sistema **fabricaba estado** (superficies `200 OK` con datos inventados con la base caída) y **el pipeline de CI no podía ejecutar un solo paso** — desde el 2026-09-24 ya ejecuta pasos y falla mostrando deuda real.

## 2. Qué funciona (con evidencia)

| Capacidad | Estado | Evidencia |
|---|---|---|
| Contacto prestador → reserva → agenda | funciona | `docs/audit/AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` (etapas 1-5, 8, 12) |
| Catálogo de salones/servicios y búsqueda | funciona | `GET /api/providers` responde con datos reales cuando Postgres está arriba |
| Multi-tenant por RLS | funciona en la base viva; **la cadena de migraciones no levantaba sobre base vacía** | `verifyTenantIsolation.js` verde en la base viva; sobre base vacía `058` moría (`CI-01`), corregido en `fix/rls-056-058-cadena` @ `c36accea` **aún sin aterrizar en `main`** |
| API de la app | arranca y sirve | entry real `backend/index.js` (`package.json` main + `CMD` del Dockerfile) |
| Frontend Flutter | compila y analiza sin errores | `flutter analyze` → 0 errores, 38 warnings, 486 infos (medido en `fase-a`) |

## 3. Qué no funciona (deuda de negocio y de honestidad)

| # | Defecto | Impacto | Evidencia |
|---|---|---|---|
| C-01 | Transiciones de reserva aceptadas sin validar; `complete` no mira `payment_status` | **dinero**: se puede acreditar sin cobrar | `docs/audit/AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` |
| C-02 | **No existe cobro real**: el endpoint responde 501 y el cliente no envía PAN/CVV | todo queda `PENDIENTE_PAGO` | idem |
| C-03 | **OTP sin canal**: `emailService.js` es un `console.log` (nodemailer comentado) | no se puede verificar identidad | idem |
| C-05 | Membresías rompen por consultar una columna inexistente | cuentas legítimas reciben 403 | idem |
| A-07 | Comisión real 15-28% + 8% vs «20% total» hardcodeado | prestadores cobran menos de lo que creen | idem |
| S1 | Superficies devuelven `2xx` con datos fabricados cuando su consulta falló (`/api/products` = 200 con base caída) | decisiones sobre datos falsos | `docs/audit/AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` |
| S4 | El guardián `smoke:surfaces` sale `0` mientras el sistema miente | **falso verde automatizado** | idem |
| CI-02 | `GET /api/admin/metrics` **inventa ingresos** con `Math.random()` y proyecta sobre ellos | el dueño decide precios mirando números falsos | `backend/index.js:812-820,840` (`DEUDA.md` CI-02) |
| CI-05 | El `JWT_SECRET` cae a un literal **publicado en este repo** si falta o mide menos de 32 caracteres | **falsificación de tokens**, incluido `admin` | `backend/src/config/jwt.js:5-11` (`DEUDA.md` TEC-53, crítico) |
| D1-D8 | Huecos del generador del grafo de ramas (aristas nacidas del fondo del tronco, conteos hardcodeados, PNG no reproducible) | evidencia que parece evidencia | `docs/audit/AUDITORIA-GRAFO-RAMAS-2026-09-24.md` |

> El inventario completo, trazable y con dueño está en [`DEUDA.md`](DEUDA.md). Las trampas que produjeron cada falso veredicto están en [`TRAMPAS.md`](TRAMPAS.md).

## 4. Criterios de salida de la Fase A (honestidad de estado)

| # | Criterio | Estado | Medición |
|---|---|---|---|
| S1 | Ninguna superficie `2xx` si su consulta falló | **~ ✓** | candado de degradación aterrizado y aceptado (rondas 3-4): con la base inalcanzable `/api/products` = `503 DATA_LAYER_DEGRADED` + `X-GlowApp-Degraded`; con la base **arriba** y la app arrancada **como en producción**, `/api/products` = `200` con `count: 296` (medido 2026-09-25). **Matiz (CI-23, ronda 7)**: `pgAvailable: null` significa «sin comprobar» y el candado **no comprueba** en ese estado ⇒ en un proceso que sirve sin el callback de arranque la primera petición queda a merced de la ruta (medido: 500/503 honestos, sin `2xx` fabricado). Con la app arrancada de verdad, los dos sentidos están medidos. **CI-17, CI-20 y CI-22 CERRADAS en `07e7225e`** |
| S2 | La degradación es visible desde fuera | **✓** | `/api/health` = `503 DEGRADED` + `X-GlowApp-Degraded: memory-fallback` (verificado en las rondas 1-4) |
| S3 | El CI existe y **puede fallar** | **~** | PR #16 head `b545ef22`: run [36100419352](https://github.com/Diegoromerov/belleza-app/actions/runs/36100419352) ejecuta pasos reales, frontend ✅, backend ❌ en el **paso 7** («Escaneo de credenciales versionadas») y **salta los pasos 8-11** ⇒ la suite y la compuerta RLS **nunca se han ejecutado**. Falta CI-14 (5 líneas de prosa) para llegar al paso 8, y la mutación deliberada (O-005) |
| S4 | Un comando sale `≠0` si algo finge | **✓** | verificado **en vivo por el Auditor** (ronda 4): plantó dos rutas con nombres distintos sin tocar el guardián ⇒ descubrió 310 rutas del stack vivo, marcó sólo la que fingía y salió `≠0`; y en la ronda 5, si el stack vivo no carga, el respaldo al inventario **aborta con `exit 1`** en vez de dar verde. **Residuos**: CI-17 (el «caso sano» es inalcanzable por construcción), CI-20 (`-ok.json` commiteado rancio) y CI-22 |

## 5. Estado de las compuertas (rol Guardián)

| Compuerta | Ubicación | Qué vigila | Estado |
|---|---|---|---|
| Anti-marcadores de conflicto | `backend/scripts/checkNoConflictMarkers.js` | marcadores `<<<<<<<` en archivos versionados | ✓ en CI (bloqueante) **solo en `fase-a`**; `main` sigue con 3 marcadores (CI-10) |
| Credenciales versionadas | `backend/scripts/verifyNoVersionedSecrets.js` | secretos en el árbol | **⚠ no fiable todavía**: su veredicto depende del fin de línea (CI-06) y quedó ciego al prefijo `glowapp_` (CI-08); ronda 2 en curso |
| Aislamiento multi-tenant | `backend/scripts/verifyTenantIsolation.js` | RLS: `FORCE`, políticas laxas, roles con BYPASSRLS | ✓ **cuando el esquema se levanta**; sobre base vacía moría (CI-01) — corregido, sin aterrizar en `main` |
| Estado y alineación del repositorio | `backend/scripts/estadoKB.js --check` | ramas zombis, ramas sin PR ni tag, worktrees muertos, copia desalineada | ✓ corre en local y en el cron semanal; **hoy sale `exit 1`** por 2 planes sin commitear (R1) |
| Superficies honestas | `backend/scripts/smokeSurfaces.js` | que ninguna superficie mienta | **✓** (ronda 6, `07e7225e`): arranca la app por el camino real (`spawn node index.js`), espera disponibilidad con timeout explícito, escribe `-ok.json` o `-degraded.json` con `health_status`/`pg_available` y mata el hijo. **Medido por mí**: base arriba ⇒ `IsDegraded=false`, 122 superficies, 0 fakes, `EXIT=0`; base caída ⇒ `-degraded.json`. Residuo: el timeout no está probado por test (Cargo 2 de la ronda 7) |
| **Autonomía** (cron del Arquitecto, fuera del repo) | job «Guardián de estado — Belleza App» lunes 9:00 + `scripts/guardian-belleza.sh` (perfil Hermes) | que el proyecto se mida solo y quede el parte | **✓ funcionando hoy con el runner del perfil**: mide `C:/beauty-app` y detecta la `R1` real (los 2 planes de `.hermes/plans/`) ⇒ `exit=1`. Primer run: **2026-09-28 09:00** (`executions.db` = 0 filas todavía). **O-014 r1 RECHAZADA por CI-25**: el runner versionado (`backend/scripts/guardianBelleza.sh`, `0a32f718`) no puede correr el chequeo en git-bash (`pwd` MSYS ⇒ `/c/...` a `node.exe`) y sus 3 tests solo cubren mocks ⇒ sus verdes son falsos. La **R4 de frescura** sí quedó ✓ (parte viejo ⇒ `--check` falla). **CI-27**: el runner inspecciona la copia donde vive el script ⇒ el cron debe invocarlo apuntando a `C:/beauty-app`. **O-014 ronda 8 emitida** |

## 6. Suites rojas heredadas (deuda declarada, no ocultada)

**15 suites fallan** en `main` y en `fase-a` (mismos fallos: no son regresiones). El paso **bloqueante** del CI excluye 10 patrones y las corre en un paso **no bloqueante** para que su estado no desaparezca del tablero:

```
geminiService | geminiFallback | auraToolExecutor | contract | biometric
resilience | contextCompressor | fase5 | authRoutes | api.cors
```

**Consecuencia que hay que decir en voz alta:** el verde de ese paso es **verde por exclusión**. Y hasta hoy **ningún run llegó a ejecutar la suite**: el job muere antes (paso 7), así que el número de suites rojas sigue siendo autorreporte de la rama, no medición de CI.

## 7. Estado del repositorio

- Saneado el 2026-09-24: **44 referencias de rama → 9**, **6 worktrees → 2**, **398 entradas de trabajo sin commitear rescatadas** a 8 tags `archive/*` publicados. Detalle y reversión en `docs/audit/INFORME-PODA-2026-09-24.md`.
- Hoy (2026-09-25, medido con la API pública y `estadoKB`): **12 ramas en el remoto** (1 `main` + 11 vivas, **todas con tarea o PR**), **3 worktrees**, **3 PRs abiertos** (#16, #12, #10), 8 tags `archive/*` locales / 17 refs remotas. El «~29 ramas» que circuló era **ruido de refs cacheados**: `git fetch --prune` lo limpió y no hay nada que podar.
- Los PRs #5-#9 y #11, #13, #14, #15 del 2026-09-24 están **cerrados sin fusionar**.
- Estado del clon fósil: `C:/Users/Compu casa/belleza-app`, `main = 4f803a0b` (2026-08-04), **divergente** (1.363 commits detrás y **331 únicos**), preservado en bundle local, **marcado como NO USAR**.

## 8. Ciclo en curso (2026-09-24 → 25)

| Orden | Rama | Entrega | Veredicto del Auditor |
|---|---|---|---|
| A-06 | `fix/compuerta-secretos-reproducible` @ `5020e4df` | compuerta de credenciales reproducible | **✗ rechazada**: allowlist `glowapp_/dev_` ciega la compuerta (mutación demostrada), el fallback del `JWT_SECRET` se declaró «falso positivo», autotest tautológico. Ronda 2 emitida |
| A-01 | `fix/rls-056-058-cadena` @ `c36accea` | `services` en `056` + aserción en `058` | **✓ aceptada en sustancia**: aserción probada por mutación, `PREPARE ×2 = 0`, `VERIFY = 0`. Ronda 2 (ligera): rebasar sobre `fase-a`, línea muerta `servicios`, aserción en el 2º bucle |
| — | `docs/sistema-agentes` @ `fafe77fa` | sistema de agentes + base de conocimiento + auditorías | publicado; **nace de `main`, así que sus runs salen con 0 jobs** (CI-10) |
| Fase A r3 / r4 | `fase-a/verdad-operativa` @ `9a86a902` / `3cef7f88` | candado de degradación + guardián por superficies | **S1 ✓ ACEPTADA** · **S4 ✓ ACEPTADA** (310 rutas del stack vivo, `exit 1`; CI-15 CERRADA) |
| A-02 r2 | `fix/admin-metricas-sin-datos` @ `f565037c` | `/api/admin/metrics` sin `Math.random` | **✓ ACEPTADA**; **CI-18** nueva (el mes proyectado salta cuando hoy es 29/30/31) ⇒ ronda 3 emitida |
| A-06 r4 | `fix/compuerta-secretos-reproducible` @ `abfb4bda` + `fix/jwt-sin-respaldo` @ `dbb87293` | compuerta de secretos reproducible | **✗ RECHAZADA**: el refactor perdió la asociación regla→hallazgo (109/104 falsos contra 8/5 reales) ⇒ **CI-19** y **R-08** ⇒ ronda 5 emitida |
| Fase A r5 | `fase-a/verdad-operativa` @ `b545ef22` | fail-fast del guardián + comando del caso sano + atribución del rechazo | **✓ ACEPTADA** con residuos. **Corrección mía del mismo día** (R-06): CI-17 **re-abierta**, CI-20 **rectificada** (no era Redis: el guardián nunca ejecuta el arranque de la app) y **CI-22** nueva ⇒ ronda 6 emitida |
| Fase A r6 | `fix/arranque-y-estado-honesto` @ `07e7225e` | tri-estado honesto + candado con motor puro + guardián con hijo real | **✓ ACEPTADA con residuos**: cierra **CI-17, CI-20 y CI-22** (el caso sano ya se produce: `-ok.json` con `IsDegraded=false` y `EXIT=0`; el hijo muere; informes reproducibles) y abre **CI-23** (el candado no comprueba cuando el estado es `null`: la protección dejó de ser estructural en procesos sin callback de arranque) ⇒ **ronda 7 emitida**. Mis mutaciones propias: 2 de 2 en rojo |

| A-03 (cerrada por el Auditor) | `fix/montajes-unicos` @ `38a9afe9` | dos bloques `app.use` ⇒ uno canónico + `routing.contract.test.js` | **✓ ACEPTADA 2026-09-25** (sus 2 mediciones pendientes las hice yo): **57** rutas retiradas (su reporte decía 56) — 308 → 252 únicas +1 nueva; 44 con equivalente y 13 sin equivalente, **ninguna usada por el cliente** (0 referencias fuera de su propio test) ⇒ no hay pérdida funcional. Mutación A (auth 2×) ⇒ `1 failed/2 passed`; mutación B (`/api/admin` → `/api/admin/precios`) ⇒ `2 failed/1 passed`; archivo restaurado idéntico; suite base **3/3** (el 3º caso es **HTTP real**) |
| O-014 r1 | `chore/guardian-en-el-repo` @ `0a32f718` | runner del guardián versionado + parte + R4 | **✗ RECHAZADA** (Cargo 1, **CI-25**): `pwd` de MSYS (`/c/...`) pasado a `node.exe` ⇒ `Cannot find module 'C:\c\...'` ⇒ `EXIT=1` con **su propio comando**, mientras su walkthrough publica `exit=0`; y sus **3 tests usan mock** ⇒ el único camino no cubierto es el roto. **Cargo 2 (R4 de frescura) ACEPTADO** (probado por mutación) ⇒ **ronda 8 emitida**; **CI-26** (tests con red), **CI-27** (inspecciona la copia donde vive el script) |
| O-015 | ensayo del tren aceptado (5 ramas) sobre el vehículo | **Arquitecto** (worktree detachado, retirado) | **EJECUTADA 2026-09-25 por mí**: 5 merges, **0 conflictos**; 4/5 suites verdes y **routing.contract ROJO** (404 esperado, **503** recibido del candado, medido con y sin base) ⇒ **CI-28** ⇒ O-016 |

| O-016 | contrato de enrutamiento vs candado (CI-28) | `fix/contrato-convive-con-candado` (desde `38a9afe9`) | hacer determinista el C2/C4: declara el estado (aislar el enrutamiento o aceptar `404`/`503` consultando el candado), conserva la mutación del prefijo duplicado | **emitida 2026-09-25**, sin entregar |

**Ensayo del tren (hecho por el Arquitecto, 2026-09-25):** las 5 aceptadas entran en el vehículo con **0 conflictos de texto**, pero el conjunto deja **`routing.contract.test.js` en ROJO** — esperado `404`, recibido **503** del candado de degradación (`degradedLock.js:57-59`, `:86-90`), medido con y sin base. **CI-28** ⇒ no aterrizar hasta que O-016 esté. Mapa completo: `docs/agents/ordenes/ENSAYO-TREN-A-2026-09-25.md`.

**Decisión pendiente del Dueño:** D-002 (`delete_branch_on_merge`) · D-003 (**rotar los 7 secretos**, porque `backend/.env.production` está en el historial de `main`) · D-004 (mergear `docs/sistema-agentes`) · D-005 (#10/#12) · **A-04** (¿`backend/public` es artefacto commiteado o derivado?) · **CI-14** (las 5 líneas de prosa que bloquean el paso 7 del CI) · **CI-16** (el candado de degradación alcanza dinero/identidad sin declararlo) · **CI-12** (`biometricCryptoService.test.js` no lo colecciona jest) · y 2 planes sin commitear en `C:/beauty-app/.hermes/plans/` que mantienen al guardián en `exit 1`.

---

## 9. Bloque máquina (se regenera solo)

Regenerar con: `node backend/scripts/estadoKB.js --write` · Verificar con: `node backend/scripts/estadoKB.js --check`

<!-- estadoKB:inicio -->
> Bloque generado por `backend/scripts/estadoKB.js` el **2026-09-25 00:15:24Z**. No se edita a mano.

**Copia inspeccionada:** `C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/sistema-agentes` · rama `docs/sistema-agentes` @ `fafe77fa` (2026-09-24 19:09:57 -0500) · árbol: **1 entradas sin commitear**

**Ramas locales (7):**

| Rama | SHA | Último commit | Commits fuera de main | PR abierto |
|---|---|---|---|---|
| `docs/sistema-agentes` | `fafe77fa` | 2026-09-24 | 12 | — |
| `fix/compuerta-secretos-reproducible` | `5020e4df` | 2026-09-24 | 7 | — |
| `fase-a/verdad-operativa` | `c1069e9f` | 2026-09-24 | 6 | sí |
| `feat/glowshop-niveles-a0` | `3337aadb` | 2026-09-24 | 1 | sí |
| `feat/glowshop-precios-csv` | `18a04262` | 2026-09-24 | 1 | sí |
| `fix/rls-056-058-cadena` | `c36accea` | 2026-09-24 | 1 | — |
| `main` | `f5a1b4fc` | 2026-09-24 | 0 | — |

**Ramas en el remoto:** 7 → `docs/sistema-agentes` · `fase-a/verdad-operativa` · `feat/glowshop-niveles-a0` · `feat/glowshop-precios-csv` · `fix/compuerta-secretos-reproducible` · `fix/rls-056-058-cadena` · `main`

**PRs abiertos:** #16 `fase-a/verdad-operativa` → `main` · #12 `feat/glowshop-precios-csv` → `main` · #10 `feat/glowshop-niveles-a0` → `main`

**Tags `archive/*`:** 8 locales · 17 refs en el remoto

**Worktrees (3):** `feat/glowshop-niveles-a0` @ 3337aad · `fix/rls-056-058-cadena` @ c36acce · `docs/sistema-agentes` @ fafe77f

**Desalineaciones detectadas (1):**

| Regla | Detalle |
|---|---|
| R1 | 1 entradas sin commitear (M docs/knowledge/ESTADO-ACTUAL.md) |
<!-- estadoKB:fin -->
