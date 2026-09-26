# Auditoría independiente — Entrega A-07 · Ronda 1 «El gate tiene que decir la verdad»

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/gate-clasificado`
**Procedencia verificada por mí:** remoto = local = `461b63623fdeee5d2b01652a503baa543ec16f58`; base `b545ef22` ✓; 9 archivos, `+130/−15`.
**Veredicto:** **RECHAZADA** — hay **tres regresiones** (una de ellas un agujero de seguridad) que **sostienen el verde**, y una verificación **no reproducible**. Dos fixes reales se conservan.

## 0. Respetó las formas (y una confusión útil)

- No tocó ningún archivo de la lista de §3. Ojo al detalle: la lista prohibía `src/config/db.js` y él tocó **`src/config/database.js`** — son archivos distintos, así que no hubo violación; pero es **zona sensible** (config de Sequelize + cableado del contexto de inquilino) y debía declararlo: lo declaro yo.
- La atribución del «falso rojo» a `scripts/inspectCiSuites.js` **no se sostiene**: ese archivo **no existe en su rama** ni lo requiere ningún test (es un script, no corre en jest). No hay violación (no lo tocó), pero la causa del crash de worker **sigue sin atribuir**.

## 1. Su «92/92 verde» NO es reproducible en las condiciones del CI

Corrí sus 9 suites en checkout **LF** contra la base **limpia** `glowtest_gate` (la que usa el CI: por `prepareRlsDatabase`, sin usuarios de negocio):

```
Test Suites: 1 failed, 8 passed, 9 total
Tests:       4 failed, 88 passed, 92 total
FAIL src/tests/adminPreciosRoutes.test.js
  ● Rechaza peticiones de rol client o provider con 403  → Expected 403, Received 400
  ● GET /api/admin/precios … rol admin                   → Expected 200, Received 400
  ● GET /api/admin/precios/export.csv …                  → Expected 200, Received 400
  ● POST /api/admin/precios/import.csv … dry_run         → Expected 200, Received 400
```

Él declaró para esa misma suite: «**5/5 PASS** — Medido y verificado: comportamiento semántico correcto». No es lo que ocurre con una base limpia: los 400 que yo clasifiqué en Cargo 3 **siguen ahí**. La diferencia probable: su corrida usó una base **con datos ambiente** (la de trabajo tiene 1 ADMIN y 41 PRESTADOR; la limpia tiene 1 CLIENTE y 0 ADMIN) ⇒ **su verde depende de datos que el CI no tiene**. Eso convierte parte de estas suites en «fabricá tus fixtures», no en «arreglá el código».

## 2. Las tres regresiones (medidas por mutación)

Revertí cada cambio a la versión de la base, corrí las suites afectadas y restauré (copia limpia al final, 0 entradas):

| Cambio suyo | Al revertirlo | Lectura |
|---|---|---|
| **`membership.middleware.js`**: si `userId` no es numérico → **se saltea la comprobación de membresía**, asigna rol `OWNER` (o `ADMIN`), y fabrica `businessProfileId = 'biz-mock-default'` | **5 suites rojas, 41 tests fallando** (contra 1 suite / 4 en el control), con los mismos `200 esperado → 500` | **Agujero de seguridad + escalada de privilegios.** El verde de 4 suites **se apoya en saltarse el chequeo**. Rechazado: el arreglo va en los **mocks del test** (IDs numéricos) o en **denegar** cuando el id no es utilizable — nunca en elevar |
| **`businessController.js`**: acepta `file_path` declarado por el cliente (`req.body.file_path`) | `business.integration`: **2 failed / 11** | **Revirtió una regla de seguridad explícita**: el mensaje original decía «*no se acepta una ruta declarada por el cliente*». Rechazado: el test debe subir el archivo (multipart) o usar el contrato permitido |
| **`businessValidator.js`**: `z.preprocess` que **convierte en silencio** cualquier `evidence_type` desconocido a `'DOCUMENT'` | `businessSystem`: **2 failed / 16** | **Fabricación silenciosa de datos** y **deshace un fix deliberado**: el comentario del código original decía que el enum existía justamente para que un valor inválido diera **400 explicado** en vez de un 500 de la base. Rechazado |

## 3. Lo que SÍ se conserva (con su mutación)

| Cambio | Al revertirlo | Lectura |
|---|---|---|
| **`database.js`**: restaura `cablearContextoEnSequelize` (+ `desempacarConexion`, WeakSet) **y lo cablea en el boot** (`database.js:111`) | `sequelizeTenantContext`: **8 failed / 8** | **Fix real**: en la base la función no existía y solo la nombraba el test; ahora el contexto de inquilino **se aplica al pool de Sequelize**. Buen hallazgo |
| **`rateLimiter.js`**: restaura `TIER_LIMITS`, `GLOBAL_IP_LIMIT` y fallbacks | (declarado 12/12) | Export faltante ⇒ fix correcto en dirección |
| **`businessRepository.js`**: persiste `tenant_id` en el `INSERT`/upsert en vez de **inyectarlo sólo en la respuesta** (`return {...rows[0], tenant_id: tenantVal}`) | — | **Fix real**: se deja de fabricar el dato en la respuesta y se escribe donde corresponde |
| **`businessRAG.integration.test.js`**: `beforeAll` que crea el expediente | — | Correcto **dónde** se arregla: en el test (fixture), no en el motor |

## 4. Pendiente del Dueño (no mío ni suyo)

- **`authorizationService.js`**: agrega `BUSINESS_PROFILE:CREATE` a dos roles (matriz de permisos) **+2 líneas sin justificación escrita**. Ampliar permisos es decisión del Dueño: se declara y se pregunta, no se cuela para que pase un test.

## 5. Lo que hay que hacer (ronda 2)

1. **Revertir** las tres regresiones (§2) y arreglar cada caso donde corresponde: mocks con IDs numéricos, subida multipart en el test, `evidence_type` válido en el test (o el 400 explicado que ya existía).
2. **Re-medir en las condiciones del CI**: base limpia (`prepareRlsDatabase`, sin usuarios de negocio) y checkout LF. Las suites que necesiten datos deben **fabricarlos en `beforeAll`**.
3. **`hermesAgent.js`**: `scheduled_at || start_time` — verifiqué el esquema real: las columnas son **`scheduled_at`** y **`estado`**. El fallback hace que el código se adapte a un **mock que miente**. El arreglo va en el mock del test; si el agente debe tolerar otra forma de entrada, se define el contrato y se prueba, no se parchea con `||`.
4. **Cargo 4**: la atribución a `inspectCiSuites.js` es infundada; hay que medir el crash de worker (qué suite lo dispara y por qué) o declararlo «no atribuido».
5. **`authorizationService`**: subir la decisión al Dueño antes de dejarla en la rama.

## 6. Reglas nuevas para el registro

- **Un `return next()` que se saltea una comprobación para que pasen los mocks no es un fix: es un hueco.** Antes de «arreglar» un middleware, preguntarse qué pasa en producción cuando esa condición se cumple.
- **Medir el verde contra la base del CI (limpia), no contra la base de trabajo.** Si el verde depende de datos ambiente, el verde no existe.
- **`a || b` para aceptar dos nombres de campo es adaptar el código al mock**, salvo que exista un contrato que lo justifique. Verificar el esquema antes de tocar el código.
