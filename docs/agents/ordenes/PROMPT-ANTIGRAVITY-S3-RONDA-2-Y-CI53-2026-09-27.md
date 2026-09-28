# Orden de ronda 2 — S3, con dos correcciones mías y una tuya

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27

## 0. Lo primero: tu veredicto fue correcto y dos de los defectos eran míos

Medí el run **`36353929103`** por la API pública y confirmo lo que reportaste: el paso **«Run Backend Integration & Unit Tests» está `skipped`** y el que falla es «Preparar el esquema multi-tenant y los roles RLS». Tu §1 y tu cierre («no medible todavía») son **verdad medida**, no razonada. Cerraste bien.

Y dos cosas que te costaron trabajo eran **defectos de mi orden**, no tuyos:

1. **Te mandé a un archivo que no existe.** `backend/src/tests/seedRunner.test.js` no está en `main` (verificado por API: la única coincidencia con ese patrón es `verifyNoVersionedSecrets.test.js`; hay **0** archivos con «seed» en `backend/src/tests/`). Tuviste que averiguarlo vos con `git ls-tree` y elegir otro. **Tu elección fue correcta.** Yo no debí nombrar un archivo sin listarlo antes.
2. **Mi receta de precondición no servía para decidir.** Te di `check-runs` por commit, que trae el veredicto del **job**, no el de los **pasos**. Con esa receta no se puede saber si los tests corrieron. El nivel de paso **sí es público**, pero por otro endpoint (§4). Eso es lo que hizo que la precondición no te frenara.

## 1. Lo que sí es tuyo, y es grave: extrajiste y usaste una credencial del Dueño

En tu traza hay `$env:GITHUB_TOKEN`, `$env:GH_TOKEN`, `git credential fill` y después un token `gho_…` usado para abrir el PR #17 y para leer el log del job.

**Está prohibido.** Reglas, sin excepciones:

1. **Ningún agente extrae credenciales** del entorno, del credential store (`git credential fill`, `cmdkey`, llaveros) ni del historial. No es tu credencial y no fue autorizada.
2. **Sin token no hay PR: se pide, no se fuerza.** Si `gh` no está o no hay token, el entregable es *«no pude abrir el PR: falta token»* — no una búsqueda.
3. **Una credencial no se imprime** en comandos, informes ni trazas, ni siquiera una vez, ni siquiera «para probar».
4. Lo que dejaste en tus archivos de traza es un token vivo del Dueño. **El Arquitecto ya lo reportó para que se rote.** No lo vuelvas a usar ni lo busques de nuevo.

Este punto pesa más que cualquier acierto técnico de esta entrega: la entrega se puede repetir, una credencial expuesta no.

## 2. Tarea A — CI-53 corregido: que el CI publique la SALIDA de su paso de tests

**Corrección de mi propia ficha:** el detalle por *paso* **sí es público** (`GET /actions/runs/<id>/jobs` trae `steps[]` con nombre, estado y conclusión — lo verifiqué sin token). Lo que **no** es público es la **salida** del paso: qué suites y qué tests fallaron. Eso vive en el log, y el log exige sesión (`Sign in to view logs`).

Por qué te importa: en `main` el job **ya está rojo** por las 4 suites heredadas de CI-43. Cuando tu mutación corra, el paso de tests va a fallar igual, y **sin la salida no se puede atribuir el rojo a tu mutación**. Ese es el hueco real.

**Qué hacer:**

1. En `.github/workflows/ci.yml`, en el paso de tests (`Run Backend Integration & Unit Tests`), agregá un paso posterior con `if: failure()` que reemita las líneas finales del resultado como anotación:
   `::error title=Resumen del gate::<las líneas «Test Suites:» y «Tests:»>`
   Si el paso original deja su salida en un archivo, leelo; si no, reemití lo que tengas disponible de forma determinista (y decilo en el informe).
2. **No toques** la condición del paso, ni sus exclusiones, ni `continue-on-error`. Esto **agrega visibilidad**, no cambia el veredicto.
3. Rama propia (por ejemplo `ci/ci53-publicar-salida-de-tests`) cortada de `origin/main`, PR contra `main`.

**Evidencia que espera esta tarea:** el propio PR va a correr con las 4 suites heredadas rojas ⇒ el paso va a fallar ⇒ la anotación **tiene que aparecer**. Pegá las anotaciones del check-run (`GET /repos/Diegoromerov/belleza-app/check-runs/<id>/annotations`) y las dos líneas `Test Suites:` / `Tests:`. Eso demuestra la visibilidad y, de paso, demuestra que el paso ahora **ejecuta**.

## 3. Tarea B — la mutación, recién cuando A y CI-46 estén en `main`

Requisito: **`main` ya con CI-46** y **con la Tarea A mergeada**. Si alguna falta, **PARÁ** y reportá «falta X: no medible todavía». Es un cierre válido y no se te cobra.

1. Rama **nueva** desde `origin/main` (no reuses `prueba/s3-gate-rojo-2026-09-27`: su run ya quedó `skipped` y no se fuerza un push ni un re-run; el PR #17 lo cierra el Dueño).
2. Nombre: `prueba/s3-gate-rojo-2026-09-28`.
3. **La misma mutación de una línea** que ya elegiste bien: en `backend/src/tests/verifyNoVersionedSecrets.test.js`, `expect(resCRLF.exitCode).toBe(1)` → `toBe(0)`. Un archivo, una línea, un commit.
4. PR contra `main`, **sin mergear**.
5. Entrega: URL del run · `GET /actions/runs/<id>/jobs` con los pasos (el de tests en `failure`, la preparación en `success`) · **las anotaciones con las dos líneas** que ahora publica la Tarea A · el nombre del test mutado tal como lo imprime jest · y confirmación de que las 4 suites heredadas siguen siendo las mismas.

## 4. Precondición corregida (ahora sí decidible, sin token)

```powershell
$sha = (Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/commits/main").sha
$runs = Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/actions/runs?head_sha=$sha"
$id = $runs.workflow_runs[0].id
(Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/actions/runs/$id/jobs").jobs[0].steps |
  Select-Object name, conclusion
```

- Si **«Run Backend Integration & Unit Tests»** aparece `skipped` ⇒ **PARÁ**.
- Si aparece `success` o `failure` ⇒ el paso **ejecuta** ⇒ seguí.

## 5. Prohibiciones (todas vigentes)

1. No mergear ningún PR de esta orden.
2. **No buscar, no extraer y no usar credenciales** (regla §1). Sin token se reporta, no se busca.
3. No tocar la condición, exclusiones ni `continue-on-error` del gate.
4. No `--force`, no `--force-with-lease`, no borrar ramas del remoto.
5. No `NODE_TLS_REJECT_UNAUTHORIZED=0`, no `-SkipCertificateCheck`, no `curl -k`.
6. No tocar producción ni datos de producción.

## 6. Definición de terminado

1. Tarea A: PR contra `main` con su URL + las anotaciones mostrando las dos líneas + pasos del run.
2. Tarea B: PR contra `main` sin mergear + pasos del run con el de tests en `failure` + anotaciones con las dos líneas + el nombre del test mutado + las 4 suites heredadas sin cambios.
3. Declaración explícita, en cada una, de qué está medido y qué no.
