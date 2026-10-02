// backend/src/services/membershipTierService.js
const { pool } = require('../config/database');

class MembershipTierService {
  /**
   * Helper para calcular el Nivel de Membresía según los Puntos XP Históricos
   */
  static calculateTier(totalXp) {
    if (totalXp >= 3500) {
      return {
        levelName: 'SOCIO BLACK CONCIERGE',
        nextTier: null,
        scansLimit: 999, // Ilimitado (Soft-cap 30/mes)
        cashbackPercent: 15,
      };
    }
    if (totalXp >= 1500) {
      return {
        levelName: 'SOCIO GOLD LUXE',
        nextTier: { levelName: 'SOCIO BLACK CONCIERGE', requiredXp: 3500, remainingXp: 3500 - totalXp },
        scansLimit: 8,
        cashbackPercent: 10,
      };
    }
    if (totalXp >= 500) {
      return {
        levelName: 'SOCIO SILVER LUXE',
        nextTier: { levelName: 'SOCIO GOLD LUXE', requiredXp: 1500, remainingXp: 1500 - totalXp },
        scansLimit: 4,
        cashbackPercent: 5,
      };
    }
    return {
      levelName: 'SOCIO CLUB GLOW',
      nextTier: { levelName: 'SOCIO SILVER LUXE', requiredXp: 500, remainingXp: 500 - totalXp },
      scansLimit: 2,
      cashbackPercent: 0,
    };
  }

  /**
   * Obtiene la información completa del perfil de membresía de un usuario
   */
  static async getUserTierProfile(userId) {
    const userRes = await pool.query(
      `SELECT user_id, level_name, total_historical_xp FROM user_levels WHERE user_id = $1`,
      [userId]
    );

    let totalHistoricalXp = 0;
    let currentLevelName = 'SOCIO CLUB GLOW';

    if (userRes.rows.length > 0) {
      totalHistoricalXp = userRes.rows[0].total_historical_xp || 0;
      currentLevelName = userRes.rows[0].level_name || 'SOCIO CLUB GLOW';
    } else {
      // Crear registro inicial si no existe
      await pool.query(
        `INSERT INTO user_levels (user_id, level_name, total_historical_xp) VALUES ($1, 'SOCIO CLUB GLOW', 0) ON CONFLICT DO NOTHING`,
        [userId]
      );
    }

    // Obtener saldo de Aura Coins
    const coinsRes = await pool.query(
      `SELECT balance_after FROM aura_coin_transactions WHERE user_id = $1 ORDER BY id DESC LIMIT 1`,
      [userId]
    );
    const auraCoinsBalance = coinsRes.rows.length > 0 ? coinsRes.rows[0].balance_after : 0;

    const tierInfo = this.calculateTier(totalHistoricalXp);

    return {
      userId,
      levelName: tierInfo.levelName,
      totalHistoricalXp,
      auraCoinsBalance,
      nextTier: tierInfo.nextTier,
      scansLimit: tierInfo.scansLimit,
      cashbackPercent: tierInfo.cashbackPercent,
    };
  }

  /**
   * Registra y otorga Puntos XP (Idempotente)
   */
  static async awardXp({ userId, eventType, xpAmount, referenceId, metadata = {} }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Verificar idempotencia si viene referenceId
      if (referenceId) {
        const checkRef = await client.query(`SELECT id FROM xp_logs WHERE reference_id = $1`, [referenceId]);
        if (checkRef.rows.length > 0) {
          await client.query('ROLLBACK');
          return { success: true, duplicate: true, message: 'Evento de XP ya procesado previamente' };
        }
      }

      // 1. Insertar Log
      await client.query(
        `INSERT INTO xp_logs (user_id, xp_amount, event_type, reference_id, metadata)
         VALUES ($1, $2, $3, $4, $5)`,
        [userId, xpAmount, eventType, referenceId, JSON.stringify(metadata)]
      );

      // 2. Actualizar XP Histórico
      const updateRes = await client.query(
        `INSERT INTO user_levels (user_id, level_name, total_historical_xp)
         VALUES ($1, 'SOCIO CLUB GLOW', $2)
         ON CONFLICT (user_id) DO UPDATE
         SET total_historical_xp = user_levels.total_historical_xp + EXCLUDED.total_historical_xp,
             updated_at = CURRENT_TIMESTAMP
         RETURNING total_historical_xp`,
        [userId, xpAmount]
      );

      const newTotalXp = updateRes.rows[0].total_historical_xp;
      const calculatedTier = this.calculateTier(newTotalXp);

      // Actualizar nombre del nivel en la BD
      await client.query(
        `UPDATE user_levels SET level_name = $1 WHERE user_id = $2`,
        [calculatedTier.levelName, userId]
      );

      await client.query('COMMIT');

      return {
        success: true,
        xpAwarded: xpAmount,
        newTotalXp,
        levelName: calculatedTier.levelName,
      };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  /**
   * Canjear Aura Coins por Cupón de Descuento
   */
  static async redeemAuraCoins({ userId, coinsToRedeem }) {
    if (coinsToRedeem <= 0) throw new Error('El monto de Aura Coins a canjear debe ser mayor a 0');

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const coinsRes = await client.query(
        `SELECT balance_after FROM aura_coin_transactions WHERE user_id = $1 ORDER BY id DESC LIMIT 1 FOR UPDATE`,
        [userId]
      );
      const currentBalance = coinsRes.rows.length > 0 ? coinsRes.rows[0].balance_after : 0;

      if (currentBalance < coinsToRedeem) {
        await client.query('ROLLBACK');
        return { success: false, error: 'Saldo insuficiente de Aura Coins' };
      }

      const newBalance = currentBalance - coinsToRedeem;
      const discountCop = (coinsToRedeem / 100) * 5000; // 100 Coins = $5.000 COP
      const couponCode = `AURA-${Math.floor(1000 + Math.random() * 9000)}-${userId}`;

      // Insertar transacción
      await client.query(
        `INSERT INTO aura_coin_transactions (user_id, coins_amount, balance_after, transaction_type, reference_id)
         VALUES ($1, $2, $3, 'CANJE_CUPON', $4)`,
        [userId, -coinsToRedeem, newBalance, couponCode]
      );

      // Insertar cupón
      await client.query(
        `INSERT INTO reward_redemptions (user_id, coupon_code, discount_cop, coins_spent)
         VALUES ($1, $2, $3, $4)`,
        [userId, couponCode, discountCop, coinsToRedeem]
      );

      await client.query('COMMIT');

      return {
        success: true,
        couponCode,
        discountCop,
        coinsSpent: coinsToRedeem,
        remainingBalance: newBalance,
      };
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}

module.exports = MembershipTierService;
