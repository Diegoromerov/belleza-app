const { wrapRouterAsync } = require('../utils/expressAsync');
const express = require('express');
const router = express.Router();
const providerController = require('../controllers/providerController');
const { authMiddleware } = require('../middleware/auth');
const { pool } = require('../config/db');

// ─── CONTRATO DE COMISIÓN E INDEPENDENCIA (D-GL-023 · F8) ────────────────────
// El prestador es independiente, no empleado. Se registra versión, fecha e IP:
// sin ese registro no hay forma de probar el vínculo comercial.

const CONTRATO_VERSION_ACTUAL = '2026-10';

router.get('/provider/contract', authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT contrato_version, contrato_aceptado_at, independencia_aceptada_at, regimen_iva
         FROM perfiles_prestador WHERE id = $1`,
      [req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Perfil de prestador no encontrado.' });

    res.json({
      version_actual: CONTRATO_VERSION_ACTUAL,
      ...rows[0],
      aceptado: Boolean(rows[0].contrato_aceptado_at && rows[0].independencia_aceptada_at)
    });
  } catch (err) {
    console.error('Error al consultar contrato:', err);
    res.status(500).json({ error: 'Error al consultar el contrato.' });
  }
});

router.post('/provider/contract/accept', authMiddleware, async (req, res) => {
  const { version, independencia, regimen_iva } = req.body;

  if (!independencia) {
    return res.status(400).json({
      error: 'Debes aceptar expresamente la cláusula de independencia: la plataforma no es tu empleador.'
    });
  }

  try {
    const { rows } = await pool.query(
      `UPDATE perfiles_prestador
          SET contrato_version = $2,
              contrato_aceptado_at = NOW(),
              contrato_aceptado_ip = $3,
              independencia_aceptada_at = NOW(),
              regimen_iva = COALESCE($4, regimen_iva)
        WHERE id = $1
        RETURNING contrato_version, contrato_aceptado_at, independencia_aceptada_at, regimen_iva`,
      [req.user.id, version || CONTRATO_VERSION_ACTUAL, req.ip, regimen_iva || null]
    );

    if (!rows.length) return res.status(404).json({ error: 'Perfil de prestador no encontrado.' });

    res.json({
      ok: true,
      mensaje: 'Contrato aceptado. Ya puedes recibir pagos y retirar.',
      contrato: rows[0]
    });
  } catch (err) {
    console.error('Error al aceptar contrato:', err);
    res.status(500).json({ error: 'Error al registrar la aceptación.' });
  }
});

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

wrapRouterAsync(router);
module.exports = router;
