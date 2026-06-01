const express = require('express');
const router = express.Router();

const adminController = require('./admin.controller');
const authAdmin = require('./authAdmin.middleware');

// Todas las rutas de administración requieren validación previa del token y rol ADMIN
router.use(authAdmin);

/**
 * @route GET /api/glow-admin/sos/active
 * @desc Obtiene todas las alertas SOS en estado 'ACTIVO'
 */
router.get('/sos/active', adminController.getAllActiveAlerts);

/**
 * @route PATCH /api/glow-admin/sos/resolve/:id
 * @desc Resuelve una alerta SOS marcándola como atendida
 */
router.patch('/sos/resolve/:id', adminController.resolveSOSAlert);

/**
 * @route POST /api/glow-admin/provider/verify
 * @desc Verifica el perfil de un prestador para habilitar su etiqueta verde
 */
router.post('/provider/verify', adminController.verifyProvider);

/**
 * @route POST /api/glow-admin/payout/approve
 * @desc Aprueba la dispersión y retiro de fondos de un prestador
 */
router.post('/payout/approve', adminController.approvePayout);

module.exports = router;
