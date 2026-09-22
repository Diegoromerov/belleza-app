const { Sequelize } = require('sequelize');
const tenantRouting = require('./tenantRouting');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL;

/**
 * ¿Hay que negociar TLS con este servidor?
 *
 * Antes, la rama de DATABASE_URL ponía `ssl.require = true` siempre. En un
 * Postgres local (contenedor de CI, docker-compose) eso hace que la conexión
 * falle en el handshake: el servidor no habla TLS. Se desactiva solo para hosts
 * locales, y DB_SSL=false lo fuerza para cualquier otro caso.
 */
function usarSsl(connectionString) {
  if (process.env.DB_SSL === 'false') return false;
  if (process.env.DB_SSL === 'true') return true;
  return !/(^|@|\/\/)(localhost|127\.0\.0\.1|\[::1\])(:|\/|$)/.test(connectionString);
}

<<<<<<< HEAD
/**
 * Cablea el contexto de inquilino (o el rol de sistema) al pool de Sequelize.
 *
 * POR QUÉ HACE FALTA
 * ------------------
 * El enrutado de consultas de `db.js` cubre el pool de `pg`, y no puede cubrir
 * a Sequelize: esta librería tiene su PROPIO pool, así que el cliente dedicado
 * de la petición (y el `set_config` que lleva dentro) no llega a las consultas
 * de los modelos. Bajo `FORCE ROW LEVEL SECURITY` esas consultas devolverían 0
 * filas: `Booking.findAll()` vacío, confirmaciones de pago que nunca encuentran
 * la reserva.
 *
 * CÓMO
 * ----
 * Se envuelve la adquisición y la liberación de conexiones del
 * ConnectionManager, el único punto por el que pasan todas las consultas (con o
 * sin transacción explícita):
 *
 *   al adquirir  -> set_config('app.tenant_id', <tenant>, false)  o
 *                   SET ROLE app_system                            (sistema)
 *   al liberar   -> RESET app.tenant_id / RESET ROLE
 *
 * Alcance de SESIÓN en la conexión, con limpieza garantizada en la liberación.
 * Es deliberado: `set_config(..., true)` es de alcance transaccional y la
 * adquisición ocurre ANTES del BEGIN de Sequelize, de modo que un `is_local`
 * aquí se evaporaría antes de la primera consulta (el modo "inerte" descrito en
 * tenantRouting.js). El par adquirir-limpiar acota el estado a exactamente el
 * intervalo en que la conexión está prestada a esa consulta, que es lo que se
 * quiere, y RESET lo deja fuera del pool.
 *
 * OJO: tras un RESET, `current_setting('app.tenant_id', true)` devuelve '' y no
 * NULL. Por eso la política de 068 usa NULLIF(..., '') antes del cast; sin eso,
 * `''::integer` reventaría.
 *
 * NO se instala si no hay servidor real (pg-mem): allí no hay políticas que
 * satisfacer y `SET ROLE`/`set_config` no son de fiar.
 */
