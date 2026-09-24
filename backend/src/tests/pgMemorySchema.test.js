process.env.USE_PG_MEM = 'true';
const pgMemory = require('../config/pgMemory');
const { pool } = require('../config/db');

describe('pgMemory schema verification', () => {
  test('debe permitir INSERT y SELECT en la tabla transactions en modo memoria', async () => {
    expect(pgMemory.enabled).toBe(true);

    await pool.query(`
      INSERT INTO transactions (id, booking_id, client_id, provider_id, amount, status)
      VALUES ('tx-test-123', 'bk-test-456', 1, 2, 50000.00, 'APPROVED');
    `);

    const resSelect = await pool.query(`SELECT * FROM transactions WHERE id = $1`, ['tx-test-123']);
    expect(resSelect.rows).toHaveLength(1);
    expect(resSelect.rows[0].id).toBe('tx-test-123');
    expect(resSelect.rows[0].status).toBe('APPROVED');
    expect(parseFloat(resSelect.rows[0].amount)).toBe(50000);
  });
});
