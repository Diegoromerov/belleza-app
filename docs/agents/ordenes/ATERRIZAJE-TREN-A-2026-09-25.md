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
| suites clave sobre el tren | **10 suites / 45 tests verdes** |
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
         fix/compuerta-secretos-reproducible; do
  git merge --no-edit "$r" || { echo "CONFLICTO en $r — PARAR y reportar"; exit 1; }
done

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
- **Pero el paso bloqueante de tests sigue rojo por deuda heredada.** Medido hoy sobre el tren: **10 suites rojas de 75**
  (`adminPreciosRoutes`, `business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`,
  `businessRAG.integration`, `businessSystem.integration`, `rateLimiter`, `sequelizeTenantContext`, `sprint2_agents`, y
  `audit360-remediation` que sí cae por la causa de CI-14). Es la deuda que el propio `ci.yml` declara en un comentario
  (citaba «15»; hoy son 10 en el gate y 19 en la suite completa).
  **Ojo con el recuento**: medido en 4 corridas, el gate da **10, 11, 11 y 12** suites rojas — el núcleo de **10 es estable** (aserción
  real) y lo demás son **falsos rojos** que no corren por un crash del worker de jest (medido: `ciRagEvaluation` y `ownerMultiSalonDashboard`,
  esta última con sus 4 tests en verde). `--maxWorkers=2` **no** lo arregla (muda el crash). ⇒ En el PR hay que leer **cuáles** fallan,
  no cuántas.

  ⇒ **Decisión explícita del Dueño**: aterrizar aceptando ese backend rojo por deuda heredada (documentado), o abrir las
  10 suites como trabajo propio antes de aterrizar.

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
