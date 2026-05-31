const { pool } = require('./src/config/db');

async function testWallet() {
  const userId = 7; // outlookuser@outlook.com
  try {
    console.log('1. Simulating pending transactions update...');
    await pool.query(
      `UPDATE wallet_transactions
       SET estado = 'COMPLETADO'
       WHERE tipo = 'CREDITO_SERVICIO'
         AND estado = 'PENDIENTE'
         AND (metadata->>'madura_at')::timestamptz <= NOW()
         AND provider_id = $1`,
      [userId]
    );

    console.log('2. Simulating madurados check...');
    const madurados = await pool.query(
      `SELECT COALESCE(SUM(monto), 0) as total
       FROM wallet_transactions
       WHERE tipo = 'CREDITO_SERVICIO'
         AND estado = 'COMPLETADO'
         AND provider_id = $1
         AND (metadata->>'acreditado') IS NULL`,
      [userId]
    );
    console.log('Madurados total:', madurados.rows[0].total);

    console.log('3. Simulating wallet select...');
    const { rows } = await pool.query(
      `SELECT pw.*,
              (SELECT COUNT(*) FROM disputas d
               JOIN bookings b ON d.booking_id = b.id
               WHERE b.provider_id = $1 AND d.estado IN ('ABIERTA','EN_REVISION')) as disputas_activas
       FROM provider_wallet pw
       WHERE pw.provider_id = $1`,
      [userId]
    );
    console.log('Wallet rows length:', rows.length);

    if (!rows.length) {
      console.log('4. Simulating wallet insert...');
      await pool.query(
        'INSERT INTO provider_wallet (provider_id) VALUES ($1) ON CONFLICT DO NOTHING',
        [userId]
      );
      console.log('Wallet inserted successfully for retrocompatibility.');
    }
    console.log('SUCCESS!');
  } catch (err) {
    console.error('ERROR OCCURRED:', err);
  } finally {
    pool.end();
  }
}

testWallet();
