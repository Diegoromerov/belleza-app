// backend/src/middleware/tenantContext.js
//
// Establece el contexto de tenant de la petición de forma TRANSACCIONAL.
//
// HISTORIA / POR QUÉ ESTE ARCHIVO CAMBIÓ
// --------------------------------------
// La versión anterior tenía tres defectos independientes, y el contexto de
// tenant NUNCA llegó a aplicarse de verdad en producción:
//
//   1. Creaba su PROPIO pool: `const pool = new Pool({ connectionString })`.
//      Un segundo pool, distinto del de config/db.js. Aunque se hubiera
//      montado, su set_config se habría aplicado a conexiones que ningún
//      controlador utiliza.
//   2. Fijaba el contexto con `pool.query(...)`, un statement suelto. Con
//      is_local = true el ajuste vive solo dentro de esa transacción implícita,
//      así que se evaporaba inmediatamente: no llegaba a ninguna consulta real.
//      El reset posterior asignaba '' — y `''::integer` lanzaría
//      'invalid input syntax for type integer' en toda política que evaluara
//      current_setting('app.tenant_id')::int.
//   3. NO estaba montado en ninguna parte. `src/startup/app.js` solo montaba
//      authMiddleware y rateLimiter; ningún archivo lo importaba. Era código
//      muerto. El único punto que fijaba app.tenant_id era auth.js:44, con
//      is_local = false — esto es, a nivel de sesión y sin reset: una fuga
//      cross-tenant. Ese bloque se ha eliminado.
//
// Ahora el contexto se fija sobre una conexión DEDICADA, dentro de una
// transacción real, con COMMIT/ROLLBACK y release garantizado (ver
// config/tenantRouting.js). Las consultas que usen el `pool` exportado por
// db.js se enrutan a esa conexión, de modo que no hay que reescribir los 335
// call sites existentes.
//
// ACTIVACIÓN
// ----------
// Opt-in mediante TENANT_TRANSACTION_PER_REQUEST=true. Con el flag desactivado
// (por defecto) este middleware es un passthrough: no abre conexión ni
// transacción, y el comportamiento de la app es idéntico al anterior.
//
// LIMITACIÓN CONOCIDA
// -------------------
// El COMMIT ocurre cuando la respuesta ya se envió (evento 'finish'), que es lo
// que permite mantener la transacción abierta durante toda la petición sin
// envolver res.send/res.json. Contrapartida: si el COMMIT falla, el cliente ya
// recibió 200 y la escritura se revierte. Es aceptable mientras el flag esté
// desactivado; si 066 lo activa en producción, conviene mover el COMMIT antes
// de enviar la respuesta interceptando res.json.

const { pool } = require('../config/db');
const tenantRouting = require('../config/tenantRouting');

async function tenantContextMiddleware(req, res, next) {
  // Sin usuario o sin tenant no hay contexto que fijar. No se abre transacción:
  // encarecería las peticiones públicas, y las políticas usan
  // current_setting('app.tenant_id', true), de modo que sin contexto devuelven
  // 0 filas en lugar de lanzar error.
  if (!req.user || !req.user.tenant_id) {
    return next();
  }

  // Modo por defecto: sin transacción por petición. El aislamiento efectivo lo
  // aplica la capa de aplicación (066). Aquí es un passthrough explícito.
  if (!tenantRouting.isPerRequestTransactionEnabled()) {
    return next();
  }

  // Marca si ya se cedió el control a la cadena de la aplicación. Sirve para
  // distinguir un fallo AL MONTAR la transacción (BEGIN/set_config: no se puede
  // servir la petición con seguridad -> 500) de un fallo DE LA CADENA de
  // aplicación, que debe reenviarse a Express en vez de enmascararse con un 500
  // genérico.
  let cadenaIniciada = false;

  try {
    await tenantRouting.runInTenantTransaction({ pool }, req.user.tenant_id, () =>
      new Promise((resolve, reject) => {
        let resuelto = false;
        const finalizar = (error) => {
          if (resuelto) return;
          resuelto = true;
          if (error) reject(error);
          else resolve();
        };

        // 'finish': la respuesta se envió correctamente.
        // 'close': el cliente se desconectó antes de terminar.
        res.on('finish', () => finalizar());
        res.on('close', () => finalizar());

        cadenaIniciada = true;
        try {
          next();
        } catch (errorCadena) {
          // Express no puede capturar un throw lanzado desde dentro de este
          // ejecutor de promesa: hay que propagarlo a mano.
          finalizar(errorCadena);
        }
      })
    );
  } catch (error) {
    if (cadenaIniciada) {
      // El fallo pertenece a la cadena de la aplicación.
      return next(error);
    }

    console.error('❌ tenantContext: fallo al montar la transacción:', error.message);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Error interno del servidor.' });
    }
  }
}

module.exports = tenantContextMiddleware;
