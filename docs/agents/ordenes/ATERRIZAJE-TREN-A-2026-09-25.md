# ATERRIZAJE DEL TREN A — runbook listo para ejecutar (2026-09-25)

**Estado:** preparado y verificado en seco. **No ejecutado.** Requiere la autorización del Dueño (§0).
**Quién ejecuta:** el Arquitecto (Hermes), con las compuertas mecánicas de abajo. El Ejecutor (Antigravity) **no** mergea ni empuja `fase-a`.

---

## 0. Precondiciones (lo que el Dueño decide)

| # | Decisión | Estado hoy |
|---|---|---|
| 1 | **Autorizar el aterrizaje** del tren en `fase-a/verdad-operativa` y el merge del PR #16 con **merge commit (no squash)** | **pendiente** |
| 2 | **CI-14** — autorizar sustituir por `***` las 5 líneas de prosa con credenciales de ejemplo | **pendiente** (es lo que mantiene rojo el paso 7 *y* la suite `audit360-remediation`) |
| 3 | **TEC-53** — confirmar en Railway `JWT_SECRET` y `BIOMETRIC_ENCRYPTION_KEY`/`ENCRYPTION_KEY` | **pendiente** (sin esto, 2b no puede aterrizar y el CI no llega a 0 credenciales) |

> **Consecuencia honesta:** el aterrizaje **se puede** hacer ya (el tren integra limpio y las suites clave pasan), pero el CI del PR
> **seguirá rojo** mientras 2 y 3 no se cierren, porque `audit360-remediation.test.js:192` corre el escáner real y falla con
> credenciales > 0. Aterrizar con el CI rojo es una decisión legítima del Dueño; **lo que no sería legítimo es decir que el CI está verde**.

## 1. Verificación en seco (ya medida, reproducible)

| Comprobación | Resultado medido |
|---|---|
| merges de las 8 ramas sobre `b545ef22` | **8, 0 conflictos de texto, 0 abortados** (`--is-ancestor` confirma las 8) |
| **re-ensayo con 9 ramas (2026-09-26, tras aceptar A-08)** | **9 merges, 0 conflictos, 0 abortados** (`--is-ancestor` confirma las 9) · HEAD del tren **`3571a831`** · 27 commits propios · en checkout **LF** |
| **re-ensayo con 10 ramas (2026-09-26, tras CERRAR A-07)** | **10 merges, 0 conflictos, 0 abortados** (`--is-ancestor` confirma **10 de 10**) · HEAD **`723df93d3`** · 32 commits propios · anti-marcadores **exit 0** · suites de las ramas **11 suites / 64 tests verdes** · **gate: 5 suites / 24 tests rojos de 586 · 0 `failed-to-run`** ⇒ aterrizar las 10 **no suma ni un rojo** · **RLS sobre el tren: `VERIFICADO`, 0 tablas omitidas** (A-07 toca `database.js`, así que se re-verificó) · suites coleccionables **91** |
| suites clave sobre el tren | **10 suites / 45 tests verdes** |
| suites clave sobre el tren de 9 ramas | **9 suites / 51 tests verdes** (incluye las 2 nuevas de A-08) · suites coleccionables: **91** (en 8 ramas eran 82) |
| **compuerta RLS (paso 5) sobre el tren de 9 ramas** | **exit 0 · 22 pruebas ejecutadas · 0 omitidas** (base preparada con los 8 SQL del CI: 13 tablas con RLS+FORCE+1 política, escritura en inquilino ajeno rechazada 42501, trigger rellenando `tenant_id`) — el cableado de Sequelize de A-08 **no** rompió el aislamiento. **Ojo:** el mismo script sale 0 con la base vacía y **0 pruebas** (CI-38) ⇒ el número que vale es el de pruebas ejecutadas |
| escáner (paso 7) | **8 hallazgos reales**, 0 mal etiquetados |
| escáner con 2b encima | **5** (sólo prosa) |
| compuerta de aislamiento RLS (paso 5 del CI) | **exit 0 — AISLAMIENTO MULTI-TENANT VERIFICADO** (corrida local con `app_rls_user`) |
| `main` / `fase-a` / vehículo | sin mover: `f5a1b4fc` / `b545ef22` / `0a32f718` |

