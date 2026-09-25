# Cuerpo listo para pegar — PR de `fase-a/verdad-operativa`

**Título sugerido:** `Fase A — Verdad operativa: honestidad de estado, compuertas y grafo de ramas`

**Abrir en:** `https://github.com/Diegoromerov/belleza-app/pull/new/fase-a/verdad-operativa` (ramas: `fase-a/verdad-operativa` → `main`)

**Al mergear: usar merge commit, NO squash** (el grafo de ramas y las auditorías citan los SHAs intermedios).

> **Actualizado el 2026-09-25** tras las rondas 5, 6 y 7 de Fase A, O-014, O-015, O-016 y las rondas 3 de A-02 y 5 de A-06. La versión anterior de este archivo describía el estado del 24 (decía 6 commits y daba S1/S4 por cerrados en falso): **esa tabla ya no aplica**.

---

## Para aterrizar: el tren que se integra en `fase-a`

Las ramas aceptadas por el Auditor entran **en este orden** (cada una es una tarea y una PR; se integran aquí porque `main` conserva los marcadores de conflicto en `ci.yml` — ver CI-10 — y ninguna rama nacida de `main` puede producir evidencia de CI):

| # | Rama | SHA | Qué cierra |
|---|---|---|---|
| 0 | `fase-a/verdad-operativa` | `b545ef22` | 9 commits, +4752/−48: `ci.yml` reparado, `.gitignore`, compuerta anti-marcadores, honestidad del fallback en memoria, errores honestos, grafo de ramas |
| 1 | `fix/ci-procedencia` | `6268afff` | A-05 — procedencia de la evidencia |
| 2 | `fix/rls-056-058-cadena` | `ba06e563` | A-01 r2 ✓ |
| 3 | `fix/montajes-unicos` | `38a9afe9` | A-03 ✓ — 57 rutas retiradas (308 → 252 únicas), 0 pérdidas reales |
| 4 | `fix/admin-metricas-sin-datos` | `6f2f656f` | A-02 r2 ✓ + r3 (CI-18: el mes proyectado ya no salta un mes) |
| 5 | `fix/arranque-y-estado-honesto` | `07e7225e` | Fase A r6 ✓ — tri-estado honesto (`null`/`true`/`false`), cierra CI-17/20/22 |
| 6 | `fix/contrato-convive-con-candado` | `3a9148ad` | O-016 — el contrato de enrutamiento convive con el candado (CI-28) |
| 7 | `fix/candado-comprueba-si-desconoce` | `82f84f5e` | Fase A r7 ✓ — el candado **comprueba** cuando no sabe (CI-23) + timeout del guardián medido |
| 8 | `fix/compuerta-secretos-reproducible` | `85687237` | A-06 r5 ✓ — cada regla re-verifica su patrón: el escáner pasa de **109 hallazgos (101 mal etiquetados) a 8** (CI-19) |

**Fuera del tren, esperando decisión del Dueño:**

| Rama | SHA | Por qué no entra |
|---|---|---|
| `fix/jwt-sin-respaldo` (2b de A-06) | `dbb87293` | Quita el `DEFAULT_PROD_SECRET` literal (`jwt.js:5-11`, **TEC-53**) pero **no es mergeable hasta que el Dueño confirme en Railway** que `JWT_SECRET` y `BIOMETRIC_ENCRYPTION_KEY`/`ENCRYPTION_KEY` están puestas: sin ellas el proceso no arranca o pierde compatibilidad de tokens. Medido: **2b + 2a r5 mergea limpio (0 conflictos) y deja el escáner en 5**, sin rebase ni force-push |

## Estado de los criterios de la Fase A (medido, no citado)

