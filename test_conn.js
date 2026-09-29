const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgresql://postgres:gBXnSypHbhvlDQFSYJNeqcBslkSWIgYh@postgres-4a1e.railway.internal:5432/railway',
  ssl: { rejectUnauthorized: false }
});
pool.query('SELECT version()')
  .then(r => console.log('OK:', r.rows[0]))
  .catch(e => console.error('Error:', e.message))
  .finally(() => pool.end());