function cablearContextoEnSequelize(instancia) {
  const cm = instancia.connectionManager;
  if (!cm || cm.__contextoDeInquilinoCableado) return;

  const getConnectionOriginal = cm.getConnection.bind(cm);
  const releaseConnectionOriginal = cm.releaseConnection.bind(cm);

  // Marca qué conexiones llevan contexto, para no limpiar las que no lo llevan.
  const conexionesConContexto = new WeakSet();

  /** Sequelize puede devolver un ResourceLock; la conexión está dentro. */
  const conexionReal = (conexion) => {
    if (!conexion) return conexion;
    // OJO: un `pg.Client` TIENE una propiedad `connection` (el socket interno),
    // así que `conexion.connection || conexion` devolvía el socket y las
    // sentencias se enviaban por su API, con otra firma: los parámetros ligados
    // se perdían ("there is no parameter $1") y el resultado llegaba sin esperar.
    // Un pg.Client se reconoce por `connectionParameters`; un ResourceLock no.
    if (conexion.connectionParameters !== undefined) return conexion;
    return conexion.connection || conexion;
  };

  cm.getConnection = async function (...args) {
    const conexion = await getConnectionOriginal(...args);
    const contexto = tenantRouting.getContext();
    if (!contexto || (!contexto.system && contexto.tenantId === undefined)) {
      return conexion;
    }

    const real = conexionReal(conexion);
    if (contexto.system) {
      // Escala a app_system (BYPASSRLS). Si falta la membresía, esto LANZA: es
      // preferible a ejecutar sin privilegios y devolver cero filas en silencio.
      await real.query('SET ROLE app_system');
    } else if (contexto.tenantId !== null && `${contexto.tenantId}` !== '') {
      await real.query("SELECT set_config('app.tenant_id', $1, false)", [
        `${contexto.tenantId}`,
      ]);
    }
    conexionesConContexto.add(real);
    return conexion;
  };

  cm.releaseConnection = async function (conexion, force) {
    const real = conexion ? conexionReal(conexion) : null;
    if (real && conexionesConContexto.has(real)) {
      // Si la limpieza falla no se puede devolver la conexión al pool: una
      // conexión con BYPASSRLS o con el tenant de otro en circulación es peor
      // que una conexión perdida.
      try {
        await real.query('RESET ROLE');
        await real.query('RESET app.tenant_id');
        conexionesConContexto.delete(real);
      } catch (error) {
        console.error(
          '❌ Sequelize: no se pudo limpiar el contexto de inquilino; se destruye la conexión:',
          error.message
        );
        return releaseConnectionOriginal(conexion, true);
      }
    }
    return releaseConnectionOriginal(conexion, force);
  };

  cm.__contextoDeInquilinoCableado = true;
}

let sequelize;
let usandoPostgresReal = false;

if (connectionString) {
  // DATABASE_URL GANA, también con NODE_ENV=test. Antes `NODE_ENV === 'test'`
  // tenía prioridad y la variable se ignoraba: el CI no podía probar el
  // aislamiento contra un servidor real por mucho contenedor que levantara,
  // porque todos los tests hablaban con pg-mem.
  const ssl = usarSsl(connectionString);
  sequelize = new Sequelize(connectionString, {
    dialect: 'postgres',
    ...(ssl
      ? { dialectOptions: { ssl: { require: true, rejectUnauthorized: false } } }
      : {}),
    logging: false,
  });
  usandoPostgresReal = true;
  cablearContextoEnSequelize(sequelize);
} else if (process.env.NODE_ENV === 'test') {
  // Sin DATABASE_URL no hay servidor: pg-mem como red de seguridad para los
  // tests que no necesitan una base de datos de verdad.
  const { newDb } = require('pg-mem');
  const pgMem = newDb();
  const pg = pgMem.adapters.createPg();
  sequelize = new Sequelize('postgres://', {
    dialect: 'postgres',
    dialectModule: pg,
    logging: false,
=======
// Harness en memoria (src/config/pgMemory.js). Se evalúa PRIMERO a propósito: antes las ramas
// NODE_ENV==='test' y DATABASE_URL tenían prioridad sobre USE_PG_MEM, de modo que el flag se ignoraba
// en silencio y un script que creía trabajar en memoria terminaba escribiendo en la base apuntada por
// DATABASE_URL. El mismo módulo expone el adaptador que comparte el pool crudo (src/config/db.js),
// para que Sequelize y el SQL crudo hablen con la MISMA base en memoria.
const pgMemory = require('./pgMemory');

if (pgMemory.enabled) {
  sequelize = new Sequelize('postgres://', {
    dialect: 'postgres',
    dialectModule: pgMemory.adapter,
    logging: false
  });
  // pg-mem no soporta CREATE TYPE ... AS ENUM: se neutraliza el helper que Sequelize usa en sync().
  sequelize.getQueryInterface().ensureEnums = async () => {};

} else if (connectionString) {
  sequelize = new Sequelize(connectionString, {
    dialect: 'postgres',
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    },
    logging: false
>>>>>>> origin/main
  });
} else {
  sequelize = new Sequelize(
    process.env.DB_NAME || 'beauty_db',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || 'postgres',
    {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      dialect: 'postgres',
      logging: false,
    }
  );
  cablearContextoEnSequelize(sequelize);
}

const testSequelizeConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Sequelize: Conexión exitosa a la base de datos.');
    return true;
  } catch (error) {
    console.error('❌ Sequelize: Error de conexión:', error.message);
    return false;
  }
};

module.exports = {
  sequelize,
  testSequelizeConnection,
  cablearContextoEnSequelize,
  usandoPostgresReal,
};
