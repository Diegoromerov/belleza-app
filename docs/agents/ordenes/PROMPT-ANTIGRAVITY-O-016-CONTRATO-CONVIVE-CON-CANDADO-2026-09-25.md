# ORDEN A · O-016 — «el contrato de enrutamiento tiene que convivir con el candado»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base:** `fix/montajes-unicos` @ **`38a9afe9`** (tu A-03, aceptada). **Rama:** `fix/contrato-convive-con-candado`.
**Prohibido:** `--force`/`--force-with-lease`; crear o borrar ramas; reescribir historia; tocar `main`, `fase-a`, migraciones, C-01/C-02/C-03, `backend/public`, `tenantRouting.js`, `COMO_EJECUTAR.md`; mergear.

## Qué encontré (ensayo de integración del tren, hecho por el Arquitecto)

Metí tus 5 entregas aceptadas en un worktree sobre el vehículo (`b545ef22`): **5 merges, 0 conflictos de texto**. Pero al correr las suites sobre el resultado integrado, **`routing.contract.test.js` (tu A-03) queda ROJO**:

```
● C2, C4: … (/api/admin/precios responde y /api/admin/precios/precios da 404)
  Expected: 404   Received: 503
```

**Medido tres veces**: sin base, con base real en `NODE_ENV=test` y con base real en `development` ⇒ **siempre 503**.

**Causa (código citado):** el candado de degradación del vehículo (`backend/src/middleware/degradedLock.js:57-59` y `:86-90`) responde **503 `DATA_LAYER_DEGRADED`** a *cualquier superficie de datos bajo `/api`* cuando el estado no está verificado o hay datos fabricados, **antes** de que el router decida el 404; y en el proceso del test el arranque nunca corre (`require('../index')` no ejecuta `app.listen` ⇒ `testConnection()`), así que con `NODE_ENV=test` el estado es «memoria/fabricado» ⇒ siempre 503. Tu test **no menciona el candado**: se escribió sobre A-03, que nace antes de que el candado existiera. **No es un fallo de enrutamiento** — tus otros dos casos siguen pasando.

**Consecuencia:** aterrizar el tren tal cual mete un test rojo en el PR que va a `main`.

## Cargo 1 — el caso C2/C4 determinista

Hacé que el caso declare **el estado en el que corre** y sea válido en los dos:

1. Si el candado está activo, «404» no es la respuesta correcta para esa URL ⇒ elegí **una** de estas dos vías y justificala:
   - **(A) aislar el enrutamiento**: montar en el `testApp` la superficie de enrutamiento **sin** el candado (es lo que el test dice medir: el contrato de montajes), o
   - **(B) declarar ambos desenlaces**: `404` cuando el estado está sano y `503 DATA_LAYER_DEGRADED` cuando está degradado — con el candado **consultado**, no asumido.
2. **Sin perder el poder de caza**: el caso debe seguir poniéndose rojo si vuelve el prefijo duplicado. **Mutación pegada** (anclada en código): `app.use('/api/admin', adminPreciosRoutes)` ⇒ `'/api/admin/precios'` ⇒ el caso debe caer. Pegá la salida RED.
3. **Nada de `NODE_ENV` como interruptor** del test, y nada que dependa de que la base esté arriba o abajo: el caso tiene que dar lo mismo en las dos.

## Cargo 2 — dejarlo escrito

En el propio test, un comentario breve (2-4 líneas) que diga **qué mide** (contrato de montajes: un router, un prefijo) y **por qué** la URL inexistente puede dar `503` en vez de `404` (el candado responde antes que el router). Quien lo lea en seis meses tiene que entenderlo sin este hilo.

## Cargo 3 — nada

No hay tercer cargo. Si algo no se puede cumplir: **parás y reportás el motivo medido**.

## Entrega

`git log -1 --format='%h %s'` + `git status --porcelain`; la corrida del test **en los cuatro escenarios** (con/sin base × `test`/`development`) mostrando el mismo resultado; la mutación pegada (RED→GREEN); y la declaración de que no tocaste el candado ni el vehículo. **No** integres tu rama en nada: el aterrizaje lo decide el Dueño.