## 2. Comandos del aterrizaje (uno por uno, sin atajos)

```bash
cd "C:/beauty-app"                       # clon autoritativo
git fetch --prune origin
git status --porcelain                   # DEBE salir vacío

# 1) integrar el tren en fase-a (rama compartida: se integra, no se reescribe)
git worktree add ../fase-a-landing fase-a/verdad-operativa
cd ../fase-a-landing
for r in fix/ci-procedencia fix/rls-056-058-cadena fix/montajes-unicos \
         fix/admin-metricas-sin-datos fix/arranque-y-estado-honesto \
         fix/contrato-convive-con-candado fix/candado-comprueba-si-desconoce \
         fix/compuerta-secretos-reproducible fix/caminos-muertos \
         fix/gate-clasificado; do
  git merge --no-edit "$r" || { echo "CONFLICTO en $r — PARAR y reportar"; exit 1; }
done

# OJO: exportar TODAS las variables del CI antes de correr los tests
# (NODE_ENV, JWT_SECRET, DATABASE_URL, TEST_DATABASE_URL, RLS_ROLE_PASSWORD).
# Medir sin JWT_SECRET dio 4 tests rojos falsos durante una jornada entera:
# ver docs/audit/RETRACTACION-GATE-ENTORNO-2026-09-26.md

# 2) compuertas ANTES de empujar (todas mecánicas, ninguna "a ojo")
node backend/scripts/checkNoConflictMarkers.js            # exit 0
node backend/scripts/verifyNoVersionedSecrets.js          # exit 1 esperado HOY (8): ver §3
npx jest src/tests/routing.contract.test.js src/tests/dbStatusLock.test.js \
         src/tests/degradedLockBehavior.test.js src/tests/candadoCompruebaSiDesconoce.test.js \
         src/tests/adminMetricsProjectedMonth.test.js src/tests/smokeSurfacesTimeout.test.js \
         src/tests/verifyNoVersionedSecretsEtiqueta.test.js   # esperado: todas verdes

# 3) empujar fase-a (fast-forward: es la primera integración)
git push origin fase-a/verdad-operativa

# 4) el PR #16 se mergea con MERGE COMMIT (nunca squash):
#    https://github.com/Diegoromerov/belleza-app/pull/16  → "Create a merge commit"
```

**Prohibido en este paso:** `--force`, `--force-with-lease`, squash, rebase de ramas ya empujadas, borrar ramas, tocar migraciones
o `backend/public`.

## 3. Qué se espera ver en el CI después de empujar (medido, no supuesto)

- `Frontend Flutter Analyze & Build` ⇒ **success** (ya lo está).
- `Backend Tests & Lint` ⇒ **failure** mientras no se cierren CI-14 y TEC-53:
  - paso 7 «Escaneo de credenciales versionadas» ⇒ rojo (8 > 0);
  - paso bloqueante de tests ⇒ rojo por `audit360-remediation` (misma causa raíz).
