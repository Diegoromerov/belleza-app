// backend/src/config/tenantRouting.js
//
// Enrutado de consultas a la conexión de la petición, vía AsyncLocalStorage.
//
// PROBLEMA QUE RESUELVE
// ---------------------
// El aislamiento por tenant necesita que la conexión que ejecuta las consultas
// sea la MISMA en la que se fijó app.tenant_id. Con un pool, `pool.query()`
// toma cualquier conexión libre, así que fijar el contexto en el middleware no
// garantiza nada para las consultas posteriores.
//
// Este repositorio tiene 335 llamadas a `pool.query` repartidas en 67 archivos.
// Reescribirlas para inyectar un cliente sería un cambio enorme y frágil. En su
// lugar, el `pool` exportado por db.js (un wrapper propio, no el Pool crudo) se
// limita a preguntar aquí si la petición tiene una conexión dedicada: si la
// tiene, la usa; si no, delega en el pool. Los 335 call sites no cambian.
//
// LÍMITES DEL ALCANCE (importante)
// --------------------------------
// Esta pieza NO activa transacciones por petición. Solo provee el mecanismo y
// la decisión de activación (opt-in por variable de entorno, ver
// TENANT_TRANSACTION_PER_REQUEST en .env.example). Con el flag desactivado el
// comportamiento es idéntico al actual.

const { AsyncLocalStorage } = require('async_hooks');

const storage = new AsyncLocalStorage();

/** true si la petición en curso tiene una conexión dedicada. */
function isRouting() {
  const store = storage.getStore();
  return Boolean(store && store.client);
}

/** Cliente dedicado de la petición en curso, o null. */
function getActiveClient() {
  const store = storage.getStore();
  return (store && store.client) || null;
}

/**
 * Ejecuta `fn` de modo que toda consulta hecha con el `pool` exportado use
 * `client`. Se usa para envolver el resto del ciclo de vida de la petición.
 */
function runWithClient(client, fn) {
  return storage.run({ client }, fn);
}

/** ¿Está activado el modo transacción-por-petición? */
function isPerRequestTransactionEnabled() {
  return process.env.TENANT_TRANSACTION_PER_REQUEST === 'true';
}

/**
 * Ejecuta `fn` dentro de una transacción dedicada con el tenant fijado de forma
 * LOCAL a esa transacción, y libera la conexión siempre.
 *
 * El cliente se obtiene con `pool.connect()` (el wrapper de db.js), de modo que
 * si Postgres no está disponible el cliente degradado también funciona y no se
 * abre ninguna transacción real.
 *
 * @param {{ pool: {connect: Function} }} deps
 * @param {number|string|null} tenantId
 * @param {(client: object) => Promise<any>} fn
 */
async function runInTenantTransaction(deps, tenantId, fn) {
  const client = await deps.pool.connect();
  let began = false;

  try {
    await client.query('BEGIN');
    began = true;

    // set_config con is_local = true: el ajuste vive solo dentro de esta
    // transacción y desaparece en el COMMIT/ROLLBACK. Es lo contrario del
    // set_config(..., false) de auth.js, que persistía en la conexión del pool
    // y permitía que otra petición heredara el tenant anterior.
    if (tenantId !== null && tenantId !== undefined && `${tenantId}` !== '') {
      await client.query('SELECT set_config($1, $2, true)', [
        'app.tenant_id',
        `${tenantId}`,
      ]);
    }

    const result = await runWithClient(client, () => fn(client));

    // COMMIT explícito. Sin esto la conexión vuelve al pool con la transacción
    // abierta ("idle in transaction"): el trabajo se perdería y la conexión
    // quedaría retenida hasta que el pool la recicle.
    await client.query('COMMIT');
    began = false;

    return result;
  } catch (error) {
    if (began && typeof client.query === 'function') {
      try {
        await client.query('ROLLBACK');
        began = false;
      } catch (rollbackError) {
        console.error('tenantRouting: fallo al hacer ROLLBACK:', rollbackError.message);
      }
    }
    throw error;
  } finally {
    try {
      if (typeof client.release === 'function') client.release();
    } catch (releaseError) {
      console.error('tenantRouting: fallo al liberar la conexión:', releaseError.message);
    }
  }
}

module.exports = {
  storage,
  isRouting,
  getActiveClient,
  runWithClient,
  isPerRequestTransactionEnabled,
  runInTenantTransaction,
};
