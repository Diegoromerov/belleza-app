# Auditoría del aterrizaje del tren A — verificación sobre `main`

**Fecha:** 2026-09-27 · **Auditor:** Hermes (Arquitecto) · **Autorizado por:** el Dueño («dale»)
**Procedencia declarada por el Ejecutor:** `main` → `e8243432f`, «Merge pull request #16», empuje `f5a1b4fcf..e8243432f`, API de PR #16: `MERGED: true`, `STATE: closed`.

**Veredicto: ATERRIZAJE VERIFICADO — con residuos mapeados.**

## 1. Que el merge sea el que se declaró (no el mensaje: los padres)

| Comprobación | Medición |
|---|---|
| `origin/main` | **`e8243432f`** = lo declarado |
| Padres del commit | `f5a1b4fcf` **+** `a6e40e017` ⇒ **merge commit de verdad**, no squash |
| Ancestría | el tren de 11 (`a6e40e017`) **es ancestro** de `main`; el `main` viejo sigue en la historia |
| Magnitud | 44 commits · 11 merges desde `f5a1b4fcf` |
| API del PR | `merged: true`, `merge_commit_sha: e8243432fb3bacc2eb350a8b6c140faf1e8f778a` |

## 2. Los dos chequeos obligatorios de la §6 del runbook, corridos **sobre `main`**

| Chequeo | Resultado |
|---|---|
| **(a) CI-30 sobrevive** | producción **sin** `BIOMETRIC_ENCRYPTION_KEY` ⇒ **lanza** (fail-closed) · con clave real de **64 hex** ⇒ **arranca** |
| **(b) No volvió ningún literal** | `jwt.js` 0 · `biometricCryptoService.js` 0 · `CLAVE_LEGADA` derivando de `process.env.JWT_SECRET` |
| Compuerta de secretos en `main` | `verifyNoVersionedSecrets.js` ⇒ **exit 0 · ✅ Sin credenciales versionadas** |
| Compuerta anti-marcadores en `main` | `checkNoConflictMarkers.js` ⇒ **exit 0** |
| `.github/workflows/ci.yml` de `main` | **válido, sin marcadores**; jobs `backend-ci` + `frontend-ci` |

## 3. El CI de `main`, medido por GitHub (run `36336949240`, sha `e8243432f`)

**Antes del aterrizaje**, `ci.yml` en `main` acumulaba runs que terminaban como `failure` **sin un solo job** (workflow inválido por los marcadores). Ahora:

```
job Backend Tests & Lint ⇒ failure
   ✓ Compuerta anti-marcadores de conflicto (bloqueante)   success
   ✓ Escaneo de credenciales versionadas (bloqueante)      success   ⇐ EL PASO 7, VERDE POR PRIMERA VEZ
   ✗ Preparar el esquema multi-tenant y los roles RLS      failure   ⇐ CI-46
   · Verificar el aislamiento multi-tenant (compuerta RLS) skipped
   · Run Backend Integration & Unit Tests                  skipped
job Frontend Flutter Analyze & Build Check ⇒ success
```

⇒ El paso 7, que nunca había pasado, **pasa**; el rojo del paso de tests bajó de **55 a 23** en el mismo protocolo de medición; y el workflow de la fuente de verdad **ya es válido y corre**.

## 4. Residuos (ninguno bloquea el aterrizaje, todos mapeados)

| Id | Qué | Estado |
|---|---|---|
| **CI-46** | «Preparar el esquema multi-tenant y los roles RLS» **falla en el runner** y deja la compuerta RLS y los tests en `skipped`. Estaba **oculto detrás del paso 7** | Descartadas 3 hipótesis midiendo (credenciales, regresión del tren, archivo faltante). Sospecha viva: Node 18 del runner — repro en curso |
| **CI-43** | El esquema del subsistema de negocio no existe en la base de test del CI ⇒ 23 rojos en las 4 suites `business*` | Es el último bloqueo del verde, junto con CI-46 |
| **CI-47** | `rag-evaluation.yml` falla en **todos** los PRs a `main`, incluso en ramas de sólo documentación ⇒ pre-existente, branch-independiente | Mapeado |
| **CI-45** | La compuerta anti-marcadores del CI corre con `cd backend` ⇒ **ciega a `.github/`**. Que la reparación sea efectiva lo garantiza mi medición sobre la copia de `main`, no la compuerta | Abierta |
| **S3 / O-005** | El criterio literal «romper un test ⇒ run rojo **en GitHub**» sigue sin medir: los tests quedan `skipped` detrás de CI-46 | 0,90 |

## 5. Efecto en el programa

**Fase A: 75,5 % → 92,5 %** (+17,0 pp; sin A-04: 97,2 %). El indicador de aterrizaje pasa de **0,15 a 1,00**: el 0 % de «fase cerrada» que bloqueaba todo lo que venía después **se movió**.

**Trabajo siguiente** (una sola orden): «que la base del CI sirva» = CI-46 + CI-43 (+ CI-45). Con eso el paso de tests corre en GitHub por primera vez y el criterio S3 queda medible.
