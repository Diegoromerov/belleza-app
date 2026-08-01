const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

// 🔹 Obtenes lista completa de disputas para panel administrativo
router.get('/disputes', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT d.id, d.booking_id, d.tipo_actor, d.tipo, d.descripcion, d.evidencia_urls, d.monto_disputado, d.estado, d.nota_resolucion, d.creado_at, d.sla_limite_at,
             u_init.nombre AS iniciado_por_nombre, u_init.email AS iniciado_por_email,
             u_client.nombre AS cliente_nombre, u_client.email AS cliente_email,
             u_prov.nombre AS prestador_nombre, u_prov.email AS prestador_email
      FROM disputas d
      JOIN usuarios u_init ON d.iniciado_por = u_init.id
      JOIN bookings b ON d.booking_id = b.id
      JOIN usuarios u_client ON b.client_id = u_client.id
      JOIN usuarios u_prov ON b.provider_id = u_prov.id
      ORDER BY d.creado_at DESC;
    `);
    res.json({
      success: true,
      disputes: result.rows
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/admin/disputes:', error);
    res.status(500).json({ error: 'Error al obtener lista de disputas.' });
  }
});

// 🔹 Resolver disputa y dictaminar porcentaje de fondos
router.patch('/disputes/:id/resolve', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const disputeId = req.params.id;
    const adminId = req.user.id;
    const { resolucion, porcentaje_prestador, nota_resolucion } = req.body;

    if (!resolucion || porcentaje_prestador === undefined || !nota_resolucion) {
      return res.status(400).json({ error: 'Todos los campos de resolución son requeridos.' });
    }

    const pct = parseFloat(porcentaje_prestador);

    const checkDispute = await pool.query('SELECT * FROM disputas WHERE id = $1', [disputeId]);
    if (checkDispute.rows.length === 0) {
      return res.status(404).json({ error: 'Disputa no encontrada.' });
    }

    const dispute = checkDispute.rows[0];

    const result = await pool.query(`
      UPDATE disputas
      SET estado = 'RESUELTA',
          resuelto_por = $1,
          resolucion = $2,
          porcentaje_prestador = $3,
          nota_resolucion = $4,
          resuelto_at = NOW(),
          actualizado_at = NOW()
      WHERE id = $5
      RETURNING *;
    `, [adminId, resolucion, pct, nota_resolucion, disputeId]);

    const finalBookingStatus = pct > 0 ? 'COMPLETADA' : 'CANCELADA';
    await pool.query(`
      UPDATE bookings
      SET estado = $1
      WHERE id = $2;
    `, [finalBookingStatus, dispute.booking_id]);

    res.json({
      success: true,
      message: 'Disputa resuelta con éxito.',
      dispute: result.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/admin/disputes/:id/resolve:', error);
    res.status(500).json({ error: 'Error al resolver la disputa.' });
  }
});

module.exports = router;
