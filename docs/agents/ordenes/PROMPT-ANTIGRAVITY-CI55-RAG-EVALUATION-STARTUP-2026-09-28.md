# Orden — CI-55: `rag-evaluation.yml` falla al arrancar en Actions

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-28

## 0. Antes de empezar: dos cosas que ya están resueltas y una convención nueva

1. **CI-54 y el motor del runner: cerrado.** Medí el run `36453827505`: `Setup Node.js 22` ✓, la preparación de base y la compuerta RLS ✓, y el gate ahora corre **592 tests** (`Test Suites: 4 failed, 73 passed, 77 total · Tests: 23 failed, 1 skipped, 568 passed, 592 total`). Tu hallazgo del motor era correcto y `22.x` fue el objetivo correcto. Y sobre tu medición: el contraste `node:20` estaba contaminado por `npx` (instala su propio Babel y resuelve fuera del árbol ⇒ el `Cannot find module` no era el error del CI). Quedá registrado como trampa; la lección, para las dos partes: **una comparación exige la misma invocación en las dos imágenes, y el error que se cita como prueba tiene que ser el mismo error del fenómeno que se quiere explicar.**
2. **El merge directo de CI-54 a `main` fue autorizado por el Dueño.** No se te imputa. Pero **nueva convención (D-019)**: cuando el Dueño autorice un merge directo, **dejá constancia** en el mensaje del commit (una línea: `Autorizado por el Dueño (fecha)`) y en la KB. Nada registraba esa autorización y desde afuera es indistinguible de un push no autorizado.
3. **La mutación S3 no es tarea tuya**: el PR lo abre el Dueño (D-018 / sin token). No lo crees.

## 1. El defecto ya está encontrado — no lo busques, arreglalo

`rag-evaluation.yml` **parsea bien como YAML** (`js-yaml` lo carga, 5 jobs declarados) y sin embargo **sus 5 últimos runs fallan con `jobs=0`**, incluido el de `main`. La causa, medida con `actionlint` (imagen oficial `rhysd/actionlint`, corrida por el Arquitecto):

```text
.github/workflows/rag-evaluation.yml:238:17: context "secrets" is not allowed here.
available contexts are "env", "github", "inputs", "job", "matrix", "needs", "runner", "steps", "strategy", "vars".
   238 |         if: ${{ secrets.RAILWAY_DEPLOY_HOOK }}
```

`secrets` **no es un contexto válido en un `if:`**. Cuando GitHub encuentra eso **invalida el archivo entero en el arranque** y no crea ningún job: de ahí el `failure` con `jobs=0` en cada push. `yaml.safe_load` no lo ve porque el YAML es correcto — es una restricción de **esquema/expresión**, no de sintaxis.

`ci.yml` sale **limpio** con el mismo linter: no lo toques.

**Patrón del arreglo** (el detalle lo decidís vos): el secreto entra por `env` y el `if` consulta el env, que sí es un contexto disponible ahí:

```yaml
- name: Deploy gate
  if: env.RAILWAY_DEPLOY_HOOK != ''
  env:
    RAILWAY_DEPLOY_HOOK: ${{ secrets.RAILWAY_DEPLOY_HOOK }}
  run: ...
```

Si el `if` de la línea 238 está a nivel de **job** y no de step, la variable va en el `env` del job. Mirá la línea 238 antes de escribir.

## 2. Qué arreglar y qué no

- **Arreglá sólo lo que impide que Actions arranque el workflow.** Un esquema roto en un `jobs.<id>.if`, una expresión inválida en `env`, un contexto no disponible, un `uses` mal formado: eso.
- **No toques**: la lista de jobs, los triggers (`push` con `paths`, `pull_request`, `schedule`, `workflow_dispatch`), ni un `continue-on-error`. Un workflow que arranca porque le sacaste el trabajo no arregla nada.
- **Si `actionlint` también marca `ci.yml`**: reportá sus hallazgos **y no toques `ci.yml`**. El gate del CI ya está medido y andando; no se toca en esta orden.
- Rama propia desde `origin/main`, PR contra `main`. Si el Dueño autoriza el merge directo, dejá la constancia del §0.2; si no, el PR queda para él.

## 3. Entregables

1. Salida de `actionlint` **antes** (el error) y **después** (limpia) para `rag-evaluation.yml`.
2. `git diff --stat` contra `main`: idealmente 1 archivo. Si tocás más, justificá cada uno.
3. La lista de jobs del workflow, **sin cambios** (los mismos 5 nombres).
4. Declaración explícita de qué quedó medido por vos y qué no.

## 4. Criterio de aceptación (medible, y lo cierra el Dueño)

**Un run de ese workflow con `jobs > 0`.** El workflow tiene `workflow_dispatch`, así que el Dueño puede dispararlo desde la UI; después se lee con:

```powershell
(Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/actions/runs?per_page=1").workflow_runs[0].id
(Invoke-RestMethod "https://api.github.com/repos/Diegoromerov/belleza-app/actions/runs/<id>/jobs").jobs | Select-Object name, conclusion
```

`jobs=0` otra vez ⇒ no está resuelto, aunque `actionlint` esté limpio. **El juez es el run, no el linter.**

## 5. Prohibiciones

1. No mergear ni pushear a `main` (salvo autorización del Dueño, con la constancia del §0.2).
2. **D-018**: cero búsqueda o uso de credenciales. Sin token se reporta, no se busca.
3. No deshabilitar el workflow, ni vaciarlo, ni cambiar sus triggers para que no dispare. Que arranque vacío no es que funcione.
4. No `--force`, no borrar ramas del remoto, no TLS desactivado.

## 6. Lo que NO entra en esta orden

- La mutación S3 (PR del Dueño) y la firma de A-07 (decisión del Dueño).
- El token expuesto: rotación a cargo del Dueño.
