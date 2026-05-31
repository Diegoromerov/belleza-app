const { pool } = require('./src/config/db');

async function test() {
  try {
    const users = await pool.query('SELECT id, email, rol FROM usuarios;');
    console.log('USUARIOS:', users.rows);

    const wallets = await pool.query('SELECT * FROM provider_wallet;');
    console.log('WALLETS:', wallets.rows);

    const txs = await pool.query('SELECT * FROM wallet_transactions;');
    console.log('TRANSACTIONS:', txs.rows);
  } catch (err) {
    console.error('DATABASE ERROR:', err);
  } finally {
    pool.end();
  }
}

test();
