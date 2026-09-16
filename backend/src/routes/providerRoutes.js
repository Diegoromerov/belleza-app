const express = require('express');
const router = express.Router();
const providerController = require('../controllers/providerController');
const { authMiddleware } = require('../middleware/auth');
const { pool } = require('../config/db');

router.get('/providers', providerController.getProviders);
router.get('/providers/:id', providerController.getProviderById);
router.get('/providers/:id/slots', providerController.getProviderSlots);

// ─── HORARIOS DEL PRESTADOR ──────────────────────────────────────────────────

// GET /api/provider/schedule
router.get('/provider/schedule', authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT active_start_hour, active_end_hour, weekly_schedule
       FROM perfiles_prestador
       WHERE id = $1`,
      [req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Perfil de prestador no encontrado.' });
    }

    res.json({
      active_start_hour: rows[0].active_start_hour ?? 8,
      active_end_hour: rows[0].active_end_hour ?? 19,
      weekly_schedule: rows[0].weekly_schedule ?? {}
    });
  } catch (err) {
    console.error('Error al consultar horario de prestador:', err);
    res.status(500).json({ error: 'Error al consultar horario de atención.' });
  }
});

// PUT /api/provider/schedule
router.put('/provider/schedule', authMiddleware, async (req, res) => {
  const { weekly_schedule, active_start_hour, active_end_hour } = req.body;

  try {
    const startHour = active_start_hour !== undefined ? parseInt(active_start_hour) : 8;
    const endHour = active_end_hour !== undefined ? parseInt(active_end_hour) : 19;

    const { rows } = await pool.query(
      `UPDATE perfiles_prestador
       SET weekly_schedule = COALESCE($2, weekly_schedule),
           active_start_hour = $3,
           active_end_hour = $4,
           updated_at = NOW()
       WHERE id = $1
       RETURNING active_start_hour, active_end_hour, weekly_schedule`,
      [req.user.id, weekly_schedule ? JSON.stringify(weekly_schedule) : null, startHour, endHour]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Perfil de prestador no encontrado.' });
    }

    res.json({
      ok: true,
      mensaje: 'Horario de atención actualizado correctamente.',
      horario: rows[0]
    });
  } catch (err) {
    console.error('Error al actualizar horario de prestador:', err);
    res.status(500).json({ error: 'Error al actualizar horario de atención.' });
  }
});

module.exports = router;
