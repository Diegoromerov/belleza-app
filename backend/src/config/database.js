const { Sequelize } = require('sequelize');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL;

let sequelize;

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
      logging: false
    }
  );
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
  testSequelizeConnection
};
