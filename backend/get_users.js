const { Sequelize } = require('sequelize');
require('dotenv').config({ path: '../backend/.env' });
const connectionString = process.env.DATABASE_URL;
let sequelize;
if (connectionString) {
  sequelize = new Sequelize(connectionString, {
    dialect: 'postgres',
    dialectOptions: {
      ssl: { require: true, rejectUnauthorized: false }
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
async function getUsers() {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    const users = await sequelize.query(
      "SELECT id, nombre, email, tenant_id, worker_type, rol, is_active FROM usuarios",
      { type: Sequelize.QueryTypes.SELECT }
    );
    console.log(`Found ${users.length} users:`);
    users.forEach(u => {
      console.log(`  ID: ${u.id}, Nombre: ${u.nombre}, Email: ${u.email}, TenantID: ${u.tenant_id}, WorkerType: ${u.worker_type}, Rol: ${u.rol}, Active: ${u.is_active}`);
    });
    return users;
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await sequelize.close();
  }
}
getUsers();