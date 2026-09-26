# Auditoría independiente — Entrega A-08 · RONDA 2 «Que el test muerda»

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/caminos-muertos`
**Procedencia verificada por mí:** remoto = local = `063b19e0a8b7b162118145d5aeb44685838f1181`; `ad4f94f8` es ancestro ✓; base `b545ef22` ✓; árbol limpio.
**Método:** lectura del diff + **mutación propia** (no la suya) + corrida real en checkout **LF**, en worktree propio (`scratch/a08r2/wt`), sin tocar el del Ejecutor.
**Veredicto:** **ACEPTADA.** Los dos cargos quedan probados por medición mía, y con esto **A-08 se cierra**.

## 1. Cargo nuevo 1 — el test de CI-21 ahora muerde

Lo que cambió (diff `ad4f94f8..063b19e0`, 3 archivos, +20/−4):
- `paymentJobs.js`: **+1 línea** — `comoSistema` pasa a exportarse (para poder invocarlo desde el test). No cambia lógica.
- `tenantRoutingUnhandled.test.js`: el hijo ahora hace `require('./backend/src/jobs/paymentJobs')` y ejecuta `comoSistema(async () => 'ok')()` **dentro de `setImmediate`, sin `await` ni `.catch()`** ⇒ invoca **por el camino de producción** y no adjunta manejador.

**Mutación del auditor** (la única prueba que vale): quité la guarda `try/catch` de `comoSistema` dejándolo como `const comoSistema = (job) => () => runAsSystem({ pool }, () => job());` (`node --check` OK) ⇒ **el test pasa a ROJO** (`Tests: 1 failed, 1 total`). Restaurado con `sha256` idéntico al original.

⇒ **Correcto donde la ronda 1 fallaba**: antes la mutación lo dejaba verde; ahora lo voltea. El cargo queda probado.

## 2. Cargo nuevo 2 — round-trip en producción

- El test existe y hace lo que corresponde: fija `NODE_ENV='production'` + una clave válida de 32 bytes, cifra un objeto, exige que el cifrado tenga 3 partes y **descifra comparando igualdad con el original** ✓ (no sólo «no lanza»).
- **Sin fuga de entorno**: el `beforeEach` del archivo restaura `NODE_ENV` y borra `BIOMETRIC_ENCRYPTION_KEY`/`ENCRYPTION_KEY` antes de cada test ⇒ la mutación de entorno está contenida (lo verifiqué leyendo el archivo, no asumiéndolo).
- **El servicio no se tocó en la ronda 2** (0 líneas de diff en `biometricCryptoService.js`) ⇒ el comportamiento de producción sigue siendo el de la ronda 1, sin cambios escondidos.
- Su declaración es **exacta**: `decryptWithLegacyKey()` es **preexistente** (aparece en `dc8c570c`, y ya estaba en `b545ef22`), no la introdujo A-08; y no se migraron datos.

## 3. Hallazgo colateral (refuerza CI-31)

Su `37/37 PASS` es **cierto en su checkout**: pero está medido en **CRLF**. En **LF** la misma corrida de las 3 suites da **36/37**, y la que cae es `audit360-remediation` → el test del escáner de credenciales (`no hay credenciales en archivos trackeados`), que en CRLF **no ve nada** y por eso pasa.
⇒ No es un error de la entrega; es la misma ceguera al CRLF de CI-31. Refuerza que **el verde del guardián de secretos depende hoy de los finales de línea** y que A-06 r5 (que sí es tolerante: 8 = 8) es la pieza que lo corrige.

## 4. Nits (no bloquean)

- El hijo del test declara un `deadPool` que **no usa** (el wrapper importado usa el pool real). Es código muerto dentro de un test que trata sobre caminos muertos: cosmético.
- Residual ya declarado al Dueño: el wrapper registra el fallo pero **no lo cuenta**; un job de pagos que falla se distingue sólo por una línea de log (decisión suya, no de la entrega).

## 5. Cargos de A-08, cerrados

| Cargo | Estado |
|---|---|
| Cargo 1 — CI-21 (rechazo sin manejar) | **cerrado**: cura en el wrapper de `paymentJobs` + test que muerde (verificado por mutación propia) |
| Cargo 2 — CI-12 (suite nunca coleccionada) | **cerrado** en ronda 1 (+ round-trip de producción agregado ahora) |
| Cargo 3 — TEC-72 (log falso de migración) | **cerrado** en ronda 1 (contrafactual 78 → 0) |
| Cambio de cripto en producción (CI-30) | **abierto a decisión del Dueño** — declarado y acotado, no se mergea por mi auditoría |
