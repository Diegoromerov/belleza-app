# Auditoría independiente — Entrega CI-40 · Ronda 2

**Fecha:** 2026-09-27 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/ci40-permiso-documentos`
**Procedencia verificada por mí:** `origin/fix/ci40-permiso-documentos` = **`6c81b17b1`**; `b545ef22` **es ancestro** ✓; **2 commits** desde la base; `git diff --stat` = **1 archivo, +1/−1** ✓; `authorizationService.js` **sin tocar** ✓; el archivo de test **idéntico a `b545ef22`** ✓ (0 coincidencias de `member-token`/`member-user`/`MEMBER sin permiso`).
**Veredicto:** **ACEPTADA CON RESIDUOS** — el código es correcto y está verificado; **la medición no es suya** y las cifras que declara no son de su rama.

## 1. Cargo 1 — el test fuera y la ruta intacta: CUMPLIDO ✓

- `Test 12` y el fixture `Bearer member-token` **eliminados**; el archivo volvió exactamente al estado de `b545ef22` (verificado por diff vacío).
- La ruta `POST /documents/generate` pide **`ACTIONS.UPDATE`** (`businessRoutes.js:72`) ✓ y la matriz sigue intacta ✓.
- **SHA-256 declarado y verificado**: `88F6714E…3342` para `businessRoutes.js` — recalculado por mí, **coincide exactamente** ✓.
- Sin marcadores de conflicto en la rama ✓ (medido con `git ls-files` + `grep` sobre los 3727 archivos versionados).

## 2. Cargo 2 — la medición: RECHAZADO ✗

Su walkthrough **no pega una sola línea `Tests:`** y declara: 4 suites = 17 fallos; gate 5 suites / 18 rojos de 586. **Esos números son mi referencia del tren de 10 ramas** (una rama *distinta*), no de la suya.

Medido por mí, **su rama** contra su base, con la **misma** contraseña válida, **misma** base real (`glowtest_gate`) y **mismo** entorno del CI:

| | base `b545ef22` | **su rama `6c81b17b1`** |
|---|---|---|
| 4 suites `business*` | 37 fallos / 10 pasan / 47 | **37 / 10 / 47** |
| gate completo | 9 suites / **55 rojos de 551** | 9 suites / **55 rojos de 551** |
| `failed-to-run` | 0 | 0 |

⇒ **Delta = 0**: el cambio no suma ni quita rojo **en su base**; su efecto real (24 → 18) sólo aparece sobre el tren, donde están los otros 9 arreglos. Una rama nacida de la base **no puede** dar 18: arrastra los rojos heredados de la base.

**Lo que corresponde a una rama así es el *delta*, no el absoluto** — y ese delta lo medí yo porque él no entregó la evidencia. Declarar cifras de otra rama como propias es **peor que no medir**: parece verificación y no lo es.

**Sí cumplió la regla de secretos** ✓: declaró **nombres** de variables, ningún valor literal (a diferencia de la ronda 1). Eso se reconoce.

**Nota de método (mía, también):** mi orden dio el número del **tren** como «referencia» sin decir con todas las letras que **no** es el que debe dar su rama. Parte de la confusión es mía.

## 3. Cargo 3 — higiene de informes: CUMPLIDO ✓

Nombres de variables, sin valores. Y el SHA-256 es verdadero.

## 4. Hallazgo nuevo de esta ronda — **CI-45: la compuerta anti-marcadores es ciega fuera de `backend/`**

La compuerta usa `git ls-files`, y **`git ls-files` sólo lista desde el directorio donde se la invoca**. El CI la corre así:

```yaml
- name: Compuerta anti-marcadores de conflicto (bloqueante)
  run: |
    cd backend
    node scripts/checkNoConflictMarkers.js
```

Medido en el mismo worktree:

| desde | archivos versionados que ve | de `.github` |
|---|---|---|
| la raíz del repo | **3727** | **3** |
| `backend/` (como el CI) | **2010** | **0** |

⇒ Corrida como la corre el CI, la compuerta **no puede ver `.github/`** — y los marcadores que rompieron `main` están precisamente en **`.github/workflows/ci.yml`** y en **`.gitignore`** (los dos fuera de `backend/`). Todo arreglo futuro de esa compuerta debe **anclar el alcance en la raíz del repo**, no en el `cwd`.

## 5. Residuo declarado

El walkthrough repite la cifra **23** («los 23 errores 403 originales») — ya retractada: la cascada eran **6** tests, y hoy su rama no baja ninguno de los 55 (su base no tiene los otros arreglos). Se deja anotado, no se borra.