- Cuando **2b + CI-14** aterricen: el escáner llega a **0** ⇒ el paso 7 y `audit360-remediation` se ponen verdes.
- **El paso bloqueante de tests: hoy son 5 suites / 24 tests rojos de 586, y el rojo NO es deuda de tests.** Medido sobre el tren de 10 con el entorno completo del CI:
  - `audit360-remediation` = **1 test** por las 8 credenciales ⇒ **CI-14 (decisión del Dueño)**;
  - `business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessSystem.integration` = **23 tests** = **cascada de CI-40**: `/documents/generate` exige `BUSINESS_PROFILE:CREATE` y **ningún rol lo tiene** ⇒ el endpoint es inalcanzable para todos ⇒ **CI-35 (decisión del Dueño)**.
  - **Ninguna de las dos se arregla con código de tests.** Con esas dos decisiones, el paso de tests queda **verde por primera vez**.
  - `0 failed-to-run`: el «rojo fantasma» del crash de worker ya no aparece tras A-07 (r3 lo arregló en el código).
  - **Recuento corregido (2026-09-26):** las cifras anteriores de este runbook («10 suites rojas de 75», «19 en la suite completa») se midieron **sin `JWT_SECRET`** y estaban infladas en 4 tests (`adminPreciosRoutes`, que sí es falsa roja por entorno y ya no lo es: CI-41). Serie correcta: base **55 → tren 24** tests rojos; paso 9: base **77**, A-07 r2 **46**, r3 **47**. Ver `docs/audit/RETRACTACION-GATE-ENTORNO-2026-09-26.md`.

  ⇒ **Decisión explícita del Dueño**: (a) decidir **CI-35** y **CI-14** (y entonces el aterrizaje llega con el paso de tests **verde**), o (b) aterrizar aceptando esos **24 tests rojos** documentados como deuda con dueño identificado. Lo que **no** sería legítimo es decir que el CI está verde.

## 4. Verificación posterior (obligatoria, con evidencia pegada)

