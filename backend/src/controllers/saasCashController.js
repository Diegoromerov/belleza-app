// backend/src/controllers/saasCashController.js
const saasCashService = require('../services/saasCashService');

/**
 * GET /api/saas/cash/current
 * Retrieves the currently active cash drawer session and live metrics.
 */
const getCurrentSession = async (req, res) => {
  try {
    const result = await saasCashService.getCurrentSession(req.activeContext);
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in getCurrentSession:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * POST /api/saas/cash/open
 * Opens a new cash drawer session.
 */
const openSession = async (req, res) => {
  try {
    const { opening_balance, notes } = req.body || {};
    const result = await saasCashService.openSession(req.activeContext, {
      opening_balance,
      notes
    });
    return res.status(201).json(result);
  } catch (error) {
    console.error('❌ Error in openSession:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * POST /api/saas/cash/movements
 * Records a manual cash movement (CASH_IN or CASH_OUT).
 */
const recordManualMovement = async (req, res) => {
  try {
    const { movement_type, category, amount, reason } = req.body || {};
    const result = await saasCashService.recordManualMovement(req.activeContext, {
      movement_type,
      category,
      amount,
      reason
    });
    return res.status(201).json(result);
  } catch (error) {
    console.error('❌ Error in recordManualMovement:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * POST /api/saas/cash/close
 * Closes the active cash session and performs final count/reconciliation.
 */
const closeSession = async (req, res) => {
  try {
    const { counted_cash, closing_notes } = req.body || {};
    const result = await saasCashService.closeSession(req.activeContext, {
      counted_cash,
      closing_notes
    });
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in closeSession:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * GET /api/saas/cash/sessions/:id/movements
 * Lists movements for a specific session.
 */
const listMovements = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await saasCashService.listMovements(req.activeContext, id);
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in listMovements:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * GET /api/saas/cash/history
 * Lists historical closed sessions for the active establishment.
 */
const getSessionHistory = async (req, res) => {
  try {
    const { page, limit, date_from, date_to } = req.query || {};
    const result = await saasCashService.getSessionHistory(req.activeContext, {
      page,
      limit,
      date_from,
      date_to
    });
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in getSessionHistory:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

/**
 * GET /api/saas/cash/sessions/:id
 * Retrieves single session details.
 */
const getSessionById = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await saasCashService.getSessionById(req.activeContext, id);
    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ Error in getSessionById:', error.message);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message,
      code: error.code || 'INTERNAL_ERROR'
    });
  }
};

module.exports = {
  getCurrentSession,
  openSession,
  recordManualMovement,
  closeSession,
  listMovements,
  getSessionHistory,
  getSessionById
};
