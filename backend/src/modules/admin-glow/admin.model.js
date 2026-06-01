/**
 * Modelo de datos del Panel de Administración de GlowApp para MySQL.
 * Proporciona consultas parametrizadas seguras para evitar inyecciones SQL.
 */

// Se asume que el pool de MySQL está configurado en un archivo central del backend.
// Importamos un mock o una configuración genérica para integrarse limpiamente.
let pool;
try {
  // Intentamos requerir el pool de conexión existente si el proyecto está configurado para MySQL
  // o usamos un wrapper parametrizado para MySQL.
  const dbConfig = require('../../config/db');
  pool = dbConfig.pool;
} catch (e) {
  // En caso de que no exista, proveemos una interfaz de simulación segura para el SDK
  console.warn('⚠️ No se detectó configuración nativa de MySQL. Utilizando interfaz desacoplada para el SDK.');
}

/**
 * Helper para ejecutar consultas parametrizadas de forma segura.
 */
async function executeQuery(query, params = []) {
  if (pool && typeof pool.execute === 'function') {
    const [rows] = await pool.execute(query, params);
    return rows;
  }
  // Simulación para entornos SDK/Staging aislados
  console.log(`[MySQL mock] Ejecutando: ${query} con parámetros:`, params);
  return [];
}

/**
 * Obtener alertas SOS activas con información unida de cliente y prestador.
 */
async function getActiveSOSAlerts() {
  const query = `
    SELECT 
      s.id, s.latitude, s.longitude, s.estado, s.fecha_creacion,
      u_client.nombre AS client_name, u_client.phone AS client_phone,
      u_prov.nombre AS provider_name, u_prov.phone AS provider_phone
    FROM sos_alerts s
    LEFT JOIN usuarios u_client ON s.client_id = u_client.id
    LEFT JOIN usuarios u_prov ON s.provider_id = u_prov.id
    WHERE s.estado = 'ACTIVO'
    ORDER BY s.fecha_creacion DESC;
  `;
  return await executeQuery(query);
}

/**
 * Actualiza el estado de una alerta SOS.
 */
async function updateSOSAlertStatus(alertId, newStatus) {
  const query = `
    UPDATE sos_alerts 
    SET estado = ?, fecha_resolucion = NOW() 
    WHERE id = ?;
  `;
  return await executeQuery(query, [newStatus, alertId]);
}

/**
 * Registra una acción administrativa.
 */
async function logAdminAction(adminId, actionType, description) {
  const query = `
    INSERT INTO admin_actions (admin_id, accion, descripcion, fecha_creacion)
    VALUES (?, ?, ?, NOW());
  `;
  return await executeQuery(query, [adminId, actionType, description]);
}

/**
 * Actualiza el estado de verificación de un prestador.
 */
async function setProviderVerifiedStatus(providerId, isVerified) {
  const status = isVerified ? 'VERIFICADO' : 'PENDIENTE';
  const query = `
    UPDATE perfiles_prestador 
    SET estatus_verificacion = ? 
    WHERE id = ?;
  `;
  return await executeQuery(query, [status, providerId]);
}

/**
 * Obtiene el saldo disponible de un prestador en su billetera.
 */
async function getProviderWalletBalance(providerId) {
  const query = `
    SELECT saldo_disponible 
    FROM wallets 
    WHERE provider_id = ?;
  `;
  const rows = await executeQuery(query, [providerId]);
  return rows.length > 0 ? parseFloat(rows[0].saldo_disponible) : 0;
}

/**
 * Comprueba si existen disputas activas relacionadas con un prestador.
 */
async function hasActiveDisputes(providerId) {
  const query = `
    SELECT COUNT(*) AS count 
    FROM disputes d
    JOIN bookings b ON d.booking_id = b.id
    WHERE b.provider_id = ? AND d.estado = 'PENDIENTE';
  `;
  const rows = await executeQuery(query, [providerId]);
  return rows.length > 0 && parseInt(rows[0].count) > 0;
}

/**
 * Registra y aprueba la solicitud de retiro en el historial contable.
 */
async function processWalletWithdrawal(providerId, amount, newBalance) {
  // 1. Actualizar saldo disponible
  const updateWalletQuery = `
    UPDATE wallets 
    SET saldo_disponible = ? 
    WHERE provider_id = ?;
  `;
  await executeQuery(updateWalletQuery, [newBalance, providerId]);

  // 2. Registrar el retiro en el historial de transacciones de liquidación
  const recordTransactionQuery = `
    INSERT INTO wallet_transactions (provider_id, tipo, monto, estado, fecha_creacion, fecha_liberacion)
    VALUES (?, 'RETIRO', ?, 'PROCESANDO_LIBERACION', NOW(), DATE_ADD(NOW(), INTERVAL 48 HOUR));
  `;
  return await executeQuery(recordTransactionQuery, [providerId, amount]);
}

module.exports = {
  getActiveSOSAlerts,
  updateSOSAlertStatus,
  logAdminAction,
  setProviderVerifiedStatus,
  getProviderWalletBalance,
  hasActiveDisputes,
  processWalletWithdrawal
};