| Criterio | Estado | Evidencia |
|---|---|---|
| S1 · ninguna superficie `2xx` si su consulta falló | **✓** | con la base caída: `/api/products` ⇒ **503 `DATA_LAYER_DEGRADED`** (r6/r7). Sin base, un proceso que sirve sin el arranque ya no deja pasar datos fabricados |
| S2 · degradación visible desde fuera | **✓** | `/api/health` ⇒ **503 `DEGRADED`** con `pgAvailable:false`; y `200 OK` con `pgAvailable:true` (PostGIS 3.6, 296 productos) cuando la base está arriba |
| S3 · el CI existe y puede fallar | **✓** | mutaciones pegadas y reproducidas: en A-06 volver a concatenar ⇒ **3 failed** y el escáner real **vuelve a 109**; en la ronda 7 quitar la comprobación ⇒ **3 failed** |
| S4 · un comando sale `≠0` si algo finge | **✓** | `smokeSurfaces` sale `≠0` si una superficie finge, y su camino de **timeout está medido** (no cuelga, sale `≠0`, mata al hijo con `SIGTERM`) |

Detalle en `docs/knowledge/ESTADO-ACTUAL.md` y `docs/agents/ordenes/EJECUCION-ARQUITECTO-2026-09-25.md` (todo lo ejecutado el 2026-09-25, con sus mutaciones).

## Advertencia que este PR declara (D-008 de `docs/knowledge/DECISIONES.md`)

El paso **bloqueante** de tests excluye 10 patrones de suite y las corre en un paso **no bloqueante**:

```
geminiService | geminiFallback | auraToolExecutor | contract | biometric
resilience | contextCompressor | fase5 | authRoutes | api.cors
```

**El verde de ese paso es verde por exclusión.** No equivale a «verificado»: las 15 suites rojas son deuda heredada y el estado real aparece en el paso no bloqueante.

## Lo que este PR **no** puede cerrar solo (necesita al Dueño)

| # | Qué | Por qué bloquea |
|---|---|---|
| **CI-14** | Las **5 líneas de prosa** con credenciales de ejemplo en informes (`AUDITORIA_PREPRODUCCION_MASTER.md:84`, `BLOQUE_TRABAJO_1_BASELINE.md:144`, `auditoria-belleza-app.md:232`, `:233`, `scripts/COMO_EJECUTAR.md:35`) | Es lo único que mantiene **rojo el paso 7** del CI aun con todas las ramas dentro: el escáner da **8** (5 prosa + 3 literales de código) y sólo baja a 3 si se autoriza sustituir esos valores por `***`. Sin autorización, **no se tocó ningún archivo de prosa** |
| **TEC-53 · D-003** | Rotar los **7 secretos** (`JWT_SECRET`, `ENCRYPTION_KEY`, `DATABASE_URL`, Gemini, YouCam, OpenUV, NVIDIA) | `backend/.env.production` **ya está en el historial de `main`** y el repo es público: rotar es la única reparación real. Y sin esa confirmación, 2b no aterriza |
| **CI-16** | El candado de degradación alcanza `/api/payments/wompi-webhook`, `/api/disputes`, `/api/tickets`, `/api/auth/login`, `/api/admin/metrics` | Firma del Dueño: es una decisión de negocio, no de código |
| **A-04** | `backend/public` (bundle Flutter commiteado): 192 archivos versionados pese a `.gitignore:68` | Decisión de arquitectura; y todo fix de frontend exige rebuild manual o no llega a producción |

## Procedencia de la verificación

- Auditorías de esta rama: `docs/audit/AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` (H-01..H-05), `…-RONDA-2-2026-09-24.md` (B1..B6), `AUDITORIA-ENTREGA-FASE-A-R5`, `AUDITORIA-ENTREGA-FASE-A-R6`.
- Por rama: `docs/audit/AUDITORIA-ENTREGA-{A-01-RONDA-2,A-02-RONDA-2,A-03,A-05,A-06-RONDA-4,O-014,FASE-A-R6}`.
- Ensayo del tren (merges, suites y escáner sobre el conjunto integrado): `docs/agents/ordenes/ENSAYO-TREN-A-2026-09-25.md`.
- Ejecutado por el Arquitecto el 2026-09-25 (con declaración de conflicto de interés y sus mutaciones): `docs/agents/ordenes/EJECUCION-ARQUITECTO-2026-09-25.md`.
