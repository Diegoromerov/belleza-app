# Orden — S3: probar que la compuerta puede fallar (mutación controlada, en GitHub)

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Qué es esto:** no arregla nada de producto. Prueba que la red **atrapa**: que un test roto a propósito hace que el run de GitHub quede **rojo**. Es el criterio **S3** de la Fase A, el único que falta junto con A-07.

---

## 1. PRECONDICIÓN DURA — verificá esto ANTES de tocar nada

Esta orden **sólo tiene sentido si el paso de tests ya ejecuta en `main`**. Mientras el paso de preparación de base (CI-46) siga rojo, el paso de tests queda **`skipped`** y un test roto no puede enrojecer el run: el ejercicio no probaría nada.

Comprobación (API pública, sin token, PowerShell):

```powershell
$sha = (Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/commits/main").sha
(Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/commits/$sha/check-runs").check_runs |
  Select-Object name, status, conclusion
```

- Si ves un check del **paso de tests** con conclusión `failure`, `success` o similar ⇒ **seguí**.
- Si el paso de tests **no aparece** o está **`skipped`** ⇒ **PARÁ**. Pegá la salida y reportá: «**no medible todavía: el paso de tests sigue `skipped`**». No hagas la mutación, no abras el PR. Es un cierre válido.

## 2. QUÉ HACER (cuando la precondición se cumple)

1. `git fetch origin main` y cortá la rama **`prueba/s3-gate-rojo-2026-09-27`** desde `origin/main` **recién fetcheado** (no de una ref cacheada de tu copia). Declará `git rev-parse origin/main` en tu informe.
2. **Una sola** mutación, mínima y reversible: en `backend/src/tests/seedRunner.test.js` invertí **una** aserción (por ejemplo, cambiar un `toBe(false)` por `toBe(true)` en el caso que ya existe). Un archivo, una línea.
3. Un commit único. **PR contra `main`.**
4. **NO lo mergees.** No lo arregles después. La rama se queda como está, para que el Dueño decida cerrarla.

Elegí ese archivo y no otro porque está **dentro** del gate (no cae en `testPathIgnorePatterns`) y porque su rojo es inequívocamente tuyo: no se confunde con las 4 suites heredadas de CI-43.

## 3. QUÉ MEDIR Y ENTREGAR (esto es el entregable de verdad)

1. **URL del run** de GitHub de tu PR.
2. **El paso de tests con conclusión `failure`** — pegalo tal cual, con el nombre del check.
3. **El nombre del test que falló**, exactamente como lo imprime jest (la línea del `●`).
4. **Confirmación de que las suites rojas heredadas siguen siendo las mismas 4** (`business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessSystem.integration`) ⇒ así se ve que el rojo **nuevo** es tu mutación y no otra cosa.
5. `git diff origin/main...HEAD --stat` ⇒ **1 archivo, 1 línea**. Si el diff es más grande, no es esta orden.

Si el paso de tests ejecuta y sale rojo por las 4 suites heredadas **más** tu test mutado, eso es **exactamente lo esperado**: el criterio es que tu mutación agregue su propio rojo.

## 4. PROHIBICIONES

1. **No mergear** el PR. Ni vos ni por CLI: es del Dueño.
2. **No toques `ci.yml`**: ni `testPathIgnorePatterns`, ni `continue-on-error`, ni las condiciones de los pasos. Conseguir el rojo por ahí invalida el ejercicio entero.
3. **No arregles** el test mutado después de ver el rojo: el rojo *es* el resultado.
4. No borres ramas del remoto, no `--force`, no `--force-with-lease`.
5. Nada de `NODE_TLS_REJECT_UNAUTHORIZED=0`, `-SkipCertificateCheck` ni `curl -k`.
6. No toques datos de producción ni uses la rama `fix/ci49-credencial-no-publicada` para esto: rama nueva, un propósito.
7. No imprimas credenciales, tokens ni cadenas de conexión.

## 5. DEFINICIÓN DE TERMINADO

1. Precondición verificada y **pegada** (los check-runs de `main`), o el reporte de «no medible todavía» con su salida.
2. Rama `prueba/s3-gate-rojo-2026-09-27` con **un commit, un archivo, una línea**.
3. PR contra `main`, **sin mergear**, con su URL.
4. El paso de tests del run con `failure` pegado y el nombre del test mutado.
5. Confirmación de que las 4 suites heredadas no cambiaron.
6. Declaración explícita: «el rojo nuevo es mi mutación, no otra cosa» — o el motivo por el que no lo podés afirmar.

**El veredicto lo emito yo** leyendo el run desde la API pública. Tu entrega es el run; la firma, no.
