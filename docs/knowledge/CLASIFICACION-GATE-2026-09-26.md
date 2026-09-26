# Clasificación del núcleo rojo del gate — 10 suites, medidas una por una

**Fecha:** 2026-09-26 · **Método:** cada suite **aislada** (`--runInBand`), contra la base limpia real `glowtest_gate` (`beauty-postgres:5435`), sobre `b545ef22` (cabeza de `fase-a/verdad-operativa`), **en un checkout LF** (ver §0, es decisivo).
**Para qué sirve:** es el insumo que A-07 necesitaba y el que permite decidir el aterrizaje sabiendo **qué clase de rojo es cada uno**.

## §0. Trampa de método que invalida la primera medición (y la mía)

El escáner de secretos usa `git grep` y valida **la línea cruda**, con el `\r` incluido. Medido sobre el **mismo commit**:

| checkout | escáner viejo (152 líneas, el de `fase-a`) | escáner nuevo (245, A-06 r5) |
|---|---|---|
| **CRLF** (el que produce Windows por defecto) | exit 0 · **0 hallazgos** ← *falso limpio* | exit 1 · **8 hallazgos** |
| **LF** (el que produce el CI en Ubuntu) | exit 1 · **39 hallazgos** | exit 1 · **8 hallazgos** |

Prueba causal: tomé `AUDITORIA_PREPRODUCCION_MASTER.md` (273 de 274 líneas en CRLF), lo pasé a LF **sólo en mi copia** y el escáner pasó de 0 a **2 hallazgos, exactamente en ese archivo** (`:81`, `:84`). Restaurado después.

⇒ El rojo del paso 7 en el CI sobre `fase-a` es **real** (39 hallazgos en LF); mi «0 hallazgos» local era **artefacto de CRLF**. Y el escáner de A-06 r5 **sí** es tolerante al CRLF (8 = 8) ⇒ esa rama no sólo corrige el conteo: hace que el gate diga lo mismo en Windows y en el CI.

## §1. Las 10 suites, aisladas

| Suite | Aislada (LF, base real) | Primera falla | Clase |
|---|---|---|---|
| `adminPreciosRoutes` | 4 failed / 1 passed | esperado **403**, recibido **400** | **real** — semántica HTTP de autorización |
| `audit360-remediation` | 1 failed / 18 passed | el test del escáner (`no hay credenciales…`) | **real** — depende de CI-14 / 2b |
| `business.integration` | 7 / 11 | esperado 200, recibido **500** | **real** — el endpoint 500 |
| `businessAdminDocs.integration` | 8 / 8 | esperado 200, recibido **500** | **real** — 500 |
| `businessHardening.integration` | 12 / 12 | esperado 200, recibido **500** | **real** — 500 |
| `businessRAG.integration` | 1 / 14 | esperado `"success"`, recibido `"not_found"` | **real** — sin dataset/expediente en la base |
| `businessSystem.integration` | 10 / 16 | esperado 200, recibido **500** | **real** — 500 |
| `rateLimiter` | 7 / 12 | `Cannot read properties of undefined (reading 'free')` | **contrato roto** — el test importa un export que ya no existe (`TIER_LIMITS`) |
| `sequelizeTenantContext` | 8 / 8 | `cablearContextoEnSequelize is not a function` | **contrato roto** — import inexistente |
| `sprint2_agents` | 1 / 5 | esperado `"14:00"`, recibido `undefined` | **real / expectativa obsoleta** |

**Conclusión: las 10 son rojas reproducibles en aislamiento** (no es un artefacto de paralelismo del gate). Y **no son una sola cosa**:
- **5 suites** fallan con **500 en endpoints de negocio** ⇒ el bloque dominante. Un 500 en un endpoint cuya consulta no tiene datos es, además, el tipo de cosa que Fase A persigue: la superficie no debería romperse, debería decir qué le falta.
- **2 suites** tienen **contrato de módulo roto** (imports inexistentes) ⇒ arreglo barato o retiro justificado.
- **3** son de expectativa/semántica (403 vs 400, `"success"` vs `"not_found"`, `"14:00"` vs `undefined`).

## §2. Lo que esto cambia

1. **El aterrizaje sigue exigiendo decisión**: aunque CI-14 y 2b se resuelvan, el paso 8 (tests) queda rojo por este núcleo. Ahora se sabe **cuánto** es deuda de contrato (2 suites) y **cuánto** es comportamiento (5 de 500 + 3 de semántica).
2. **A-07 arranca con el mapa hecho**: no necesita reproducir la clasificación, sólo decidir por suite (arreglar, retirar con justificación, o abrir trabajo propio).
3. **Toda medición de suites debe hacerse en un checkout LF**; si no, los tests que leen archivos mienten. `audit360-remediation` pasó 19/19 en CRLF y falla en LF: ese «verde aislado» era falso.
