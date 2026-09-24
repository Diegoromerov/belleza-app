# Estado actual — Belleza App / GlowApp

**Medición:** 2026-09-24 · **Copia de referencia:** `C:/beauty-app` ↔ `github.com/Diegoromerov/belleza-app` · **Base:** `main = f5a1b4fc`
**Regla:** todo número de este documento tiene un comando que lo produce. Lo que no se pudo medir dice `NO VERIFICADO`.

---

## 1. Resumen en una línea

La app está **funcionalmente a medias por dentro y aparentemente terminada por fuera**: los flujos de descubrimiento, agenda y perfiles funcionan; **el dinero y la verificación de identidad no** (no existe cobro real, el OTP no tiene canal, y hay caminos que permiten cobrar dos veces). Además el sistema **fabricaba estado**: con la base caída, varias superficies respondían `200 OK` con datos inventados.

## 2. Qué funciona (con evidencia)

| Capacidad | Estado | Evidencia |
|---|---|---|
| Contacto prestador → reserva → agenda | funciona | `docs/audit/AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` (etapas 1-5, 8, 12) |
| Catálogo de salones/servicios y búsqueda | funciona | `GET /api/providers` responde con datos reales cuando Postgres está arriba |
| Multi-tenant por RLS | funciona y está probado | `backend/scripts/prepareRlsDatabase.js` + `backend/scripts/verifyTenantIsolation.js`; en local se prueba con `SET ROLE app_rls_user` + `set_config('app.tenant_id', …)` |
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
| D1-D8 | Huecos del generador del grafo de ramas (aristas nacidas del fondo del tronco, conteos hardcodeados, PNG no reproducible) | evidencia que parece evidencia | `docs/audit/AUDITORIA-GRAFO-RAMAS-2026-09-24.md` |

> El inventario completo, trazable y con dueño está en [`DEUDA.md`](DEUDA.md). Las trampas que produjeron cada falso veredicto están en [`TRAMPAS.md`](TRAMPAS.md).

## 4. Criterios de salida de la Fase A (honestidad de estado)

| # | Criterio | Estado | Medición |
|---|---|---|---|
| S1 | Ninguna superficie `2xx` si su consulta falló | **✗** | `GET /api/products` = `200 OK` con datos fabricados y base inalcanzable |
| S2 | La degradación es visible desde fuera | **✓** | `/api/health` = `503` + `X-GlowApp-Degraded: memory-fallback` |
| S3 | El CI existe y **puede fallar** | **~** | `ci.yml` parsea y está reparado, pero **ningún run se ha ejecutado nunca**; falta O-005 (mutación) |
| S4 | Un comando sale `≠0` si algo finge | **✗** | `npm run smoke:surfaces` → exit `0` mientras `/api/products` mentía |

## 5. Estado de las compuertas (rol Guardián)

| Compuerta | Ubicación | Qué vigila | Estado |
|---|---|---|---|
| Anti-marcadores de conflicto | `backend/scripts/checkNoConflictMarkers.js` | marcadores `<<<<<<<` en archivos versionados | ✓ en CI (bloqueante) |
| Credenciales versionadas | `backend/scripts/verifyNoVersionedSecrets.js` | secretos en el árbol | ✓ en CI (bloqueante) |
| Aislamiento multi-tenant | `backend/scripts/verifyTenantIsolation.js` | RLS: `FORCE`, políticas laxas, roles con BYPASSRLS | ✓ en CI (bloqueante) |
| Estado y alineación del repositorio | `backend/scripts/estadoKB.js --check` | ramas zombis, ramas sin PR ni tag, worktrees muertos, copia desalineada | **nuevo** — job semanal O-003/O-004 |
| Superficies honestas | `backend/scripts/smokeSurfaces.js` | que ninguna superficie mienta | **✗ no cumple su función** (ver S4) |

## 6. Suites rojas heredadas (deuda declarada, no ocultada)

**15 suites fallan** en `main` y en `fase-a` (mismos fallos: no son regresiones). El paso **bloqueante** del CI excluye 10 patrones y las corre en un paso **no bloqueante** para que su estado no desaparezca del tablero:

```
geminiService | geminiFallback | auraToolExecutor | contract | biometric
resilience | contextCompressor | fase5 | authRoutes | api.cors
```

**Consecuencia que hay que decir en voz alta:** el verde de ese paso es **verde por exclusión**. No equivale a «verificado».

## 7. Estado del repositorio

Saneado el 2026-09-24: **44 referencias de rama → 9**, **6 worktrees → 2**, **398 entradas de trabajo sin commitear rescatadas** a 8 tags `archive/*` publicados. Detalle y reversión en `docs/audit/INFORME-PODA-2026-09-24.md`.

Estado del clon fósil: `C:/Users/Compu casa/belleza-app`, `main = 4f803a0b` (2026-08-04), **divergente** (1.363 commits detrás y **331 únicos**), preservado en bundle local, **marcado como NO USAR**.

---

## 8. Bloque máquina (se regenera solo)

Regenerar con: `node backend/scripts/estadoKB.js --write` · Verificar con: `node backend/scripts/estadoKB.js --check`

<!-- estadoKB:inicio -->
> Bloque generado por `backend/scripts/estadoKB.js` el **2026-09-24 22:46:43Z**. No se edita a mano.

**Copia inspeccionada:** `C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/sistema-agentes` · rama `docs/sistema-agentes` @ `f5a1b4fc` (2026-09-24 15:37:30 -0500) · árbol: **36 entradas sin commitear**

**Ramas locales (5):**

| Rama | SHA | Último commit | Commits fuera de main | PR abierto |
|---|---|---|---|---|
| `fase-a/verdad-operativa` | `c1069e9f` | 2026-09-24 | 6 | — |
| `feat/glowshop-niveles-a0` | `3337aadb` | 2026-09-24 | 1 | sí |
| `feat/glowshop-precios-csv` | `18a04262` | 2026-09-24 | 1 | sí |
| `docs/sistema-agentes` | `f5a1b4fc` | 2026-09-24 | 0 | — |
| `main` | `f5a1b4fc` | 2026-09-24 | 0 | — |

**Ramas en el remoto:** 4 → `fase-a/verdad-operativa` · `feat/glowshop-niveles-a0` · `feat/glowshop-precios-csv` · `main`

**PRs abiertos:** #12 `feat/glowshop-precios-csv` → `main` · #10 `feat/glowshop-niveles-a0` → `main`

**Tags `archive/*`:** 8 locales · 17 refs en el remoto

**Worktrees (3):** `feat/glowshop-niveles-a0` @ 3337aad · `fase-a/verdad-operativa` @ c1069e9 · `docs/sistema-agentes` @ f5a1b4f

**Desalineaciones detectadas (3):**

| Regla | Detalle |
|---|---|
| R1 | 36 entradas sin commitear (?? backend/scripts/estadoKB.js · ?? docs/agents/COLA.md · ?? docs/agents/PLANTILLA-AUDITORIA.md …) |
| R3 | «docs/sistema-agentes» es muerta viva (0 commits fuera de main) |
| R4 | el worktree C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/sistema-agentes apunta a la rama muerta «docs/sistema-agentes» |
<!-- estadoKB:fin -->
