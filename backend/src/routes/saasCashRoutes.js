// backend/src/routes/saasCashRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const saasCashController = require('../controllers/saasCashController');

/**
 * CASH DRAWER / CAJA DOMAIN ROUTES
 * Base prefix: /api/saas/cash
 * Protected by authMiddleware + activeContextMiddleware.
 */

// GET /api/saas/cash/current — Consultar estado y métricas de sesión activa
router.get('/current', authMiddleware, activeContextMiddleware, saasCashController.getCurrentSession);

// POST /api/saas/cash/open — Abrir nueva sesión de caja
router.post('/open', authMiddleware, activeContextMiddleware, saasCashController.openSession);

// POST /api/saas/cash/movements — Registrar movimiento manual (CASH_IN / CASH_OUT)
router.post('/movements', authMiddleware, activeContextMiddleware, saasCashController.recordManualMovement);

// POST /api/saas/cash/close — Cerrar sesión y arquear caja
router.post('/close', authMiddleware, activeContextMiddleware, saasCashController.closeSession);

// GET /api/saas/cash/sessions/:id/movements — Listar movimientos de una sesión
router.get('/sessions/:id/movements', authMiddleware, activeContextMiddleware, saasCashController.listMovements);

// GET /api/saas/cash/sessions/:id — Detalle de una sesión específica
router.get('/sessions/:id', authMiddleware, activeContextMiddleware, saasCashController.getSessionById);

// GET /api/saas/cash/history — Historial de sesiones de caja de la sede
router.get('/history', authMiddleware, activeContextMiddleware, saasCashController.getSessionHistory);

module.exports = router;
