# Orden — CI-54: el motor del runner. Objetivo corregido de 20.x a 22.x

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-28

## 0. Reconocimiento: tu hallazgo es correcto y el CI lo confirma

Antes de corregirte, lo que hiciste bien:

1. **La causa raíz del gate, encontrada por vos.** El resumen que ahora publica el propio CI (Tarea A, ya en `main`) lo dice con tus palabras: `Test Suites: 77 failed, 77 total · Tests: 0 total`, con `[BABEL]: You appear to be using a native ECMAScript module plugin…` y decenas de `● Test suite failed to run`. En el runner **no carga ninguna suite**. Eso no lo sabíamos: hasta hoy el paso estaba `skipped` y yo comparaba contra un baseline **local** de 4 suites rojas que **nunca** describió al CI.
2. **D-018 cumplida.** Revisé tu traza: no sondeaste tokens, no usaste credenciales y **no abriste PRs** — dejaste los links para que los abra el Dueño. Eso es exactamente lo que la regla pedía.
3. **El diff de la mutación, limpio**: `prueba/s3-gate-rojo-2026-09-28` = 1 archivo / 1 línea contra `main`. Correcto.

## 1. La corrección: **20.x no alcanza**

Tu parche cambia `node-version: '18.x'` → `'20.x'`. Medido en el árbol:

```
@babel/preset-env                v8.0.2  engines={"node": "^22.18.0 || >=24.11.0"}  type=module
@babel/plugin-transform-runtime  v8.0.1  engines={"node": "^22.18.0 || >=24.11.0"}  type=module
joi                              v18.2.3 engines={"node": ">= 20"}
```

(rutas: `backend/node_modules/@babel/preset-env/package.json`, `…/@babel/plugin-transform-runtime/package.json`)

El error real no es «falta un flag»: es que `babel-jest` intenta cargar en forma **síncrona** plugins que son **módulos ESM nativos**, y eso sólo lo resuelve un Node que soporte `require()` de ESM. Con el `engines` declarado, **Node 20 queda por debajo del requisito** y probablemente reproduzca el mismo `[BABEL]`. Con 20.x, tu PR entra y el gate sigue en `Tests: 0 total`.

**Cambiá el objetivo a `22.x`** (o `24.x`): es el parche que el `engines` del propio paquete respalda.

## 2. La medición que falta (y es la que decide)

Corré **una sola suite** en contenedor limpio, dos veces, y pegá las dos salidas:

```bash
docker run --rm -w /app node:20 sh -c "cd /app && npx jest src/tests/verifyNoVersionedSecrets.test.js"   # inyectando el árbol como ya lo hacés
docker run --rm -w /app node:22 sh -c "cd /app && npx jest src/tests/verifyNoVersionedSecrets.test.js"
```

- En **20**: si aparece `[BABEL]`/`failed to run` ⇒ confirma que 20 no alcanza.
- En **22**: la suite tiene que **cargar** (verde o rojo por aserciones, pero ejecutando tests).
- Si en 22 **tampoco** carga ⇒ **no propongas el cambio**: reportá y escalá a 24.x.

Declaralo como medición tuya, con la salida pegada. Yo intenté reproducirlo desde Windows con bind mount y no terminó en tiempo razonable; esa vía queda descartada y no te la cobro ni te la pido.

## 3. Criterio de aceptación — medible con lo que ya construimos

Cuando el PR de CI-54 esté en `main`, el resumen que publica el paso `Publicar salida del gate de tests (anotacion)` **deja de decir `Tests: 0 total`**. Ese es el número que importa:

- `Tests: 0 total` ⇒ sigue roto, aunque el paso «pase».
- `Tests: <n>` con `n > 0` ⇒ las suites cargan y el gate dice la verdad.

Pegá la línea del run que lo demuestre (`GET /actions/runs/<id>/jobs` + las anotaciones del check-run).

## 4. Prohibiciones

1. No tocar la **condición** del paso de tests, ni sus **exclusiones**, ni agregar `continue-on-error`. Un gate que pasa porque dejó de mirar no es un gate.
2. No ampliar `testPathIgnorePatterns` para «que pase».
3. No mergear nada: el PR lo abre y lo mergea el Dueño.
4. **D-018**: nada de buscar, extraer o usar credenciales. Sin token se reporta, no se busca.
5. No `--force`, no borrar ramas del remoto, no TLS desactivado.

## 5. Lo que NO es tu tarea (para que no lo mezcles)

1. **La mutación S3** espera a que esto esté en `main`. Con `Tests: 0 total`, cualquier mutación es invisible: el rojo ya está en todas las suites.
2. **El PR de la mutación lo tiene que abrir el Dueño.** Medido: `ci.yml` corre en PRs y en `main`, pero **no** en pushes a ramas — el push de tu rama de mutación sólo disparó `rag-evaluation.yml`, que falló **sin jobs**. No crees el PR con credenciales: dejá el link, como hiciste.
3. **CI-55 (nuevo, no ahora)**: `rag-evaluation.yml` aparece como `failure` con **0 jobs** en push de rama. Es la firma de un workflow inválido o vacío. Queda registrado; no lo toques en esta orden.

## 6. Definición de terminado

1. Rama con `node-version` en **22.x** (o 24.x) y el diff mostrado (`+/-` de una o dos líneas, sólo `ci.yml`).
2. Las **dos** salidas de contenedor (20 y 22) pegadas, con la suite cargando en 22.
3. Declaración explícita de qué quedó medido por vos y qué no.
4. El link para que el Dueño abra el PR.
