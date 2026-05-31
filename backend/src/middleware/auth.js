const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const JWT_SECRET = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';

module.exports = async (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '') || req.query.token;
  if (!token) return res.status(401).json({ error: 'Acceso denegado. Token requerido.' });
  try {
    const verified = jwt.verify(token, JWT_SECRET);
    
    // Consultar el rol actual del usuario en la base de datos para evitar JWT desactualizados
    const userRes = await pool.query('SELECT rol FROM usuarios WHERE id = $1', [verified.id]);
    if (userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado en el sistema.' });
    }
    
    const dbRole = userRes.rows[0].rol;
    req.user = {
      id: verified.id,
      email: verified.email,
      role: dbRole === 'PRESTADOR' ? 'provider' : (dbRole === 'CLIENTE' ? 'client' : null)
    };
    
    next();
  } catch (err) {
    res.status(400).json({ error: 'Token inválido o expirado.' });
  }
};

