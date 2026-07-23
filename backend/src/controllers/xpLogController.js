// src/controllers/xpLogController.js
const { XpLog } = require('../models');
const Joi = require('joi');

// Validation schema for XP logs (allow unknown fields)
const xpLogSchema = Joi.object({ points: Joi.number().integer().required(), description: Joi.string().allow('').optional() }).unknown(true);

async function getLogs(req, res) {
  try {
    const logs = await XpLog.findAll({ where: { user_id: req.user.id } });
    return res.json(logs);
  } catch (err) {
    console.error('Error fetching XP logs:', err);
    return res.status(500).json({ error: 'Error fetching XP logs.' });
  }
}

// Create a new XP log entry
async function createLog(req, res) {
  try {
    // Validate request body
    const { error } = xpLogSchema.validate({ ...req.body, user_id: req.user.id });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    const log = await XpLog.create({ ...req.body, user_id: req.user.id });
    return res.status(201).json(log);
  } catch (err) {
    console.error('Error creating XP log:', err);
    return res.status(500).json({ error: 'Error creating XP log.' });
  }
}

// Convert XP points to Wallet Cashback balance (500 XP = $5.000 COP)
async function convertXpToCashback(req, res) {
  try {
    const userId = req.user.id;
    const { pool } = require('../config/db');

    // Consultar total de XP del usuario
    const xpRes = await pool.query(
      `SELECT COALESCE(SUM(points), 0) as total_xp FROM xp_logs WHERE user_id = $1`,
      [userId]
    );
    const totalXp = parseInt(xpRes.rows[0].total_xp || '0', 10);

    if (totalXp < 500) {
      return res.status(400).json({
        error: `Requieres al menos 500 XP para canjear Cashback. Tu saldo actual es de ${totalXp} XP.`
      });
    }

    const blocksToConvert = Math.floor(totalXp / 500);
    const xpToDeduct = blocksToConvert * 500;
    const cashbackAmount = blocksToConvert * 5000;

    // Descontar XP del historial
    await pool.query(
      `INSERT INTO xp_logs (user_id, points, description, created_at)
       VALUES ($1, $2, $3, NOW())`,
      [userId, -xpToDeduct, `Canje de ${xpToDeduct} XP por $${cashbackAmount} COP en Cashback`]
    );

    // Abonar saldo en wallet del prestador/cliente
    await pool.query(
      `UPDATE perfiles_prestador SET saldo_disponible = COALESCE(saldo_disponible, 0) + $1 WHERE id = $2`,
      [cashbackAmount, userId]
    );

    console.log(`🎉 [CASHBACK GAMIFICADO] Usuario ID ${userId} canjeó ${xpToDeduct} XP por $${cashbackAmount} COP en Billetera.`);

    return res.json({
      success: true,
      message: `¡Canje exitoso! Se han acreditado $${cashbackAmount} COP a tu Billetera GlowApp.`,
      xp_deducted: xpToDeduct,
      cashback_credited: cashbackAmount,
      remaining_xp: totalXp - xpToDeduct,
    });
  } catch (err) {
    console.error('Error converting XP to cashback:', err);
    return res.status(500).json({ error: 'Error al procesar el canje de XP por Cashback.' });
  }
}

module.exports = { getLogs, createLog, convertXpToCashback };