1. `git log --oneline -3` en `fase-a` + `git rev-parse --short fase-a/verdad-operativa` (SHA nuevo).
2. API pública: `GET /repos/Diegoromerov/belleza-app/pulls/16` ⇒ `mergeable`, `commits`.
3. `GET /commits/<sha-nuevo>/check-runs` ⇒ los 2 checks con su conclusión (pegar crudo).
4. KB: `ESTADO-ACTUAL.md` (Fase A = aterrizada en `fase-a`, PR #16 actualizado), `COLA.md` (ramas cerradas) y `DEUDA.md`
   (CI-23/CI-18/CI-19/CI-28 pasan de «en rama» a «cerradas» si el aterrizaje ocurre).

## 5. Rollback

Si algo sale mal **después** de empujar: `git revert -m 1 <sha-del-merge>` en una rama nueva y PR contra `fase-a`.
**No** se rebobina `fase-a` (reescribir una rama compartida está prohibido y ya hay evidencia externa que la cita).

## 6. Lo que este aterrizaje NO hace

- No toca `main` (eso es el merge del PR #16, decisión del Dueño en la interfaz de GitHub).
- No rota secretos (D-003) ni decide sobre `backend/public` (A-04) ni sobre el alcance del candado (CI-16).
- No cierra la Fase A: queda el residuo de CI-14/TEC-53 y el diagnóstico del workflow `rag-evaluation` (no bloquea el PR).

---

## §6 · Chequeos obligatorios al resolver el conflicto del servicio biométrico (2026-09-27)

**Por qué:** dos ramas reescriben el mismo archivo — `backend/src/services/biometricCryptoService.js`. **A-08** (`fix/caminos-muertos`, **ya en el tren**) le puso el control **fail-closed de 32 bytes** (CI-30) y quita la derivación por `sha256` en producción; **TEC-53** (`fix/secretos-sin-respaldo-literal`, en vuelo) lo reescribe para **quitar el literal de respaldo** de `CLAVE_LEGADA`. Además, su rama nace de `b545ef22`, así que **no** trae el control de A-08: si el conflicto se resuelve quedándose con un lado, se pierde una de las dos cosas.

Al resolverlo, verificar las **dos** y pegarlo:

1. **Sobrevive CI-30**: el arranque con una clave que no son 32 bytes (ni 64 hex ni 32 utf8) **lanza** en producción/test (`NODE_ENV=production node -e "require('./src/services/biometricCryptoService')"` ⇒ error), y con la clave real (**64 hex**) **no** lanza.
2. **No vuelve ningún literal**: `grep -nE "fallback|clave_vieja|glowapp_biometric|beauty_app_super_secret" backend/src/services/biometricCryptoService.js` ⇒ sin coincidencias, y `node scripts/verifyNoVersionedSecrets.js < /dev/null` ⇒ **exit 0, 0 hallazgos**.

**Además (duplicación trivial):** TEC-53 toca `backend/src/tests/adminPreciosRoutes.test.js` con el mismo cambio que ya hizo **A-07 r4** (`4e9145ad9`, en el tren): usar `getJwtSecret()`. Ese hunk debe resolverse como **no-op** (o conflicto trivial); si el archivo aterriza con el literal de respaldo, es una regresión.

---

## §7 · Tren de 11 ensayado (2026-09-27) — los 10 + TEC-53

**Rama de ensayo:** `tren/aterrizaje-11` desde `b545ef22` · **HEAD `a6e40e017`** · **11 merges**, 34 commits desde la base.

| Medición (base real, entorno del CI) | Resultado |
|---|---|
| Merges | **11, con 1 conflicto** — `backend/src/services/biometricCryptoService.js` (A-08 vs TEC-53) |
| Resolución del conflicto | **versión de TEC-53**, verificada contra la §6: **0 literales de respaldo** · control de 32 bytes presente · `jwt.js` con `getJwtSecret` y sin literales · **producción sin `BIOMETRIC_ENCRYPTION_KEY` LANZA** (no deriva del JWT) y **con clave de 64 hex arranca** |
| Compuerta anti-marcadores (desde `backend/`, como el CI) | **exit 0** |
| **Escáner de secretos (paso 7)** | **exit 0 · ✅ Sin credenciales versionadas** ⇒ **el paso 7 se pone verde por primera vez** |
| Gate de tests | **4 suites / 23 tests rojos de 586** (sólo las 4 `business*`) — `audit360` ya **verde** |
| Compuerta RLS (paso 5) | **exit 0 · ✅ AISLAMIENTO MULTI-TENANT VERIFICADO** |
| `ci.yml` del tren | `DATABASE_URL_ADMIN: postgres://postgres:***@localhost:5432/glowtest` ⇒ **el aterrizaje repara el workflow roto de `main`** (CI-44) |

**Comparación honesta, mismo protocolo:** hoy `fase-a` (`b545ef22`) da **9 suites / 55 tests rojos** ⇒ el tren de 11 **baja el rojo a 23** y pone el paso 7 en verde.

**Predicciones corregidas (error mío en la primera pasada):** dije «gate 4 suites / 17 tests» mezclando dos conjuntos. El **17** corresponde a **este tren + el arreglo de ruta de CI-40**; el tren de 11 **sin** CI-40 da **23**. Con CI-40 (su ronda 2, sólo la línea de ruta) ⇒ **17**.

**CI-40 queda fuera de esta ola**: su rama todavía trae `Test 12`, que **suma** un rojo. Entra después de su ronda 2.

---

## §8 · ATERRIZAJE EJECUTADO (2026-09-27) — verificado sobre `main`

| Paso | Estado |
|---|---|
| Autorización del Dueño | «dale» — 2026-09-27 |
| Empuje del tren a `fase-a/verdad-operativa` | **fast-forward** `b545ef225..a6e40e017`, sin `--force` |
| Merge a `main` | `main` = **`e8243432f`**, merge commit de PR #16 (padres `f5a1b4fcf` + `a6e40e017`). El Dueño lo hizo en su clon y lo empujó; GitHub marcó el PR como mergeado. **Nunca squash.** |
| §6-a · CI-30 sobrevive | ✅ producción sin `BIOMETRIC_ENCRYPTION_KEY` lanza; con 64 hex arranca |
| §6-b · ningún literal volvió | ✅ 0 en `jwt.js` y en el biométrico; escáner exit 0; anti-marcadores exit 0 |
| CI de `main` | run `36336949240`: **paso 7 verde por primera vez**, `ci.yml` válido, job de backend con 15 pasos (antes: workflow inválido sin jobs) |
| Residuo | **CI-46** (paso de preparación de la base) ⇒ los tests siguen `skipped` en GitHub |
| Fase A | **92,5 %** (aterrizaje 0,15 → 1,00) |
