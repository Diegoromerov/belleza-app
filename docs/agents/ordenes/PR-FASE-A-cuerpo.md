# Cuerpo listo para pegar — PR de `fase-a/verdad-operativa`

**Título sugerido:** `Fase A — Verdad operativa: honestidad de estado, compuertas y grafo de ramas`

**Abrir en:** `https://github.com/Diegoromerov/belleza-app/pull/new/fase-a/verdad-operativa` (ramas: `fase-a/verdad-operativa` → `main`)

---

## Qué trae (6 commits sobre `main = f5a1b4fc`)

1. **`ci.yml` reparado** — la versión de `main` tiene **marcadores de conflicto sin resolver** (`<<<<<<< HEAD` en la línea 60, `=======`, `>>>>>>> origin/main`) y por eso el workflow aparece como `failure` **sin un solo job**: medido por API, `ci.yml` acumula **1.679 runs** y todos terminan igual, con `jobs=0` — GitHub no puede ni evaluar los disparadores, así que se dispara en cualquier push. Esta rama trae el archivo válido (`yaml.safe_load` OK, jobs `backend-ci` + `frontend-ci`) y con él **el PR ejecutará pasos de verdad por primera vez**: los pushes de esta rama no generaron run porque, al ser el archivo válido, sí se aplica el filtro `branches: [main, staging]`. Al mergear, la reparación llega a `main` y los pushes a `main` dejan de producir runs vacíos. Se conserva el montaje de esquema multi-tenant y los roles RLS (`prepareRlsDatabase.js`, `verifyTenantIsolation.js`) y se descarta `sequelize.sync({force:true})` (`npm run migrate`): las políticas RLS no viven en un modelo.
2. **`.gitignore` saneado** (marcadores fuera, reglas de ambas ramas conservadas).
3. **Compuerta anti-marcadores** — `backend/scripts/checkNoConflictMarkers.js`, cableada en CI.
4. **Honestidad del fallback en memoria** — `servingFabricatedData` se activa al responder desde memoria y se limpia al volver a Postgres (`backend/src/config/db.js`).
5. **Errores honestos** — el `catch` de `GET /api/providers` responde `500`, no `200` con un array vacío.
6. **Grafo de ramas** — `backend/scripts/branchGraph.js` + artefactos en `docs/audit/`.

Verificación de la rama: `flutter analyze` → 0 errores · suite completa → 15 suites rojas **heredadas** (mismos fallos que `main`, 0 regresiones nuevas).

## Advertencia que este PR declara (D-008 de `docs/knowledge/DECISIONES.md`)

El paso **bloqueante** de tests excluye 10 patrones de suite y las corre en un paso **no bloqueante**:

```
geminiService | geminiFallback | auraToolExecutor | contract | biometric
resilience | contextCompressor | fase5 | authRoutes | api.cors
```

**El verde de ese paso es verde por exclusión.** No equivale a «verificado»: las 15 suites rojas son deuda heredada y el estado real aparece en el paso no bloqueante. Criterio S3 de la Fase A queda **parcial** hasta que exista la mutación que demuestre que la compuerta puede fallar (O-005 en `docs/agents/COLA.md`).

## Qué NO está cerrado todavía (Fase A)

| Criterio | Estado |
|---|---|
| S1 · ninguna superficie `2xx` si su consulta falló | **✗** — `GET /api/products` sigue devolviendo `200` con datos fabricados y base caída |
| S2 · degradación visible desde fuera | ✓ — `/api/health` = `503` + `X-GlowApp-Degraded: memory-fallback` |
| S3 · el CI existe y puede fallar | **~** — falta la mutación |
| S4 · un comando sale `≠0` si algo finge | **✗** — `smoke:surfaces` sale `0` mientras el sistema miente |

Detalle en `docs/knowledge/ESTADO-ACTUAL.md`.

## Procedencia de la verificación

- Rama entregada: `fase-a/verdad-operativa` @ `c1069e9f` · `git status --porcelain` limpio.
- Auditorías de esta rama: `docs/audit/AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` (H-01..H-05) y `docs/audit/AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` (B1..B6).
