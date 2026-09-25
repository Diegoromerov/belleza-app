# Estado actual — Belleza App / GlowApp

**Medición:** 2026-09-25 00:15 UTC · **Copia de referencia:** `C:/beauty-app` ↔ `github.com/Diegoromerov/belleza-app` · **Base:** `main = f5a1b4fc` (sin mover desde el 2026-09-24)
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
| S1 | Ninguna superficie `2xx` si su consulta falló | **✗** | `GET /api/products` = `200 OK` con datos fabricados y base inalcanzable |
| S2 | La degradación es visible desde fuera | **✓** | `/api/health` = `503` + `X-GlowApp-Degraded: memory-fallback` |
| S3 | El CI existe y **puede fallar** | **~** | ya no es hipótesis: PR #16 run [#1681](https://github.com/Diegoromerov/belleza-app/actions/runs/36072881287) ejecutó **6 pasos reales**, frontend ✅, backend ❌ en el paso 7 y **saltó los pasos 8-11**. Falta la mutación deliberada (O-005) |
| S4 | Un comando sale `≠0` si algo finge | **✗** | `npm run smoke:surfaces` → exit `0` mientras `/api/products` mentía |

## 5. Estado de las compuertas (rol Guardián)

| Compuerta | Ubicación | Qué vigila | Estado |
|---|---|---|---|
| Anti-marcadores de conflicto | `backend/scripts/checkNoConflictMarkers.js` | marcadores `<<<<<<<` en archivos versionados | ✓ en CI (bloqueante) **solo en `fase-a`**; `main` sigue con 3 marcadores (CI-10) |
| Credenciales versionadas | `backend/scripts/verifyNoVersionedSecrets.js` | secretos en el árbol | **⚠ no fiable todavía**: su veredicto depende del fin de línea (CI-06) y quedó ciego al prefijo `glowapp_` (CI-08); ronda 2 en curso |
| Aislamiento multi-tenant | `backend/scripts/verifyTenantIsolation.js` | RLS: `FORCE`, políticas laxas, roles con BYPASSRLS | ✓ **cuando el esquema se levanta**; sobre base vacía moría (CI-01) — corregido, sin aterrizar en `main` |
| Estado y alineación del repositorio | `backend/scripts/estadoKB.js --check` | ramas zombis, ramas sin PR ni tag, worktrees muertos, copia desalineada | ✓ corre en local y en el cron semanal; **hoy sale `exit 1`** por 2 planes sin commitear (R1) |
| Superficies honestas | `backend/scripts/smokeSurfaces.js` | que ninguna superficie mienta | **✗ no cumple su función** (ver S4) |

## 6. Suites rojas heredadas (deuda declarada, no ocultada)

**15 suites fallan** en `main` y en `fase-a` (mismos fallos: no son regresiones). El paso **bloqueante** del CI excluye 10 patrones y las corre en un paso **no bloqueante** para que su estado no desaparezca del tablero:

```
geminiService | geminiFallback | auraToolExecutor | contract | biometric
resilience | contextCompressor | fase5 | authRoutes | api.cors
```

**Consecuencia que hay que decir en voz alta:** el verde de ese paso es **verde por exclusión**. Y hasta hoy **ningún run llegó a ejecutar la suite**: el job muere antes (paso 7), así que el número de suites rojas sigue siendo autorreporte de la rama, no medición de CI.

## 7. Estado del repositorio

- Saneado el 2026-09-24: **44 referencias de rama → 9**, **6 worktrees → 2**, **398 entradas de trabajo sin commitear rescatadas** a 8 tags `archive/*` publicados. Detalle y reversión en `docs/audit/INFORME-PODA-2026-09-24.md`.
- Hoy: **7 ramas** (1 `main` + 6 vivas), **3 worktrees**, **3 PRs abiertos** (#16, #12, #10), 8 tags `archive/*` locales / 17 refs en el remoto.
- Los PRs #5-#9 y #11, #13, #14, #15 del 2026-09-24 están **cerrados sin fusionar**.
- Estado del clon fósil: `C:/Users/Compu casa/belleza-app`, `main = 4f803a0b` (2026-08-04), **divergente** (1.363 commits detrás y **331 únicos**), preservado en bundle local, **marcado como NO USAR**.

## 8. Ciclo en curso (2026-09-24 → 25)

| Orden | Rama | Entrega | Veredicto del Auditor |
|---|---|---|---|
| A-06 | `fix/compuerta-secretos-reproducible` @ `5020e4df` | compuerta de credenciales reproducible | **✗ rechazada**: allowlist `glowapp_/dev_` ciega la compuerta (mutación demostrada), el fallback del `JWT_SECRET` se declaró «falso positivo», autotest tautológico. Ronda 2 emitida |
| A-01 | `fix/rls-056-058-cadena` @ `c36accea` | `services` en `056` + aserción en `058` | **✓ aceptada en sustancia**: aserción probada por mutación, `PREPARE ×2 = 0`, `VERIFY = 0`. Ronda 2 (ligera): rebasar sobre `fase-a`, línea muerta `servicios`, aserción en el 2º bucle |
| — | `docs/sistema-agentes` @ `fafe77fa` | sistema de agentes + base de conocimiento + auditorías | publicado; **nace de `main`, así que sus runs salen con 0 jobs** (CI-10) |

**Decisión pendiente del Dueño:** D-002 (`delete_branch_on_merge`) · D-003 (**rotar los 7 secretos**, porque `backend/.env.production` está en el historial de `main`) · D-004 (mergear `docs/sistema-agentes`) · D-005 (#10/#12) · **A-04** (¿`backend/public` es artefacto commiteado o derivado?) · y 2 planes sin commitear en `C:/beauty-app/.hermes/plans/` que mantienen al guardián en `exit 1`.

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
